"""Tests architecture rule calibration."""
import argparse
import contextlib
import io
import json
import os
import sys
import tempfile
import unittest

QUALITY_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REPO_ROOT = os.path.dirname(QUALITY_DIR)
sys.path.insert(0, QUALITY_DIR)

import check_architecture as arch  # noqa: E402


def write(root, relative, text):
    path = os.path.join(root, relative)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as handle:
        handle.write(text)


class ArchitectureCalibrationTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with open(os.path.join(REPO_ROOT, arch.DEFAULT_CONFIG), encoding="utf-8") as handle:
            cls.config = json.load(handle)
        cls.cases = cls.config.get("calibration", [])

    def test_config_has_positive_and_negative_cases(self):
        self.assertTrue(any(case["expect"] for case in self.cases), "no positive case")
        self.assertTrue(any(not case["expect"] for case in self.cases), "no negative case")

    def test_every_rule_has_positive_and_negative_coverage(self):
        declared = {rule["id"] for rule in self.config["rules"]}
        positive = {
            rule for case in self.cases if case["expect"]
            for rule in case.get("covers", [])
        }
        negative = {
            rule for case in self.cases if not case["expect"]
            for rule in case.get("covers", [])
        }
        self.assertEqual(declared, positive, "rules without positive coverage")
        self.assertEqual(declared, negative, "rules without negative coverage")
        self.assertTrue(all(set(case.get("covers", [])) <= declared for case in self.cases))

    def test_layers_cover_the_declared_architecture(self):
        _, layers, _, _, _ = arch.load_config(REPO_ROOT, arch.DEFAULT_CONFIG)
        samples = {
            "presentation": [
                "lib/app/modules/home/home_view.dart",
                "lib/app/widgets/language_switcher.dart",
            ],
            "application": [
                "lib/app/features/language/application/language_cubit.dart",
                "lib/app/controllers/scene_director.dart",
                "lib/app/narrative/application/narrative_position.dart",
            ],
            "domain": [
                "lib/app/domain/providers/asset_loader.dart",
                "lib/app/features/render_quality/domain/render_quality.dart",
                "lib/app/narrative/domain/narrative_document.dart",
            ],
            "core": ["lib/app/core/constants/app_colors.dart"],
            "data": ["lib/app/data/providers/bundle_asset_loader.dart"],
        }

        for layer, paths in samples.items():
            matcher = arch.Matcher(layers[layer], layers)
            for path in paths:
                with self.subTest(layer=layer, path=path):
                    self.assertIsNotNone(matcher.match(path))

    def test_cases_trigger_exactly_the_expected_rules(self):
        for case in self.cases:
            with self.subTest(file=case["file"]):
                self.assertEqual(sorted(case["expect"]), self.scan_case(case))

    def scan_case(self, case):
        with tempfile.TemporaryDirectory(prefix="arch-calibration-") as scratch:
            config = dict(self.config, baseline="quality/no-baseline.json")
            write(scratch, arch.DEFAULT_CONFIG, json.dumps(config))
            for source in config["sources"]:
                if source["lang"] == "go":
                    write(scratch, source["dir"] + "/go.mod", "module %s\n" % source["go_module"])
            write(scratch, case["file"], case["source"])
            _, _, sources, rules, exclude = arch.load_config(scratch, arch.DEFAULT_CONFIG)
            violations, _ = arch.scan(scratch, sources, rules, exclude)
            return sorted(rule.id for rule, path, _, _ in violations if path == case["file"])

    def test_multiline_domain_directives_preserve_boundary(self):
        path = "lib/app/domain/models/calibration_probe.dart"
        for uri, expected in (
            ("dart:core", []),
            ("package:flutter/material.dart", ["F-DOMAIN-PURE"]),
        ):
            with self.subTest(uri=uri):
                self.assertEqual(expected, self.scan_case({
                    "file": path,
                    "source": "import\n  '%s';\n" % uri,
                }))

    def test_directives_ignore_comments_and_preserve_conditional_uris(self):
        source = (
            "// import 'package:flutter/material.dart';\n"
            "import\n  'dart:core'\n"
            "    if (dart.library.html) 'dart:html';\n"
        )
        self.assertEqual([(3, "dart:core"), (4, "dart:html")],
                         list(arch.dart_imports(source)))

    def test_comments_between_keyword_and_uri_do_not_hide_domain_imports(self):
        path = "lib/app/domain/models/calibration_probe.dart"
        for directive in (
            "import /* separator */ 'package:flutter/material.dart';\n",
            "import // separator\n  'package:flutter/material.dart';\n",
        ):
            with self.subTest(directive=directive):
                self.assertEqual(["F-DOMAIN-PURE"], self.scan_case({
                    "file": path,
                    "source": directive,
                }))

    def test_inline_comment_cannot_create_conditional_import(self):
        source = (
            "import 'dart:core' // if (dart.library.html) 'package:flutter/material.dart'\n"
            "  if (dart.library.io) 'dart:io';\n"
        )
        self.assertEqual([(1, "dart:core"), (2, "dart:io")],
                         list(arch.dart_imports(source)))

    def test_conditional_uri_reports_its_own_line(self):
        source = (
            "import 'dart:core'\n"
            "  if (dart.library.html)\n"
            "    'package:flutter/material.dart';\n"
        )
        self.assertEqual([(1, "dart:core"), (3, "package:flutter/material.dart")],
                         list(arch.dart_imports(source)))

    def test_quoted_comment_marker_remains_part_of_uri(self):
        self.assertEqual([(1, ".//dependency.dart")],
                         list(arch.dart_imports("import './/dependency.dart';\n")))

    def test_nested_block_comment_hides_import_until_outer_close(self):
        source = (
            "/* outer\n"
            "  /* inner */\n"
            "  import 'package:flutter/material.dart';\n"
            "*/\n"
            "import 'package:flutter/material.dart';\n"
        )
        self.assertEqual([(5, "package:flutter/material.dart")],
                         list(arch.dart_imports(source)))
        self.assertEqual(["F-DOMAIN-PURE"], self.scan_case({
            "file": "lib/app/domain/models/calibration_probe.dart",
            "source": source,
        }))

    def test_triple_quoted_import_export_and_conditional_uris(self):
        source = (
            "import '''package:flutter/material.dart'''\n"
            "  if (dart.library.html) \"\"\"dart:html\"\"\";\n"
            "export \"\"\"dart:core\"\"\";\n"
        )
        self.assertEqual([(1, "package:flutter/material.dart"), (2, "dart:html"),
                          (3, "dart:core")], list(arch.dart_imports(source)))
        self.assertEqual(["F-DOMAIN-PURE", "F-DOMAIN-PURE"], self.scan_case({
            "file": "lib/app/domain/models/calibration_probe.dart",
            "source": source,
        }))

    def test_multiline_string_cannot_fake_directive_or_comment(self):
        source = (
            "import 'dart:core';\n"
            "const fake = '''\n"
            "import 'package:flutter/material.dart';\n"
            "''';\n"
            "const marker = \"\"\"/* not a comment */\"\"\";\n"
        )
        self.assertEqual([(1, "dart:core")], list(arch.dart_imports(source)))

    def test_raw_uri_prefix_stays_visible(self):
        source = "import r'''package:flutter/material.dart''';\n"
        self.assertEqual([(1, "package:flutter/material.dart")],
                         list(arch.dart_imports(source)))
        self.assertEqual(["F-DOMAIN-PURE"], self.scan_case({
            "file": "lib/app/domain/models/calibration_probe.dart",
            "source": source,
        }))

    def test_shared_dart_directive_fixtures(self):
        fixture = os.path.join(QUALITY_DIR, "fixtures", "dart_directives.json")
        with open(fixture, encoding="utf-8") as handle:
            cases = json.load(handle)["cases"]
        self.assertGreaterEqual(len(cases), 10)
        for case in cases:
            with self.subTest(name=case["name"]):
                if "error" in case:
                    with self.assertRaises(arch.ConfigError) as failure:
                        self.scan_case({
                            "file": "lib/app/domain/models/calibration_probe.dart",
                            "source": case["source"],
                        })
                    self.assertIn("calibration_probe.dart:%d" % case["error"], str(failure.exception))
                    continue
                actual = list(arch.parse_dart_directives(case["source"]))
                self.assertEqual(case["directives"], actual)
                self.assertEqual([(item["line"], item["uri"]) for item in actual],
                                 list(arch.dart_imports(case["source"])))
                if any(item["uri"].startswith("package:flutter/") for item in actual):
                    rules = self.scan_case({
                        "file": "lib/app/domain/models/calibration_probe.dart",
                        "source": case["source"],
                    })
                    self.assertIn("F-DOMAIN-PURE", rules)

    def test_part_uris_are_validated_without_import_edges(self):
        for directive in (
            "part 'of';", "part of 'of';",
            "part of r'''parent.dart''';", 'part """child.dart""";',
        ):
            with self.subTest(directive=directive):
                self.assertEqual([], arch.parse_dart_directives(directive))
                source = directive + "\nimport 'dart:core';\n"
                self.assertEqual([(2, "dart:core")], list(arch.dart_imports(source)))

    def test_named_part_of_has_no_import_edge(self):
        for name in ("library", "library.name", "_library.$segment_2"):
            with self.subTest(name=name):
                self.assertEqual([], arch.parse_dart_directives("part of %s;" % name))
                source = "part of %s;\nimport 'dart:core';\n" % name
                self.assertEqual([(2, "dart:core")], list(arch.dart_imports(source)))

    def test_same_line_import_after_metadata_enforces_domain_boundary(self):
        source = (
            "@Deprecated('old') import 'dart:core'; "
            "import 'package:flutter/material.dart';\n"
        )
        self.assertEqual([(1, 'dart:core'), (1, 'package:flutter/material.dart')],
                         list(arch.dart_imports(source)))
        self.assertEqual(["F-DOMAIN-PURE"], self.scan_case({
            "file": "lib/app/domain/models/calibration_probe.dart",
            "source": source,
        }))

    def test_parser_error_cannot_be_warned_away(self):
        for text, line in (
            ("import unknownUri;\n", 1),
            ("part of library.name\r\nimport 'missing.dart';\n", 2),
            ("part of library.name + other;\n", 1),
            ("part of library name;\n", 1),
            ("library library.class;\n", 1),
            ("part of library.class;\n", 1),
            ("final value = of\nimport 'missing.dart';\n", 2),
            ("void part() {}\npart of class;\n", 2),
        ):
            with (
                self.subTest(text=text),
                tempfile.TemporaryDirectory(prefix="arch-config-fail-") as scratch,
            ):
                write(scratch, arch.DEFAULT_CONFIG, json.dumps(self.config))
                for source in self.config["sources"]:
                    if source["lang"] == "go":
                        write(scratch, source["dir"] + "/go.mod", "module %s\n" % source["go_module"])
                write(scratch, "lib/app/domain/models/bad.dart", text)
                output = io.StringIO()
                with contextlib.redirect_stderr(output):
                    result = arch.main(["--root", scratch, "--warn-only"])
                self.assertEqual(2, result)
                self.assertIn("lib/app/domain/models/bad.dart:%d" % line, output.getvalue())

    def test_declarations_leave_later_domain_imports_visible(self):
        for declaration in (
            "library library.import;", "void part() {}", "part<T>() {}",
            "final value = of(part);", "final value = () { return part; };",
            "final value = <int>[part];", "final value = {part};",
            "@prefix.import<List<int>>.named(of(part)) void of() {}",
        ):
            with self.subTest(declaration=declaration):
                self.assertEqual(["F-DOMAIN-PURE"], self.scan_case({
                    "file": "lib/app/domain/models/calibration_probe.dart",
                    "source": declaration + "\nimport 'package:flutter/material.dart';\n",
                }))

    def test_reserved_words_cannot_be_library_name_segments(self):
        reserved = (
            "assert break case catch class const continue default do else enum extends "
            "false final finally for if in is new null rethrow return super switch this "
            "throw true try var void while with"
        ).split()
        for word in reserved:
            for directive in ("library", "part of"):
                with self.subTest(word=word, directive=directive):
                    with self.assertRaises(arch.DirectiveError):
                        arch.parse_dart_directives("%s name.%s;" % (directive, word))

    def test_baseline_shrink_only_removes_entries(self):
        with tempfile.TemporaryDirectory(prefix="arch-baseline-") as scratch:
            baseline_path = "quality/architecture-baseline.json"
            initial = {"violations": ["kept", "stale"]}
            write(scratch, baseline_path, json.dumps(initial))
            args = argparse.Namespace(init_baseline=False, shrink_baseline=True)

            baseline, stale = arch.settle_baseline(
                args,
                scratch,
                baseline_path,
                {"kept", "new"},
            )

            self.assertEqual(baseline, {"kept"})
            self.assertEqual(stale, [])
            with open(os.path.join(scratch, baseline_path), encoding="utf-8") as handle:
                self.assertEqual(json.load(handle)["violations"], ["kept"])

    def test_new_and_stale_violations_are_reported(self):
        _, _, _, rules, _ = arch.load_config(REPO_ROOT, arch.DEFAULT_CONFIG)
        rule = next(item for item in rules if item.id == "F-ISOLATION")
        violations = [(rule, "lib/app/features/alpha/probe.dart", 2,
                       "lib/app/features/beta/probe.dart")]
        stale = ["F-ISOLATION|lib/app/features/old/probe.dart|missing.dart"]
        output = io.StringIO()

        with contextlib.redirect_stdout(output):
            new, known = arch.report(violations, set(), stale, False)

        self.assertEqual(len(new), 1)
        self.assertEqual(known, [])
        self.assertIn("NEW lib/app/features/alpha/probe.dart:2 F-ISOLATION", output.getvalue())
        self.assertIn("STALE baseline entry", output.getvalue())


if __name__ == "__main__":
    unittest.main()
