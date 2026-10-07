export const hstsValue = 'max-age=31536000';

export function renderContentSecurityPolicy(data) {
  const analyticsOrigin = data.site.analytics
    ? new URL(data.site.analytics.script_url).origin
    : null;
  const scripts = ["'self'", "'wasm-unsafe-eval'", analyticsOrigin].filter(Boolean).join(' ');
  const connections = ["'self'", analyticsOrigin].filter(Boolean).join(' ');
  const images = ["'self'", 'data:', 'blob:', ...imageOrigins(data)].join(' ');
  return `default-src 'self'; base-uri 'self'; object-src 'none'; form-action 'self'; script-src ${scripts}; worker-src 'self' blob:; style-src 'self' 'unsafe-inline'; font-src 'self'; img-src ${images}; connect-src ${connections}; frame-ancestors 'self'; upgrade-insecure-requests;`;
}

export function securityHeaders(data) {
  return {
    'Strict-Transport-Security': hstsValue,
    'Content-Security-Policy': renderContentSecurityPolicy(data),
  };
}

export function renderSecurityTxt(data, generatedAt = new Date()) {
  const email = String(data.profile.email);
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    throw new Error('profile.email must be a valid public contact address');
  }
  const site = new URL(data.site.url);
  if (site.protocol !== 'https:') throw new Error('site.url must use HTTPS');
  site.pathname = `${site.pathname.replace(/\/$/, '')}/`;
  site.search = '';
  site.hash = '';
  const expires = new Date(generatedAt);
  expires.setUTCDate(expires.getUTCDate() + 365);
  return `Contact: mailto:${email}\nExpires: ${expires.toISOString()}\nPreferred-Languages: ${preferredLanguages(data).join(', ')}\nCanonical: ${new URL('.well-known/security.txt', site).toString()}\n`;
}

// sync:content renews a month ahead; verify:content fails only in the last week.
export const securityTxtRenewDays = 30;
export const securityTxtCheckDays = 7;

export function securityTxtNeedsUpdate(current, expected, { now = Date.now(), checkOnly = false } = {}) {
  const withoutExpiry = (text) => text.replace(/^Expires: .+$/m, '');
  if (withoutExpiry(current) !== withoutExpiry(expected)) return true;
  const expires = Date.parse(current.match(/^Expires: (.+)$/m)?.[1] ?? '');
  const days = checkOnly ? securityTxtCheckDays : securityTxtRenewDays;
  return !(expires - now > days * 24 * 60 * 60 * 1000);
}

function preferredLanguages(data) {
  const locales = data.site.locales;
  if (!Array.isArray(locales) || locales.length === 0 ||
    !locales.every((locale) => typeof locale === 'string' && /^[a-z]{2}(?:-[A-Z]{2})?$/.test(locale))) {
    throw new Error('site.locales must list the published language tags');
  }
  return locales;
}

function imageOrigins(data) {
  const origins = new Set();
  function visit(value, key = '') {
    if (Array.isArray(value)) {
      for (const item of value) visit(item, key);
    } else if (value && typeof value === 'object') {
      for (const [name, item] of Object.entries(value)) visit(item, name);
    } else if (typeof value === 'string' && /(?:image|logo|thumbnail|avatar|photo)/i.test(key)) {
      if (value.startsWith('https://')) origins.add(new URL(value).origin);
    }
  }
  visit(data);
  return [...origins].sort();
}
