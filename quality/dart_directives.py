"""Lex import/export URI branches without relying on a Dart SDK.

Comments, nested interpolation expressions, and string literals are handled by
an explicit state stack. Unsupported directive URI expressions fail closed.
"""


# Reserved keywords cannot be library-name segments; built-in and contextual
# keywords can. Categories follow _fe_analyzer_shared's scanner/token.dart.
_RESERVED = frozenset((
    "assert break case catch class const continue default do else enum extends "
    "false final finally for if in is new null rethrow return super switch this "
    "throw true try var void while with"
).split())
_DIRECTIVES = ("import", "export", "part", "library")


class DirectiveError(ValueError):
    def __init__(self, line, message):
        super().__init__(message)
        self.line = line


class _Lexer:
    def __init__(self, text):
        self.text = text
        self.pos = int(text.startswith("\ufeff"))
        self.line = 1
        self.line_start = True
        self.brace_depth = 0
        self.stack = [{"kind": "code"}]
        self.tokens = []

    def _move(self, end, visible=False):
        chunk = self.text[self.pos:end]
        self.line += (chunk.count("\n") + chunk.count("\r") - chunk.count("\r\n")
                      - int(chunk.startswith("\n") and self.pos > 0
                            and self.text[self.pos - 1] == "\r"))
        if "\n" in chunk or "\r" in chunk:
            self.line_start = not visible
        elif visible:
            self.line_start = False
        self.pos = end

    def _string_start(self, raw=False):
        start, line = self.pos, self.line
        quote_pos = start + int(raw)
        char = self.text[quote_pos]
        length = 3 if self.text.startswith(char * 3, quote_pos) else 1
        self.stack.append({"kind": "string", "quote": char * length, "raw": raw,
                           "start": start, "line": line, "content": quote_pos + length,
                           "interpolated": False, "root": len(self.stack) == 1 and self.brace_depth == 0})
        self._move(quote_pos + length, visible=True)

    def _string(self, frame):
        text, pos = self.text, self.pos
        quote = frame["quote"]
        if text.startswith(quote, pos):
            if frame["root"]:
                value = text[frame["content"]:pos]
                kind = "unsupported" if frame["interpolated"] or "\\" in value else "string"
                self.tokens.append((kind, value, frame["line"], False))
            self.stack.pop()
            self._move(pos + len(quote), visible=True)
        elif not frame["raw"] and text[pos] == "\\":
            if pos + 1 == len(text):
                raise DirectiveError(frame["line"], "unterminated string escape")
            self._move(pos + 2, visible=True)
        elif not frame["raw"] and text.startswith("${", pos):
            frame["interpolated"] = True
            self.stack.append({"kind": "interpolation", "depth": 1, "line": frame["line"]})
            self._move(pos + 2, visible=True)
        elif not frame["raw"] and text[pos] == "$" and pos + 1 < len(text) and (
                text[pos + 1].isalpha() or text[pos + 1] == "_"):
            frame["interpolated"] = True
            end = pos + 2
            while end < len(text) and (text[end].isalnum() or text[end] == "_"):
                end += 1
            self._move(end, visible=True)
        elif len(quote) == 1 and text[pos] in "\r\n":
            raise DirectiveError(frame["line"], "unterminated single-line string")
        else:
            self._move(pos + 1, visible=True)

    def _comment(self, frame):
        text, pos = self.text, self.pos
        if frame["kind"] == "line-comment":
            if text[pos] in "\r\n":
                self.stack.pop()
            self._move(pos + 1)
        elif text.startswith("/*", pos):
            frame["depth"] += 1
            self._move(pos + 2)
        elif text.startswith("*/", pos):
            frame["depth"] -= 1
            self._move(pos + 2)
            if frame["depth"] == 0:
                self.stack.pop()
        else:
            self._move(pos + 1)

    def _code(self, frame):
        text, pos = self.text, self.pos
        char = text[pos]
        if text.startswith("#!", pos) and pos == int(text.startswith("\ufeff")):
            end = pos + 2
            while end < len(text) and text[end] not in "\r\n":
                end += 1
            self._move(end)
        elif char.isspace():
            self._move(pos + 1)
        elif text.startswith("//", pos):
            self.stack.append({"kind": "line-comment"})
            self._move(pos + 2)
        elif text.startswith("/*", pos):
            self.stack.append({"kind": "block-comment", "depth": 1, "line": self.line})
            self._move(pos + 2)
        elif char in "'\"" or (char in "rR" and pos + 1 < len(text) and text[pos + 1] in "'\""):
            self._string_start(raw=char in "rR")
        elif frame["kind"] == "interpolation" and char in "{}":
            frame["depth"] += 1 if char == "{" else -1
            self._move(pos + 1, visible=True)
            if frame["depth"] == 0:
                self.stack.pop()
        elif char.isalpha() or char in "_$":
            end = pos + 1
            while end < len(text) and (text[end].isalnum() or text[end] in "_$"):
                end += 1
            if len(self.stack) == 1 and self.brace_depth == 0:
                self.tokens.append(("identifier", text[pos:end], self.line, self.line_start))
            self._move(end, visible=True)
        else:
            if len(self.stack) == 1:
                if self.brace_depth == 0 or (char == "}" and self.brace_depth == 1):
                    self.tokens.append(("symbol", char, self.line, self.line_start))
                if char == "{":
                    self.brace_depth += 1
                elif char == "}":
                    if self.brace_depth == 0:
                        raise DirectiveError(self.line, "unmatched declaration group close")
                    self.brace_depth -= 1
            self._move(pos + 1, visible=True)

    def scan(self):
        while self.pos < len(self.text):
            frame = self.stack[-1]
            if frame["kind"] == "string":
                self._string(frame)
            elif frame["kind"] in ("line-comment", "block-comment"):
                self._comment(frame)
            else:
                self._code(frame)
        for frame in self.stack[1:]:
            if frame["kind"] != "line-comment":
                raise DirectiveError(frame["line"], "unterminated %s" % frame["kind"])
        return self.tokens


