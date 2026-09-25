#!/usr/bin/env python3
"""Architecture import gate for docs/ARCHITECTURE-RULES.md.

Reads quality/architecture-rules.json, parses every import/export directive in
the configured source trees (Dart, TypeScript/JavaScript, Go) and reports the
imports that break a layer-direction, module-isolation or external-package
rule. Known violations live in quality/architecture-baseline.json; the
baseline only shrinks.

Exit codes: 0 clean (or --warn-only), 1 a new violation or a stale baseline
entry (a fixed violation still listed, which would let it come back
silently), 2 configuration error.
"""
import argparse
import json
import os
import posixpath
import re
import subprocess
import sys
from collections import Counter

DEFAULT_CONFIG = "quality/architecture-rules.json"
LANG_EXTENSIONS = {
    "dart": (".dart",),
    "ts": (".ts", ".tsx", ".js", ".jsx", ".mjs", ".cjs"),
    "go": (".go",),
}
TS_RESOLVE_SUFFIXES = (
    "", ".ts", ".tsx", ".js", ".jsx", ".mjs", ".cjs",
    "/index.ts", "/index.tsx", "/index.js", "/index.jsx",
)
QUOTED = re.compile(r"""['"]([^'"\n]+)['"]""")
TS_STATEMENT = re.compile(
    r"""^[ \t]*(?:import|export)(?:[ \t]+type)?\s+(?:[^'";]*?\s+from\s+)?(['"])([^'"\n]+)\1""",
    re.M,
)
TS_CALL = re.compile(r"""\b(?:import|require)\s*\(\s*(['"])([^'"\n]+)\1\s*\)""")
GO_SINGLE = re.compile(r"""^\s*import\s+(?:[\w.]+\s+)?"([^"]+)\"""", re.M)
GO_BLOCK = re.compile(r"^\s*import\s*\((.*?)\)", re.M | re.S)
GO_BLOCK_LINE = re.compile(r"""^\s*(?:[\w.]+\s+)?"([^"]+)\"""")
USE_CLIENT = re.compile(r"""\A(?:\s|//[^\n]*\n|/\*.*?\*/)*['"]use client['"]""", re.S)


class ConfigError(Exception):
    pass


def glob_to_regex(pattern):
    """`**` spans directories, `*` stays in one segment, `{name}` captures one
    segment, and `dir/**` also matches `dir` itself (a Go package path)."""
    out, i = ["^"], 0
    while i < len(pattern):
        if pattern.startswith("**/", i):
            out.append("(?:.*/)?")
            i += 3
        elif pattern.startswith("/**", i) and i + 3 == len(pattern):
            out.append("(?:/.*)?")
            i += 3
        elif pattern.startswith("**", i):
            out.append(".*")
            i += 2
        elif pattern[i] == "*":
            out.append("[^/]*")
            i += 1
        elif pattern[i] == "?":
            out.append("[^/]")
            i += 1
        elif pattern[i] == "{":
            end = pattern.index("}", i)
            out.append("(?P<%s>[^/]+)" % pattern[i + 1:end])
            i = end + 1
        else:
            out.append(re.escape(pattern[i]))
            i += 1
    out.append("$")
    return re.compile("".join(out))


class Matcher:
    def __init__(self, patterns, layers):
        expanded = []
        for item in patterns or []:
            if item.startswith("@"):
                name = item[1:]
                if name not in layers:
                    raise ConfigError("unknown layer reference: " + item)
                expanded.extend(layers[name])
            else:
                expanded.append(item)
        self.regexes = [glob_to_regex(p) for p in expanded]

    def match(self, path):
        for regex in self.regexes:
            found = regex.match(path)
            if found:
                return found
        return None


