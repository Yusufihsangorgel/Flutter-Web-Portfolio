function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export function createLimiter(limit) {
  let active = 0;
  const queue = [];
  const runNext = () => {
    if (active >= limit || queue.length === 0) return;
    active += 1;
    const { fn, resolve, reject } = queue.shift();
    fn().then(
      (value) => {
        active -= 1;
        resolve(value);
        runNext();
      },
      (error) => {
        active -= 1;
        reject(error);
        runNext();
      },
    );
  };
  return function run(fn) {
    return new Promise((resolve, reject) => {
      queue.push({ fn, resolve, reject });
      runNext();
    });
  };
}

/**
 * @param {string} url
 * @param {{headers?: HeadersInit, attempts?: number}} options
 */
export async function fetchJson(url, { headers, attempts = 3 } = {}) {
  let lastError = null;
  for (let attempt = 1; attempt <= attempts; attempt += 1) {
    try {
      const response = await fetch(url, { headers });
      if (response.ok) {
        return { ok: true, status: response.status, body: await response.json() };
      }
      if (response.status >= 500 || response.status === 429) {
        lastError = new Error(`${url} responded ${response.status}`);
      } else {
        let body = null;
        try {
          body = await response.json();
        } catch {
          body = null;
        }
        return { ok: false, status: response.status, body, error: null };
      }
    } catch (error) {
      lastError = error;
    }
    if (attempt < attempts) await delay(attempt * 500);
  }
  return { ok: false, status: null, body: null, error: lastError };
}

/**
 * @param {string} url
 * @param {{headers?: HeadersInit, attempts?: number}} options
 */
export async function fetchText(url, { headers, attempts = 3 } = {}) {
  let lastError = null;
  for (let attempt = 1; attempt <= attempts; attempt += 1) {
    try {
      const response = await fetch(url, { headers });
      if (response.ok) {
        return { ok: true, status: response.status, body: await response.text() };
      }
      if (response.status >= 500 || response.status === 429) {
        lastError = new Error(`${url} responded ${response.status}`);
      } else {
        return { ok: false, status: response.status, body: null, error: null };
      }
    } catch (error) {
      lastError = error;
    }
    if (attempt < attempts) await delay(attempt * 500);
  }
  return { ok: false, status: null, body: null, error: lastError };
}

export function describeFetchFailure(result, label) {
  if (result.error) return `${label}: ${result.error.message}`;
  return `${label}: HTTP ${result.status}`;
}