def _uri(tokens, index, directive_line):
    if index >= len(tokens) or tokens[index][0] != "string" or not tokens[index][1]:
        line = tokens[index][2] if index < len(tokens) else directive_line
        raise DirectiveError(line, "unsupported or missing directive URI")
    _, value, line, _ = tokens[index]
    return {"uri": value, "line": line}, index + 1


def _branch(tokens, index, directive_line):
    if index >= len(tokens) or tokens[index][:2] != ("symbol", "("):
        raise DirectiveError(directive_line, "conditional import requires a condition")
    depth = 0
    while index < len(tokens):
        token = tokens[index]
        if token[:2] == ("symbol", "("):
            depth += 1
        elif token[:2] == ("symbol", ")"):
            depth -= 1
            if depth == 0:
                return _uri(tokens, index + 1, directive_line)
        elif token[:2] == ("symbol", ";"):
            break
        index += 1
    raise DirectiveError(directive_line, "unterminated conditional import")


def _modifier(tokens, index):
    keyword = tokens[index][1]
    index += 1
    if keyword == "deferred":
        if index >= len(tokens) or tokens[index][1] != "as":
            raise DirectiveError(tokens[index - 1][2], "deferred import requires as prefix")
        index += 1
    if index >= len(tokens) or tokens[index][0] != "identifier" or tokens[index][1] == "if":
        raise DirectiveError(tokens[index - 1][2], "missing import combinator name")
    index += 1
    if keyword in ("show", "hide"):
        while index < len(tokens) and tokens[index][:2] == ("symbol", ","):
            index += 1
            if index >= len(tokens) or tokens[index][0] != "identifier":
                raise DirectiveError(tokens[index - 1][2], "missing import combinator name")
            index += 1
    return index


def _name_end(tokens, index, directive_line, description):
    # Library-name resolution and other Dart semantics belong to the compiler.
    while index < len(tokens):
        kind, name, _, _ = tokens[index]
        if (kind != "identifier" or name in _RESERVED or not name.isascii()
                or not name.replace("$", "_").isidentifier()):
            break
        index += 1
        if index < len(tokens) and tokens[index][:2] == ("symbol", ";"):
            return index + 1
        if index >= len(tokens) or tokens[index][:2] != ("symbol", "."):
            break
        index += 1
    line = tokens[index][2] if index < len(tokens) else directive_line
    raise DirectiveError(line, "unsupported %s directive" % description)