def list_files(root):
    try:
        out = subprocess.run(
            ["git", "-C", root, "ls-files", "-z", "--cached", "--others", "--exclude-standard"],
            capture_output=True, check=True,
        ).stdout.decode("utf-8", "replace")
        files = [f for f in out.split("\0") if f]
        return sorted({f for f in files if os.path.isfile(os.path.join(root, f))})
    except (subprocess.CalledProcessError, FileNotFoundError):
        found = []
        for base, dirs, names in os.walk(root):
            dirs[:] = [d for d in dirs if d not in (".git", "node_modules", "build", ".dart_tool", ".next")]
            for name in names:
                found.append(os.path.relpath(os.path.join(base, name), root).replace(os.sep, "/"))
        return sorted(found)


def dart_imports(text):
    lines = text.split("\n")
    i = 0
    while i < len(lines):
        stripped = lines[i].lstrip()
        if stripped.startswith(("import ", "export ", "import'", "export'", 'import"', 'export"')):
            start, chunk = i, lines[i]
            while ";" not in chunk and i + 1 < len(lines) and i - start < 8:
                i += 1
                chunk += "\n" + lines[i]
            for spec in QUOTED.findall(chunk.split(";")[0]):
                yield start + 1, spec
        i += 1


def ts_imports(text):
    seen = set()
    for regex in (TS_STATEMENT, TS_CALL):
        for found in regex.finditer(text):
            line = text.count("\n", 0, found.start(2)) + 1
            if (line, found.group(2)) not in seen:
                seen.add((line, found.group(2)))
                yield line, found.group(2)


def go_imports(text):
    for found in GO_SINGLE.finditer(text):
        yield text.count("\n", 0, found.start(1)) + 1, found.group(1)
    for block in GO_BLOCK.finditer(text):
        base_line = text.count("\n", 0, block.start(1)) + 1
        for offset, raw in enumerate(block.group(1).split("\n")):
            found = GO_BLOCK_LINE.match(raw)
            if found:
                yield base_line + offset, found.group(1)


class Source:
    def __init__(self, spec, root):
        self.dir = spec["dir"].rstrip("/")
        self.lang = spec["lang"]
        if self.lang not in LANG_EXTENSIONS:
            raise ConfigError("unsupported lang: " + self.lang)
        self.package = spec.get("dart_package")
        self.aliases = spec.get("aliases", {})
        self.module = spec.get("go_module")
        self.include_tests = spec.get("include_tests", False)
        if self.lang == "go":
            gomod = os.path.join(root, self.dir, "go.mod")
            if os.path.isfile(gomod):
                with open(gomod, encoding="utf-8") as handle:
                    declared = re.search(r"^module\s+(\S+)", handle.read(), re.M)
                if declared and self.module and declared.group(1) != self.module:
                    raise ConfigError("go_module %s differs from %s" % (self.module, gomod))
                if declared and not self.module:
                    self.module = declared.group(1)
            if not self.module:
                raise ConfigError("go source %s needs go_module" % self.dir)
        if self.lang == "dart" and not self.package:
            raise ConfigError("dart source %s needs dart_package" % self.dir)

    def owns(self, path):
        if not path.startswith(self.dir + "/") or not path.endswith(LANG_EXTENSIONS[self.lang]):
            return False
        if self.lang == "go" and path.endswith("_test.go") and not self.include_tests:
            return False
        return True

    def imports(self, text):
        return {"dart": dart_imports, "ts": ts_imports, "go": go_imports}[self.lang](text)

    def resolve(self, spec, from_path, fileset):
        """Returns ("local", repo-relative path) or ("ext", specifier)."""
        if self.lang == "dart":
            if spec.startswith("package:"):
                package, _, rest = spec[len("package:"):].partition("/")
                if package == self.package:
                    return "local", posixpath.join(self.dir, rest)
                return "ext", spec
            if spec.startswith("dart:"):
                return "ext", spec
            return "local", posixpath.normpath(posixpath.join(posixpath.dirname(from_path), spec))
        if self.lang == "go":
            if spec == self.module or spec.startswith(self.module + "/"):
                return "local", posixpath.join(self.dir, spec[len(self.module):].lstrip("/")).rstrip("/")
            return "ext", spec
        if spec.startswith("."):
            base = posixpath.normpath(posixpath.join(posixpath.dirname(from_path), spec))
        else:
            for prefix, target in self.aliases.items():
                if spec.startswith(prefix):
                    base = posixpath.normpath(target + spec[len(prefix):])
                    break
            else:
                return "ext", spec
        for suffix in TS_RESOLVE_SUFFIXES:
            if base + suffix in fileset:
                return "local", base + suffix
        return "local", base


