const allowedGlobalHeaders = new Set([
  "content-security-policy",
  "cross-origin-embedder-policy",
  "cross-origin-opener-policy",
  "cross-origin-resource-policy",
  "permissions-policy",
  "referrer-policy",
  "x-content-type-options",
  "x-frame-options",
]);

const maximumPolicyBytes = 64 * 1024;
const maximumHeaderCount = 32;
const maximumHeaderValueLength = 8 * 1024;

/// Parses the global `/*` block used by Netlify and Cloudflare static hosts.
///
/// The preview server intentionally accepts only the response-policy headers
/// it can apply safely. Routing and cache blocks remain owned by the server.
export function parseGlobalStaticHeaders(source) {
  if (typeof source !== "string") {
    throw new TypeError("Static header policy must be text.");
  }
  if (Buffer.byteLength(source, "utf8") > maximumPolicyBytes) {
    throw new Error("Static header policy exceeds 64 KiB.");
  }

  const lines = source.split(/\n/).map((line) => line.replace(/\r$/, ""));
  const globalBlocks = lines
    .map((line, index) => (line.trim() === "/*" ? index : -1))
    .filter((index) => index >= 0);
  if (globalBlocks.length !== 1) {
    throw new Error("Static header policy must contain exactly one global /* block.");
  }

  const headers = new Map();
  for (let index = globalBlocks[0] + 1; index < lines.length; index += 1) {
    const line = lines[index];
    if (line.trim() === "") break;
    if (!/^\s/.test(line)) break;
    if (line.trimStart().startsWith("#")) continue;
    if (/\p{Cc}/u.test(line)) {
      throw new Error(`Static header policy line ${index + 1} contains a control character.`);
    }

    const separator = line.indexOf(":");
    if (separator < 1) {
      throw new Error(`Static header policy line ${index + 1} is malformed.`);
    }
    const name = line.slice(0, separator).trim();
    const value = line.slice(separator + 1).trim();
    const normalizedName = name.toLowerCase();
    if (!/^[A-Za-z][A-Za-z0-9-]{0,63}$/.test(name)) {
      throw new Error(`Static header policy line ${index + 1} has an invalid name.`);
    }
    if (!allowedGlobalHeaders.has(normalizedName)) {
      throw new Error(`Static header policy may not set ${name}.`);
    }
    if (value.length === 0 || value.length > maximumHeaderValueLength) {
      throw new Error(`Static header policy value for ${name} has an invalid length.`);
    }
    if (headers.has(normalizedName)) {
      throw new Error(`Static header policy repeats ${name}.`);
    }
    headers.set(normalizedName, { name, value });
    if (headers.size > maximumHeaderCount) {
      throw new Error("Static header policy declares too many global headers.");
    }
  }

  if (headers.size === 0) {
    throw new Error("Static header policy global block is empty.");
  }
  return [...headers.values()];
}
