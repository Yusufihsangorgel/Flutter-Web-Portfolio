// Only completed or successful Pana tasks are settled; unknown statuses remain pending.
const SETTLED_TASK_STATUSES = new Set(['completed', 'success']);

export function confirmsScore(metricsResponse, grantedPoints) {
  const scorecard = metricsResponse?.scorecard;
  const panaReport = scorecard?.panaReport;
  const sections = panaReport?.report?.sections;
  return panaReport?.reportStatus === 'success' &&
    SETTLED_TASK_STATUSES.has(scorecard?.taskStatus) &&
    Array.isArray(sections) && sections.length > 0 &&
    sections.every((section) => Number.isFinite(section?.grantedPoints) && section.grantedPoints >= 0) &&
    sections.reduce((total, section) => total + section.grantedPoints, 0) === grantedPoints;
}

export function extractPackageFacts(packageResponse, scoreResponse, metricsResponse = null, storedPoints = null) {
  const latest = packageResponse?.latest;
  if (!latest || typeof latest.version !== 'string' || latest.version.length === 0) {
    throw new Error('pub.dev package response is missing latest.version');
  }
  const grantedPoints = scoreResponse?.grantedPoints;
  const maxPoints = scoreResponse?.maxPoints;
  const validScore = Number.isFinite(grantedPoints) && grantedPoints >= 0 &&
    Number.isFinite(maxPoints) && maxPoints > 0;
  const isDrop = Number.isFinite(storedPoints) && grantedPoints < storedPoints;
  const scorePending = !validScore || (isDrop && !confirmsScore(metricsResponse, grantedPoints));
  return {
    version: latest.version,
    likes: typeof scoreResponse?.likeCount === 'number' ? scoreResponse.likeCount : null,
    downloads:
      typeof scoreResponse?.downloadCount30Days === 'number'
        ? scoreResponse.downloadCount30Days
        : null,
    pubPoints: scorePending ? null : grantedPoints,
    maxPoints,
    scorePending,
  };
}

export const COUNTER_FIELDS = new Set(['likes', 'downloads']);

export function applyPackageFacts(pkg, facts) {
  const changedFields = [];
  let visibleChanged = false;
  let counterChanged = false;

  if (facts.version !== pkg.version) {
    pkg.version = facts.version;
    visibleChanged = true;
    changedFields.push('version');
  }

  let pendingScore = false;
  if (facts.scorePending) {
    pendingScore = true;
  } else if (facts.pubPoints !== pkg.pub_points) {
    pkg.pub_points = facts.pubPoints;
    visibleChanged = true;
    changedFields.push('pub_points');
  }

  if (facts.likes !== null && facts.likes !== pkg.likes) {
    pkg.likes = facts.likes;
    counterChanged = true;
    changedFields.push('likes');
  }
  if (facts.downloads !== null && facts.downloads !== pkg.downloads) {
    pkg.downloads = facts.downloads;
    counterChanged = true;
    changedFields.push('downloads');
  }

  return { visibleChanged, counterChanged, pendingScore, changedFields };
}
