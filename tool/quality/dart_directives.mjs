// Dart directive URI scanner. Lexical nesting keeps interpolation strings from
// hiding subsequent directives; it intentionally does not parse Dart expressions.
function location(file, line, message) {
  return new Error(`${file}:${line}: ${message}`);
}

function endOfBlockComment(source, start, file, line) {
  let depth = 1;
  let index = start + 2;
  while (index < source.length && depth > 0) {
    if (source.startsWith('/*', index)) {
      depth += 1;
      index += 2;
    } else if (source.startsWith('*/', index)) {
      depth -= 1;
      index += 2;
    } else index += 1;
  }
  if (depth !== 0) throw location(file, line, 'unterminated block comment');
  return index;
}

class DartLexer {
  constructor(source, file) {
    this.source = source;
    this.file = file;
    this.tokens = [];
    this.frames = [{ kind: 'code' }];
    this.index = 0;
    this.line = 1;
    this.braceDepth = 0;
  }

  advance(end) {
    for (let position = this.index; position < end; position += 1) {
      if (this.source[position] === '\r') this.line += 1;
      else if (this.source[position] === '\n' && this.source[position - 1] !== '\r') this.line += 1;
    }
    this.index = end;
  }

  scanString(frame) {
    const { source, index } = this;
    const char = source[index];
    if (source.startsWith(frame.quote, index)) {
      if (frame.capture) {
        this.tokens.push({
          type: 'string',
          value: source.slice(frame.start, index),
          line: frame.line,
          escaped: frame.escaped,
          interpolated: frame.interpolated,
        });
      }
      this.advance(index + frame.quote.length);
      this.frames.pop();
    } else if (!frame.raw && char === '\\') {
      frame.escaped = true;
      this.advance(Math.min(source.length, index + 2));
    } else if (!frame.raw && char === '$') {
      this.scanInterpolation(frame);
    } else if (frame.quote.length === 1 && (char === '\n' || char === '\r')) {
      throw location(this.file, frame.line, 'unterminated string');
    } else this.advance(index + 1);
  }

  scanInterpolation(frame) {
    frame.interpolated = true;
    const { source, index, line } = this;
    if (source[index + 1] === '{') {
      this.advance(index + 2);
      this.frames.push({ kind: 'interpolation', braces: 1, line });
      return;
    }
    const name = /^[A-Za-z_$][\w$]*/.exec(source.slice(index + 1));
    if (!name) throw location(this.file, line, 'unsupported string interpolation');
    this.advance(index + 1 + name[0].length);
  }

  scanCode(frame) {
    const { source, index, line } = this;
    const char = source[index];
    if (/\s/.test(char)) {
      this.advance(index + 1);
      return;
    }
    if (source.startsWith('//', index)) {
      const end = source.slice(index).search(/[\r\n]/);
      this.advance(end < 0 ? source.length : index + end);
      return;
    }
    if (source.startsWith('/*', index)) {
      this.advance(endOfBlockComment(source, index, this.file, line));
      return;
    }
    if (frame.kind === 'interpolation' && char === '}') {
      frame.braces -= 1;
      this.advance(index + 1);
      if (frame.braces === 0) this.frames.pop();
      return;
    }
    if (frame.kind === 'interpolation' && char === '{') frame.braces += 1;
    const raw = char === 'r' && (source[index + 1] === "'" || source[index + 1] === '"');
    const marker = source[index + Number(raw)];
    if (marker === "'" || marker === '"') {
      this.startString(marker, raw);
      return;
    }
    this.scanToken();
  }

  startString(marker, raw) {
    const { source, index, line } = this;
    const quote = source.startsWith(marker.repeat(3), index + Number(raw))
      ? marker.repeat(3)
      : marker;
    this.advance(index + Number(raw) + quote.length);
    this.frames.push({
      kind: 'string',
      quote,
      raw,
      start: this.index,
      line,
      capture: this.frames.length === 1 && this.braceDepth === 0,
      escaped: false,
      interpolated: false,
    });
  }

  scanToken() {
    const { source, index, line } = this;
    const word = /^[A-Za-z_$][\w$]*/.exec(source.slice(index));
    const value = word ? word[0] : source[index];
    if (this.frames.length === 1) {
      if (this.braceDepth === 0)
        this.tokens.push({ type: word ? 'word' : 'symbol', value, line, index });
      if (value === '{') this.braceDepth += 1;
      else if (value === '}') this.braceDepth -= 1;
    }
    this.advance(index + value.length);
  }

