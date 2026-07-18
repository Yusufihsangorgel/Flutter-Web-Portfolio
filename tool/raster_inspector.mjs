import { inflateSync } from 'node:zlib';

const pngSignature = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
const maxPixels = 100_000_000;
const maxInflatedBytes = 256 * 1024 * 1024;
const maxEncodedBytes = 64 * 1024 * 1024;

export function inspectRaster(bytes, label = 'raster') {
  if (!Buffer.isBuffer(bytes) || bytes.length < 4) {
    throw new Error(`${label} is empty or truncated`);
  }
  if (bytes.length > maxEncodedBytes) throw new Error(`${label} exceeds the encoded raster budget`);
  if (bytes.subarray(0, 8).equals(pngSignature)) return inspectPng(bytes, label);
  if (bytes[0] === 0xff && bytes[1] === 0xd8) return inspectJpeg(bytes, label);
  throw new Error(`${label} is not a supported PNG or JPEG`);
}

export function assertRasterDimensions(info, width, height, label = 'raster') {
  if (
    !Number.isSafeInteger(width) ||
    !Number.isSafeInteger(height) ||
    info.width !== width ||
    info.height !== height
  ) {
    throw new Error(
      `${label} is ${info.width}x${info.height}; expected ${width}x${height}`,
    );
  }
}

function inspectPng(bytes, label) {
  let cursor = 8;
  let header = null;
  let sawEnd = false;
  const compressed = [];

  while (cursor < bytes.length) {
    if (cursor + 12 > bytes.length) throw new Error(`${label} has a truncated PNG chunk`);
    const length = bytes.readUInt32BE(cursor);
    const typeOffset = cursor + 4;
    const dataOffset = cursor + 8;
    const end = dataOffset + length;
    if (length > maxInflatedBytes || end + 4 > bytes.length) {
      throw new Error(`${label} has an invalid PNG chunk length`);
    }
    const type = bytes.toString('ascii', typeOffset, dataOffset);
    const storedCrc = bytes.readUInt32BE(end);
    const actualCrc = crc32(bytes.subarray(typeOffset, end));
    if (storedCrc !== actualCrc) throw new Error(`${label} has a corrupt ${type} chunk`);

    if (cursor === 8 && (type !== 'IHDR' || length !== 13)) {
      throw new Error(`${label} does not begin with a valid IHDR`);
    }
    if (type === 'IHDR') {
      if (header) throw new Error(`${label} contains multiple IHDR chunks`);
      header = {
        width: bytes.readUInt32BE(dataOffset),
        height: bytes.readUInt32BE(dataOffset + 4),
        bitDepth: bytes[dataOffset + 8],
        colorType: bytes[dataOffset + 9],
        compression: bytes[dataOffset + 10],
        filter: bytes[dataOffset + 11],
        interlace: bytes[dataOffset + 12],
      };
      validateDimensions(header.width, header.height, label);
      if (header.compression !== 0 || header.filter !== 0 || header.interlace !== 0) {
        throw new Error(`${label} uses an unsupported PNG encoding`);
      }
      validatePngColor(header, label);
    } else if (type === 'IDAT') {
      if (!header || sawEnd) throw new Error(`${label} has an out-of-order IDAT`);
      compressed.push(bytes.subarray(dataOffset, end));
    } else if (type === 'IEND') {
      if (length !== 0 || !header || compressed.length === 0) {
        throw new Error(`${label} has an invalid IEND`);
      }
      sawEnd = true;
      cursor = end + 4;
      break;
    }
    cursor = end + 4;
  }

  if (!header || !sawEnd || cursor !== bytes.length) {
    throw new Error(`${label} is a truncated or trailing-data PNG`);
  }
  const channels = { 0: 1, 2: 3, 3: 1, 4: 2, 6: 4 }[header.colorType];
  const rowBytes = Math.ceil((header.width * channels * header.bitDepth) / 8);
  const expectedBytes = (rowBytes + 1) * header.height;
  if (!Number.isSafeInteger(expectedBytes) || expectedBytes > maxInflatedBytes) {
    throw new Error(`${label} exceeds the PNG decode budget`);
  }
  let decoded;
  try {
    decoded = inflateSync(Buffer.concat(compressed), {
      maxOutputLength: expectedBytes + 1,
    });
  } catch {
    throw new Error(`${label} has invalid PNG image data`);
  }
  if (decoded.length !== expectedBytes) {
    throw new Error(`${label} has an invalid decoded PNG size`);
  }
  for (let row = 0; row < header.height; row += 1) {
    if (decoded[row * (rowBytes + 1)] > 4) {
      throw new Error(`${label} has an invalid PNG scanline filter`);
    }
  }
  return { format: 'png', width: header.width, height: header.height };
}

