import { readFile } from 'node:fs/promises';

export async function loadResumeFont() {
  return (await readFile(new URL('../../assets/fonts/inter/Inter-Variable.ttf', import.meta.url))).toString('base64');
}
