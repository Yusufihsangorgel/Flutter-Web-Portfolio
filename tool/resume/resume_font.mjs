// @ts-check
import { readFile } from 'node:fs/promises';

/**
 * @returns {Promise<string>}
 */
export async function loadResumeFont() {
  return (
    await readFile(new URL('../../assets/fonts/inter/Inter-Variable.ttf', import.meta.url))
  ).toString('base64');
}