class Rule:
    KINDS = ("forbid", "isolate", "external-deny", "external-allow-only")

    def __init__(self, spec, layers):
        self.id = spec["id"]
        self.kind = spec["kind"]
        if self.kind not in self.KINDS:
            raise ConfigError("rule %s: unknown kind %s" % (self.id, self.kind))
        self.why = spec.get("why", "")
        self.from_ = Matcher(spec.get("from"), layers)
        self.from_except = Matcher(spec.get("from_except"), layers)
        self.to = Matcher(spec.get("to"), layers)
        self.to_except = Matcher(spec.get("to_except"), layers)
        self.prefixes = tuple(spec.get("packages", []))
        self.pattern = glob_to_regex(spec["pattern"]) if spec.get("pattern") else None
        self.client_only = spec.get("client_only", False)

    def applies_to(self, path, is_client=False):
        if self.client_only and not is_client:
            return False
        if self.kind == "isolate":
            return bool(self.pattern.match(path)) and not self.from_except.match(path)
        return bool(self.from_.match(path)) and not self.from_except.match(path)

    def breaks(self, from_path, kind, target):
        if self.kind == "forbid":
            return kind == "local" and bool(self.to.match(target)) and not self.to_except.match(target)
        if self.kind == "isolate":
            if kind != "local" or self.to_except.match(target):
                return False
            source, dest = self.pattern.match(from_path), self.pattern.match(target)
            return bool(dest) and source.groupdict() != dest.groupdict()
        if kind != "ext":
            return False
        hit = target.startswith(self.prefixes) or (
            "$gostd" in self.prefixes and "." not in target.split("/")[0]
        )
        return hit if self.kind == "external-deny" else not hit


def load_config(root, path):
    try:
        with open(os.path.join(root, path), encoding="utf-8") as handle:
            config = json.load(handle)
    except (OSError, ValueError) as error:
        raise ConfigError("cannot read %s: %s" % (path, error))
    layers = config.get("layers", {})
    sources = [Source(spec, root) for spec in config["sources"]]
    rules = [Rule(spec, layers) for spec in config["rules"]]
    exclude = Matcher(config.get("exclude"), layers)
    ids = [rule.id for rule in rules]
    if len(ids) != len(set(ids)):
        raise ConfigError("duplicate rule id")
    return config, layers, sources, rules, exclude


def scan(root, sources, rules, exclude, files=None):
    files = files if files is not None else list_files(root)
    fileset = set(files)
    violations, edges = [], []
    for path in files:
        source = next((s for s in sources if s.owns(path)), None)
        if source is None or exclude.match(path):
            continue
        try:
            with open(os.path.join(root, path), encoding="utf-8", errors="replace") as handle:
                text = handle.read()
        except OSError:
            continue
        is_client = source.lang == "ts" and bool(USE_CLIENT.match(text))
        active = [rule for rule in rules if rule.applies_to(path, is_client)]
        for line, spec in source.imports(text):
            kind, target = source.resolve(spec, path, fileset)
            edges.append((path, kind, target))
            for rule in active:
                if rule.breaks(path, kind, target):
                    violations.append((rule, path, line, target))
    return violations, edges


def violation_key(rule, path, target):
    return "%s|%s|%s" % (rule.id, path, target)


def read_baseline(root, path):
    full = os.path.join(root, path)
    if not os.path.isfile(full):
        return None
    with open(full, encoding="utf-8") as handle:
        return set(json.load(handle).get("violations", []))


