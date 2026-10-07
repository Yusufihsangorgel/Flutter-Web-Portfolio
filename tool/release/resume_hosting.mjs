const revalidation = 'public, max-age=0, must-revalidate';
const documents = [
  { file: 'resume.pdf', type: 'application/pdf', extension: 'pdf' },
  { file: 'resume.html', type: 'text/html', extension: 'html' },
];

export function validateResumeHosting({ nginx, firebase, vercel, netlify }) {
  const errors = [];
  const nginxSource = nginx.replace(/#.*$/gm, '');
  for (const document of documents) {
    errors.push(...nginxIssues(nginxSource, document));
    for (const [host, groups, source] of [
      ['firebase', firebase.hosting?.headers, document.file],
      ['vercel', vercel.headers, `/${document.file}`],
      ['netlify', netlifyHeaders(netlify), `/${document.file}`],
    ]) {
      const matching = (groups ?? []).filter((group) => group.source === source);
      if (matching.length !== 1 || !validHeaders(matching[0].headers, document.type)) {
        errors.push(`${host} ${document.file} must declare its MIME type and revalidation policy`);
      }
    }
  }
  return errors;
}

function validHeaders(headers, type) {
  return [
    ['content-type', type],
    ['cache-control', revalidation],
  ].every(([key, value]) => {
    const matching = (headers ?? []).filter((header) => header.key.toLowerCase() === key);
    return matching.length === 1 && matching[0].value === value;
  });
}

function nginxIssues(source, { file, type, extension }) {
  const errors = [];
  const pattern = new RegExp(`\\blocation\\s+=\\s+/${file.replace('.', '\\.')}\\s*\\{`, 'g');
  const locations = [...source.matchAll(pattern)];
  const location = locations[0];
  const body = location ? blockBody(source, location.index + location[0].length) : '';
  const mime = new RegExp(`\\btypes\\s*\\{\\s*${type}\\s+${extension};\\s*\\}`);
  const cache = `add_header Cache-Control "${revalidation}" always;`;
  const server = source.split(/\blocation\b/)[0];
  const inherited = singleDirective(server, 'add_header_inherit', 'merge');
  const overridden = /\b(?:return|rewrite|alias|root|expires|add_header_inherit)\b/.test(body);
  if (locations.length !== 1 || !mime.test(body)) {
    errors.push(`nginx ${file} must have an exact location and MIME type`);
  }
  if (!singleDirective(body, 'try_files', '$uri =404') || overridden) {
    errors.push(`nginx ${file} must serve the requested document directly`);
  }
  const cacheHeaders = [...body.matchAll(/\badd_header\s+Cache-Control\s+[^;]+;/gi)];
  const securityOverride = /\badd_header\b/.test(body.replace(cache, ''));
  if (cacheHeaders.length !== 1 || cacheHeaders[0][0] !== cache || !inherited || securityOverride) {
    errors.push(`nginx ${file} must revalidate and inherit document security headers`);
  }
  const compressed =
    extension === 'pdf'
      ? singleDirective(body, 'gzip', 'off') && singleDirective(body, 'gzip_static', 'off')
      : singleDirective(server, 'gzip_static', 'on') && !/\bgzip_static\b/.test(body);
  if (!compressed) errors.push(`nginx ${file} compression policy is missing or incorrect`);
  return errors;
}

function singleDirective(source, name, expected) {
  const matches = [...source.matchAll(new RegExp(`\\b${name}\\s+([^;]+);`, 'g'))];
  return matches.length === 1 && matches[0][1].trim().replace(/\s+/g, ' ') === expected;
}

function blockBody(source, start) {
  let depth = 1;
  const tail = source.slice(start);
  for (const token of tail.matchAll(/"[^"]*"|'[^']*'|[{}]/g)) {
    if (token[0] === '{') depth += 1;
    if (token[0] === '}') depth -= 1;
    if (depth === 0) return tail.slice(0, token.index);
  }
  return '';
}

function netlifyHeaders(source) {
  source = source.replace(/^\s*#.*$/gm, '');
  return [...source.matchAll(/\[\[headers\]\]([\s\S]*?)(?=\n\s*\[\[|$)/g)].map(([, block]) => {
    const tables = block.split(/^\s*\[headers\.values\]\s*$/m);
    const values = tables.length === 2 ? tables[1].split(/^\s*\[/m)[0] : '';
    return {
      source: tables[0].match(/^\s*for\s*=\s*"([^"]+)"\s*$/m)?.[1],
      headers: [...values.matchAll(/^\s*([\w-]+)\s*=\s*"([^"]*)"\s*$/gm)].map(([, key, value]) => ({
        key,
        value,
      })),
    };
  });
}