  lex() {
    while (this.index < this.source.length) {
      const frame = this.frames.at(-1);
      if (frame.kind === 'string') this.scanString(frame);
      else this.scanCode(frame);
    }
    if (this.frames.length !== 1) {
      const frame = this.frames.at(-1);
      throw location(this.file, frame.line, `unterminated ${frame.kind}`);
    }
    return this.tokens;
  }
}

function requireUri(tokens, index, file, line) {
  const token = tokens[index];
  if (token?.type !== 'string')
    throw location(file, token?.line ?? line, 'unsupported directive URI');
  if (!token.value || token.escaped || token.interpolated) {
    throw location(file, token.line, 'unsupported directive URI syntax');
  }
  return { kind: 'uri', uri: token.value, line: token.line };
}

function afterCondition(tokens, index, file, line) {
  if (tokens[index]?.type !== 'symbol' || tokens[index].value !== '(')
    throw location(file, line, 'expected conditional predicate');
  let depth = 0;
  for (let cursor = index; cursor < tokens.length; cursor += 1) {
    if (tokens[cursor].type === 'symbol' && tokens[cursor].value === '(') depth += 1;
    else if (tokens[cursor].type === 'symbol' && tokens[cursor].value === ')') depth -= 1;
    if (depth === 0) return cursor + 1;
  }
  throw location(file, line, 'unterminated conditional predicate');
}

function consumeCombinator(tokens, cursor, file) {
  let next = cursor + 1;
  if (tokens[next]?.type !== 'word')
    throw location(file, tokens[cursor].line, 'expected combinator name');
  next += 1;
  while (
    tokens[next]?.type === 'symbol' &&
    tokens[next].value === ',' &&
    tokens[next + 1]?.type === 'word'
  )
    next += 2;
  return next;
}

function consumeClause(context, cursor) {
  const { tokens, file, kind, directives } = context;
  const token = tokens[cursor];
  if (token.value === 'if' && (kind === 'import' || kind === 'export')) {
    const next = afterCondition(tokens, cursor + 1, file, token.line);
    directives.push({ ...requireUri(tokens, next, file, token.line), kind });
    return next + 1;
  }
  if (token.value === 'deferred' && kind === 'import') return cursor + 1;
  if (token.value === 'as' && kind === 'import' && tokens[cursor + 1]?.type === 'word') {
    return cursor + 2;
  }
  if (
    (token.value === 'show' || token.value === 'hide') &&
    (kind === 'import' || kind === 'export')
  ) {
    return consumeCombinator(tokens, cursor, file);
  }
  throw location(file, token.line, 'unsupported directive syntax');
}

function parseDirective(tokens, start, file) {
  const keyword = tokens[start];
  let cursor = start + 1;
  let kind = keyword.value;
  if (kind === 'part' && tokens[cursor]?.value === 'of') {
    kind = 'part of';
    cursor += 1;
    // Dart also permits `part of library.name;`, which is not a URI edge.
    if (tokens[cursor]?.type === 'word') {
      while (
        cursor < tokens.length &&
        (tokens[cursor].type !== 'symbol' || tokens[cursor].value !== ';')
      )
        cursor += 1;
      if (cursor === tokens.length)
        throw location(file, keyword.line, 'unterminated part of directive');
      return { next: cursor, directives: [] };
    }
  }
  const first = requireUri(tokens, cursor, file, keyword.line);
  const directives = [{ ...first, kind }];
  cursor += 1;
  while (tokens[cursor]?.type !== 'symbol' || tokens[cursor].value !== ';') {
    if (!tokens[cursor]) throw location(file, keyword.line, 'unterminated directive');
    cursor = consumeClause({ tokens, file, kind, directives }, cursor);
  }
  return { next: cursor, directives };
}

export function parseDartDirectives(source, file = '<source>') {
  const tokens = new DartLexer(source, file).lex();
  const directives = [];
  for (let index = 0; index < tokens.length; index += 1) {
    const token = tokens[index];
    if (token.type !== 'word' || !['import', 'export', 'part'].includes(token.value)) continue;
    const parsed = parseDirective(tokens, index, file);
    directives.push(...parsed.directives);
    index = parsed.next;
  }
  return directives;
}