def write_baseline(root, path, keys):
    payload = {
        "note": "Known architecture violations at introduction. This list only shrinks: "
                "fix an entry, then remove it here in the same commit. Never add entries.",
        "violations": sorted(keys),
    }
    with open(os.path.join(root, path), "w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2, ensure_ascii=False)
        handle.write("\n")


def layer_of(path, layer_matchers):
    for name, matcher in layer_matchers:
        if matcher.match(path):
            return name
    return None


def print_stats(edges, layers):
    matchers = [(name, Matcher(globs, layers)) for name, globs in layers.items()]
    pairs = Counter()
    for from_path, kind, target in edges:
        if kind != "local":
            continue
        pairs[(layer_of(from_path, matchers) or "-", layer_of(target, matchers) or "-")] += 1
    for (src, dst), count in sorted(pairs.items(), key=lambda item: -item[1]):
        print("%6d  %s -> %s" % (count, src, dst))


def parse_args(argv):
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--root", default=os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                        help="repository root (default: the parent of quality/)")
    parser.add_argument("--config", default=DEFAULT_CONFIG)
    parser.add_argument("--warn-only", action="store_true", help="report, never fail")
    parser.add_argument("--list", action="store_true", help="also print baseline violations")
    parser.add_argument("--stats", action="store_true", help="print import counts between layers")
    parser.add_argument("--init-baseline", action="store_true", help="create the baseline once")
    parser.add_argument("--shrink-baseline", action="store_true", help="drop fixed entries")
    return parser.parse_args(argv)


def settle_baseline(args, root, path, current):
    """Returns (baseline keys, stale keys) after the optional init/shrink step."""
    baseline = read_baseline(root, path)
    if args.init_baseline:
        if baseline is not None:
            raise ConfigError("%s exists; the baseline only shrinks" % path)
        write_baseline(root, path, current)
        print("ARCH baseline created with %d entries" % len(current))
        return set(current), []
    baseline = baseline or set()
    stale = sorted(baseline - current)
    if args.shrink_baseline and stale:
        write_baseline(root, path, baseline & current)
        print("ARCH baseline shrunk by %d entries" % len(stale))
        return baseline & current, []
    return baseline, stale


def report(violations, baseline, stale, show_known):
    new = [v for v in violations if violation_key(v[0], v[1], v[3]) not in baseline]
    known = [v for v in violations if violation_key(v[0], v[1], v[3]) in baseline]
    for label, group in (("NEW", new), ("BASELINE", known if show_known else [])):
        for rule, path, line, target in sorted(group, key=lambda v: (v[1], v[2], v[0].id)):
            print("%s %s:%d %s -> %s  (%s)" % (label, path, line, rule.id, target, rule.why))
    for key in stale:
        print("STALE baseline entry, the violation is fixed: remove it with --shrink-baseline: %s" % key)
    return new, known


def main(argv=None):
    args = parse_args(argv)
    root = os.path.abspath(args.root)
    try:
        config, layers, sources, rules, exclude = load_config(root, args.config)
        violations, edges = scan(root, sources, rules, exclude)
        current = {violation_key(r, p, t) for r, p, _, t in violations}
        baseline_path = config.get("baseline", "quality/architecture-baseline.json")
        baseline, stale = settle_baseline(args, root, baseline_path, current)
    except (ConfigError, KeyError) as error:
        print("ARCH config error: %s" % error, file=sys.stderr)
        return 2
    if args.stats:
        print_stats(edges, layers)
    new, known = report(violations, baseline, stale, args.list)
    print("ARCH summary: %d violations, %d new, %d in baseline, %d stale baseline entries, %d imports checked"
          % (len(violations), len(new), len(known), len(stale), len(edges)))
    return 1 if (new or stale) and not args.warn_only else 0


if __name__ == "__main__":
    sys.exit(main())