function inspectJpeg(bytes, label) {
  let cursor = 2;
  let dimensions = null;
  let sawScan = false;
  let sawEnd = false;

  while (cursor < bytes.length) {
    if (bytes[cursor] !== 0xff) throw new Error(`${label} has invalid JPEG marker framing`);
    const markerStart = cursor;
    while (cursor < bytes.length && bytes[cursor] === 0xff) cursor += 1;
    if (cursor >= bytes.length) throw new Error(`${label} has a truncated JPEG marker`);
    const marker = bytes[cursor];
    cursor += 1;
    if (marker === 0xd9) {
      sawEnd = true;
      break;
    }
    if (marker === 0x00 || marker === 0xd8) {
      throw new Error(`${label} has an unexpected JPEG marker`);
    }
    if (marker === 0x01 || (marker >= 0xd0 && marker <= 0xd7)) continue;
    if (cursor + 2 > bytes.length) throw new Error(`${label} has a truncated JPEG segment`);
    const length = bytes.readUInt16BE(cursor);
    if (length < 2 || cursor + length > bytes.length) {
      throw new Error(`${label} has an invalid JPEG segment length`);
    }
    const dataOffset = cursor + 2;
    const segmentEnd = cursor + length;
    if (isStartOfFrame(marker)) {
      if (length < 8) throw new Error(`${label} has an invalid JPEG frame header`);
      const height = bytes.readUInt16BE(dataOffset + 1);
      const width = bytes.readUInt16BE(dataOffset + 3);
      validateDimensions(width, height, label);
      if (dimensions && (dimensions.width !== width || dimensions.height !== height)) {
        throw new Error(`${label} has inconsistent JPEG frame dimensions`);
      }
      dimensions = { width, height };
    }
    cursor = segmentEnd;
    if (marker === 0xda) {
      sawScan = true;
      let foundMarker = false;
      while (cursor < bytes.length) {
        if (bytes[cursor] !== 0xff) {
          cursor += 1;
          continue;
        }
        let next = cursor + 1;
        while (next < bytes.length && bytes[next] === 0xff) next += 1;
        if (next >= bytes.length) break;
        const value = bytes[next];
        if (value === 0x00 || (value >= 0xd0 && value <= 0xd7)) {
          cursor = next + 1;
          continue;
        }
        foundMarker = true;
        break;
      }
      if (!foundMarker) throw new Error(`${label} has truncated JPEG scan data`);
      if (cursor < markerStart) throw new Error(`${label} has invalid JPEG scan order`);
    }
  }

  if (!dimensions || !sawScan || !sawEnd) {
    throw new Error(`${label} is missing a JPEG frame, scan, or end marker`);
  }
  if (cursor !== bytes.length) {
    throw new Error(`${label} has unexpected trailing JPEG data`);
  }
  return { format: 'jpeg', ...dimensions };
}

function isStartOfFrame(marker) {
  return (
    marker >= 0xc0 &&
    marker <= 0xcf &&
    ![0xc4, 0xc8, 0xcc].includes(marker)
  );
}

function validateDimensions(width, height, label) {
  if (width < 1 || height < 1 || width * height > maxPixels) {
    throw new Error(`${label} has unsafe raster dimensions`);
  }
}

function validatePngColor(header, label) {
  const allowed = {
    0: [1, 2, 4, 8, 16],
    2: [8, 16],
    3: [1, 2, 4, 8],
    4: [8, 16],
    6: [8, 16],
  }[header.colorType];
  if (!allowed?.includes(header.bitDepth)) {
    throw new Error(`${label} has an invalid PNG bit-depth/color-type pair`);
  }
}

function crc32(bytes) {
  let crc = 0xffffffff;
  for (const byte of bytes) {
    crc ^= byte;
    for (let bit = 0; bit < 8; bit += 1) {
      crc = (crc >>> 1) ^ (0xedb88320 & -(crc & 1));
    }
  }
  return (crc ^ 0xffffffff) >>> 0;
}
