"""Lex import/export URI branches without relying on a Dart SDK.

Comments, nested interpolation expressions, and string literals are handled by
an explicit state stack. Unsupported directive URI expressions fail closed.
"""


class DirectiveError(ValueError):
    def __init__(self, line, message):
        super().__init__(message)
        self.line = line


class _Lexer:
    def __init__(self, text):
        self.text = text
        self.pos = 0
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
        if char.isspace():
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
        elif char.isalpha() or char == "_":
            end = pos + 1
            while end < len(text) and (text[end].isalnum() or text[end] == "_"):
                end += 1
            if len(self.stack) == 1 and self.brace_depth == 0:
                self.tokens.append(("identifier", text[pos:end], self.line, self.line_start))
            self._move(end, visible=True)
        else:
            if len(self.stack) == 1:
                if self.brace_depth == 0:
                    self.tokens.append(("symbol", char, self.line, self.line_start))
                if char == "{":
                    self.brace_depth += 1
                elif char == "}":
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


def parse_dart_directives(text):
    """Return {kind, uri, line} for every import/export URI branch."""
    tokens = _Lexer(text).scan()
    result = []
    index = 0
    while index < len(tokens):
        kind, value, line, _at_line_start = tokens[index]
        index += 1
        if kind != "identifier" or value not in ("import", "export"):
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
