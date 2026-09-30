function appendList(lines, heading, items) {
  lines.push(heading, '');
  if (items.length === 0) lines.push('None.');
  else for (const item of items) lines.push(`- ${item}`);
  lines.push('');
}

function appendWriting(lines, summary) {
  lines.push('## Writing', '');
  lines.push(summary.writingChanged
    ? `Updated: ${summary.writingEntryCount} entries (was ${summary.previousWritingEntryCount}).`
    : 'No change.');
  if ((summary.writingFailures ?? []).length === 0) {
    lines.push('No source failures.');
  } else {
    lines.push('Source failures (previously stored entries retained):');
    for (const failure of summary.writingFailures) lines.push(`- ${failure}`);
  }
  lines.push('');
}

function appendScores(lines, summary) {
  lines.push('## Pending pub.dev score', '');
  if ((summary.scoreUnavailable ?? []).length > 0) {
    for (const line of summary.scoreUnavailable) lines.push(`- ${line}`);
  } else if (summary.pendingScorePackages.length === 0) {
    lines.push('None.');
  } else {
    for (const name of summary.pendingScorePackages) {
      lines.push(`- \`${name}\`: pub.dev has not published a score for the latest version yet.`);
    }
  }
  lines.push('');
}

function appendCandidates(lines, summary) {
  lines.push('## Candidate pull requests not yet in contributions', '');
  if (summary.candidatesError) {
    lines.push(`Could not be determined: ${summary.candidatesError}`);
  } else if (summary.candidateGroups.length === 0) {
    lines.push('None.');
  } else {
    for (const group of summary.candidateGroups) {
      lines.push(`### ${group.repo}`, '');
      for (const item of group.items) {
        lines.push(`- [${item.title}](${item.url})${item.mergedDate ? ` — merged ${item.mergedDate}` : ''}`);
      }
      lines.push('');
    }
  }
}

export function buildReport(summary) {
  const lines = [`# Portfolio data refresh — ${summary.generatedAt}`, ''];
  appendList(lines, '## Visible changes', summary.visibleChanges);
  appendList(lines, '## Counter-only changes', summary.counterChanges);
  appendWriting(lines, summary);
  appendScores(lines, summary);
  appendList(lines, '## Closed without merging', summary.closedUnmergedContributions.map(
    (item) => `\`${item.id}\`: ${item.url} closed without merging; entry left unchanged.`,
  ));
  appendList(lines, '## Fetch failures', summary.failures);
  appendCandidates(lines, summary);
  return `${lines.join('\n').trimEnd()}\n`;
}
