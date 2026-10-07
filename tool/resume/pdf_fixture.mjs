// @ts-check
import { deflateSync } from 'node:zlib';

function stream(value) {
  const bytes = deflateSync(Buffer.from(value));
  return `<< /Filter /FlateDecode /Length ${bytes.length} >>\nstream\n${bytes.toString('latin1')}\nendstream`;
}

/**
 * @param {{ text?: string, date?: string, id?: string, metadataOnly?: boolean, arrayRange?: boolean, structured?: boolean }} [options]
 * @returns {Buffer}
 */
export function pdfFixture({
  text = 'Example',
  date = 'D:20261007120000Z',
  id = 'A'.repeat(32),
  metadataOnly = false,
  arrayRange = false,
  structured = false,
} = {}) {
  const characters = [...new Set([...text])];
  const glyph = (index) => (index + 1).toString(16).padStart(4, '0');
  const mappings = characters.map((character, index) => {
    const unicode = Buffer.from(character, 'utf16le').swap16().toString('hex');
    return arrayRange
      ? `<${glyph(index)}> <${glyph(index)}> [<${unicode}>]`
      : `<${glyph(index)}> <${unicode}>`;
  });
  const cmap = `begincmap\n${mappings.length} begin${arrayRange ? 'bfrange' : 'bfchar'}\n${mappings.join('\n')}\nend${arrayRange ? 'bfrange' : 'bfchar'}\nendcmap`;
  const encoded = [...text].map((character) => glyph(characters.indexOf(character))).join('');
  const objects = [
    '<< /Type /Catalog /Pages 2 0 R >>',
    '<< /Type /Pages /Count 1 /Kids [3 0 R] >>',
    '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F4 5 0 R >> >> /Contents 4 0 R >>',
    stream(metadataOnly ? 'q Q' : `BT /F4 22 Tf <${encoded}> Tj ET`),
    '<< /Type /Font /Subtype /Type0 /Encoding /Identity-H /ToUnicode 6 0 R >>',
    stream(cmap),
    `<< /Title (Example) /Author (Example) /CreationDate (${date}) /ModDate (${date}) >>`,
  ];
  if (structured) {
    objects[0] =
      '<< /Type /Catalog /Pages 2 0 R /MarkInfo << /Marked true >> /StructTreeRoot 8 0 R /Outlines 9 0 R >>';
    objects.push(
      '<< /Type /StructTreeRoot /K [] >>',
      '<< /Type /Outlines /First 10 0 R /Last 10 0 R /Count 1 >>',
      '<< /Title (Example) /Parent 9 0 R /Dest [3 0 R /XYZ 0 0 0] >>',
    );
  }
  let output = '%PDF-1.4\n';
  const rows = ['0000000000 65535 f \n'];
  objects.forEach((body, index) => {
    rows.push(`${String(Buffer.byteLength(output, 'latin1')).padStart(10, '0')} 00000 n \n`);
    output += `${index + 1} 0 obj\n${body}\nendobj\n`;
  });
  const offset = Buffer.byteLength(output, 'latin1');
  output += `xref\n0 ${objects.length + 1}\n${rows.join('')}trailer\n<< /Size ${objects.length + 1} /Root 1 0 R /Info 7 0 R /ID [<${id}><${id}>] >>\nstartxref\n${offset}\n%%EOF\n`;
  return Buffer.from(output, 'latin1');
}
