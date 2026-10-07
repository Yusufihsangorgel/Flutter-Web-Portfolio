const markers = [
  'portfolio-ci',
  'portfolio-template',
  'portfolio-demo',
  'portfolio-onboarding',
  'portfolio-record-intro',
  'portfolio-record',
];

export function renderStarterReadme({ name, site, repository }) {
  const blocks = markers
    .map((marker) => `<!-- ${marker}:start -->\n\n<!-- ${marker}:end -->`)
    .join('\n\n');
  return `# ${name}\n\n${name}'s portfolio is available at [${site}](${site}). The [source repository](https://github.com/${repository}) contains the template and site.\n\n${blocks}\n\n## Customize\n\nSee [the customization guide](docs/CUSTOMIZE.md) to make this portfolio your own.\n`;
}
