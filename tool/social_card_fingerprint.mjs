import { createHash, timingSafeEqual } from 'node:crypto';

const schema = 'portfolio-social-card/v1';

export function sha256(bytes) {
  return createHash('sha256').update(bytes).digest('hex');
}

export function serializeSocialCardFingerprint({ inputDigest, pngBytes }) {
  assertDigest(inputDigest, 'input digest');
  if (!Buffer.isBuffer(pngBytes) || pngBytes.length === 0) {
    throw new Error('social-card PNG must be non-empty bytes');
  }
  return `${JSON.stringify(
    {
      schema,
      input_sha256: inputDigest,
      png_sha256: sha256(pngBytes),
    },
    null,
    2,
  )}\n`;
}

export function verifySocialCardFingerprint({
  fingerprintText,
  expectedInputDigest,
  pngBytes,
}) {
  assertDigest(expectedInputDigest, 'expected input digest');
  if (!Buffer.isBuffer(pngBytes) || pngBytes.length === 0) return false;

  let document;
  try {
    document = JSON.parse(fingerprintText);
  } catch {
    return false;
  }
  if (
    document?.schema !== schema ||
    !isDigest(document.input_sha256) ||
    !isDigest(document.png_sha256)
  ) {
    return false;
  }

  return (
    equalDigest(document.input_sha256, expectedInputDigest) &&
    equalDigest(document.png_sha256, sha256(pngBytes))
  );
}

function assertDigest(value, label) {
  if (!isDigest(value)) throw new Error(`${label} must be a SHA-256 digest`);
}

function isDigest(value) {
  return typeof value === 'string' && /^[0-9a-f]{64}$/.test(value);
}

function equalDigest(left, right) {
  return timingSafeEqual(Buffer.from(left, 'hex'), Buffer.from(right, 'hex'));
}
