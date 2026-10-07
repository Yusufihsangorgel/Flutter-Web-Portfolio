/**
 * Reconstructs a template literal from its static parts and evaluated values.
 * Keeping large markup and style blocks at module scope keeps renderer members small.
 *
 * @param {readonly string[]} parts
 * @param {readonly unknown[]} values
 */
export function fillTemplate(parts, values) {
  let rendered = parts[0];
  for (let index = 0; index < values.length; index += 1) {
    rendered += String(values[index]) + parts[index + 1];
  }
  return rendered;
}
