let failures = 0;

export function test(label, fn) {
  try {
    fn();
    console.log(`ok - ${label}`);
  } catch (error) {
    failures += 1;
    console.error(`not ok - ${label}`);
    console.error(error);
  }
}

/** @returns {Record<string, any>} */
export function samplePackage(overrides = {}) {
  return {
    id: 'redis_task_queue',
    name: 'redis_task_queue',
    description: 'Old description.',
    url: 'https://pub.dev/packages/redis_task_queue',
    repository: 'https://github.com/example/redis_task_queue',
    version: '1.1.4',
    likes: 1,
    pub_points: 160,
    downloads: 546,
    category: 'server',
    topics: [],
    maturity: 'L3',
    proof: 'A measured claim that must never be touched.',
    roadmap: [{ title: 'Untouched roadmap entry', status: 'done' }],
    ...overrides,
  };
}

export function reportResults() {
  if (failures > 0) {
    console.error(`\n${failures} test(s) failed.`);
    process.exitCode = 1;
  } else {
    console.log('\nAll refresh_portfolio_data tests passed.');
  }
}
