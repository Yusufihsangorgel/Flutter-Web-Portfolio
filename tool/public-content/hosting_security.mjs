import { parseGlobalStaticHeaders } from '../release/static_header_policy.mjs';
import { securityHeaders } from './security.mjs';

export function validateHostingSecurity(config, content) {
  const errors = [];
  const expected = securityHeaders(content);
  for (const [host, headers] of Object.entries(globalHeaders(config, errors))) {
    if (headers['Strict-Transport-Security'] !== expected['Strict-Transport-Security']) {
      errors.push(`${host} HSTS is missing or differs from policy`);
    }
    const csp = headers['Content-Security-Policy'];
    const script = csp?.match(/(?:^|;)\s*script-src\s+([^;]+)/)?.[1] ?? '';
    if (csp !== expected['Content-Security-Policy'] || /'unsafe-(?:inline|eval)'/.test(script)) {
      errors.push(`${host} CSP is missing, unsafe, or differs from policy`);
    }
  }
  for (const error of catchAllErrors(config)) errors.push(error);
  return errors;
}

function globalHeaders(config, errors) {
  const nginxServer = config.nginx.match(/\bserver\s*\{([\s\S]*?)(?=^\s*location\b)/m)?.[1] ?? '';
  let staticHeaders = {};
  try {
    staticHeaders = Object.fromEntries(
      parseGlobalStaticHeaders(config.staticHeaders).map(({ name, value }) => [name, value]),
    );
  } catch {
    errors.push('staticHeaders global block is missing or invalid');
  }
  const firebaseGroup = config.firebase.hosting?.headers?.find((group) => group.source === '**');
  const vercelGroup = config.vercel.headers?.find((group) => group.source === '/(.*)');
  const netlifyGroup = [
    ...config.netlify.matchAll(/\[\[headers\]\]([\s\S]*?)(?=\[\[headers\]\]|\[\[redirects\]\]|$)/g),
  ]
    .map((match) => match[1])
    .find((block) => /^\s*for\s*=\s*"\/\*"\s*$/m.test(block));
  return {
    nginx: Object.fromEntries(
      [...nginxServer.matchAll(/^\s*add_header ([\w-]+) "([^"]*)" always;/gm)].map((match) => [
        match[1],
        match[2],
      ]),
    ),
    staticHeaders,
    firebase: Object.fromEntries(
      firebaseGroup?.headers?.map(({ key, value }) => [key, value]) ?? [],
    ),
    vercel: Object.fromEntries(vercelGroup?.headers?.map(({ key, value }) => [key, value]) ?? []),
    netlify: Object.fromEntries(
      [
        ...(netlifyGroup ?? '').matchAll(
          /^\s{2}(Strict-Transport-Security|Content-Security-Policy) = "([^"]*)"$/gm,
        ),
      ].map((match) => [match[1], match[2]]),
    ),
  };
}

function catchAllErrors(config) {
  const errors = [];
  errors.push(...nginxCatchAllErrors(config.nginx));
  if (
    [
      ...(config.firebase.hosting?.rewrites ?? []),
      ...(config.firebase.hosting?.redirects ?? []),
    ].some(isIndexCatchAll)
  )
    errors.push('firebase catch-all rewrite exists');
  if ([...(config.vercel.rewrites ?? []), ...(config.vercel.redirects ?? [])].some(isIndexCatchAll))
    errors.push('vercel catch-all rewrite exists');
  if (/^\s*\/\*\s+\/(?:index\.html)?(?:\s|$)/m.test(config.redirects))
    errors.push('redirects catch-all rewrite exists');
  const netlifyRedirects = [
    ...config.netlify.matchAll(/\[\[redirects\]\]([\s\S]*?)(?=\[\[redirects\]\]|$)/g),
  ].map((match) => match[1]);
  if (
    netlifyRedirects.some(
      (block) =>
        /^\s*from\s*=\s*"\/\*"\s*$/m.test(block) &&
        /^\s*to\s*=\s*"\/(?:index\.html)?"\s*$/m.test(block),
    )
  )
    errors.push('netlify catch-all rewrite exists');
  return errors;
}

function isIndexCatchAll(rewrite) {
  const source = rewrite.source ?? rewrite.from;
  const destination = rewrite.destination ?? rewrite.to;
  return (
    ['**', '/*', '/(.*)', '/:path*'].includes(source) && ['/', '/index.html'].includes(destination)
  );
}

function nginxCatchAllErrors(nginx) {
  const errors = [];
  const nginxRoot = nginx.match(/location\s+\/\s*\{([^}]*)\}/)?.[1] ?? '';
  const nginxGlobal = nginx.match(/\bserver\s*\{([\s\S]*?)(?=^\s*location\b)/m)?.[1] ?? '';
  const globalRewrites = [
    ...nginxGlobal.matchAll(/\brewrite\s+(\S+)\s+\/(?:index\.html)?(?=\s|;)/g),
  ];
  const globalCatchAll = globalRewrites.some((match) => {
    const source = match[1].replace(/^\^\/?/, '').replace(/\$$/, '');
    return ['', '.*', '(.*)'].includes(source);
  });
  if (
    /\btry_files\s+[^;]*\s\/(?:index\.html)?(?:\s|;)/.test(nginxRoot) ||
    /\brewrite\s+\S+\s+\/(?:index\.html)?(?:\s|;)/.test(nginxRoot) ||
    globalCatchAll
  ) {
    errors.push('nginx catch-all rewrite exists');
  }
  return errors;
}