def _part(tokens, index, directive_line):
    if index < len(tokens) and tokens[index][:2] == ("identifier", "of"):
        index += 1
        if index < len(tokens) and tokens[index][0] == "identifier":
            return _name_end(tokens, index, directive_line, "named part of")
    _, index = _uri(tokens, index, directive_line)
    if index >= len(tokens) or tokens[index][:2] != ("symbol", ";"):
        line = tokens[index][2] if index < len(tokens) else directive_line
        raise DirectiveError(line, "unsupported or unterminated part directive")
    return index + 1


def _group_end(tokens, index):
    """Skip one balanced region; angle brackets are groups only in metadata types."""
    pairs = {"(": ")", "[": "]", "{": "}"}
    if tokens[index][1] == "<":
        pairs["<"] = ">"
    stack = []
    start_line = tokens[index][2]
    while index < len(tokens):
        kind, value, line, _ = tokens[index]
        if kind == "symbol":
            if value in pairs:
                stack.append(pairs[value])
            elif value in pairs.values():
                if not stack or value != stack.pop():
                    raise DirectiveError(line, "unbalanced declaration group")
                if not stack:
                    return index + 1
        index += 1
    raise DirectiveError(start_line, "unterminated declaration group")


def _metadata_end(tokens, index):
    line = tokens[index][2]
    index += 1
    while True:
        if index >= len(tokens) or tokens[index][0] != "identifier":
            raise DirectiveError(line, "unsupported metadata reference")
        index += 1
        if index < len(tokens) and tokens[index][:2] == ("symbol", "<"):
            index = _group_end(tokens, index)
        if index >= len(tokens) or tokens[index][:2] != ("symbol", "."):
            break
        index += 1
    if index < len(tokens) and tokens[index][:2] == ("symbol", "("):
        index = _group_end(tokens, index)
    return index


def _directive_start(tokens, index):
    kind, value, _, _ = tokens[index]
    following = tokens[index + 1][:2] if index + 1 < len(tokens) else None
    return (kind == "identifier" and value in _DIRECTIVES
            and following not in (("symbol", "."), ("symbol", "<"), ("symbol", "(")))


def _declaration_end(tokens, index):
    # This is an item boundary scan, not a Dart declaration/expression parser.
    while index < len(tokens):
        kind, value, line, _ = tokens[index]
        following = tokens[index + 1][:2] if index + 1 < len(tokens) else None
        if kind == "identifier" and value in ("import", "export", "part") and following:
            if following[0] in ("string", "unsupported") or (
                    value == "part" and following == ("identifier", "of")):
                raise DirectiveError(line, "directive inside unfinished declaration")
        if kind == "symbol" and value in ("(", "[", "{"):
            index = _group_end(tokens, index)
            if value == "{":
                return index
        elif kind == "symbol" and value in (")", "]", "}"):
            raise DirectiveError(line, "unmatched declaration group close")
        elif kind == "symbol" and value == ";":
            return index + 1
        else:
            index += 1
    return index


def parse_dart_directives(text):
    """Return import/export URI branches; validate but omit part directives."""
    tokens = _Lexer(text).scan()
    result = []
    index = 0
    while index < len(tokens):
        kind, value, line, _at_line_start = tokens[index]
        if (kind, value) == ("symbol", "@"):
            index = _metadata_end(tokens, index)
            continue
        if not _directive_start(tokens, index):
            index = _declaration_end(tokens, index)
            continue
        index += 1
        if value == "library":
            if index < len(tokens) and tokens[index][:2] == ("symbol", ";"):
                index += 1
            else:
                index = _name_end(tokens, index, line, "library")
            continue
        if value == "part":
            index = _part(tokens, index, line)
            continue
        uri, index = _uri(tokens, index, line)
        result.append({"kind": value, **uri})
        while index < len(tokens) and tokens[index][:2] != ("symbol", ";"):
            token = tokens[index]
            if token[0] == "identifier" and token[1] == "if":
                uri, index = _branch(tokens, index + 1, line)
                result.append({"kind": value, **uri})
            elif token[0] == "identifier" and token[1] in ("deferred", "as", "show", "hide"):
                index = _modifier(tokens, index)
            else:
                raise DirectiveError(token[2], "unsupported directive syntax")
        if index == len(tokens):
            raise DirectiveError(line, "unterminated import/export directive")
        index += 1
    return result
