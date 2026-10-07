import { readFileSync } from 'node:fs';

const fixture = (name) =>
  JSON.parse(readFileSync(new URL(`./${name}.json`, import.meta.url), 'utf8'));

globalThis.fetch = async (url) => {
  if (url.endsWith('/api/packages/re2')) {
    return Response.json({ latest: { version: '1.0.0' } });
  }
  if (url.endsWith('/api/packages/re2/score')) {
    if (process.env.REFRESH_TEST_SCORE_FAILURE === '1') {
      return Response.json({ error: 'unavailable' }, { status: 404 });
    }
    if (process.env.REFRESH_TEST_CONFIRMED_DROP === '1') {
      return Response.json({
        grantedPoints: 140,
        maxPoints: 160,
        likeCount: 2,
        downloadCount30Days: 600,
      });
    }
    return Response.json(fixture('pub-score-pending'));
  }
  if (url.endsWith('/api/packages/re2/metrics')) {
    return Response.json(
      fixture(
        process.env.REFRESH_TEST_CONFIRMED_DROP === '1'
          ? 'pub-metrics-confirmed'
          : 'pub-metrics-pending',
      ),
    );
  }
  throw new Error(`Unexpected request: ${url}`);
};
