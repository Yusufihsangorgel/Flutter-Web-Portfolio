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
  return `Contact: mailto:${email}\nExpires: ${expires.toISOString()}\nPreferred-Languages: en, tr\nCanonical: ${new URL('.well-known/security.txt', site).toString()}\n`;
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
