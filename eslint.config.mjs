import js from '@eslint/js';
import globals from 'globals';

export default [
  { ignores: ['tool/resume/**'] },
  {
    files: ['tool/**/*.mjs'],
    ...js.configs.recommended,
    languageOptions: {
      ecmaVersion: 'latest',
      sourceType: 'module',
      globals: { ...globals.node, ...globals.browser },
    },
    rules: {
      ...js.configs.recommended.rules,
      'no-unused-vars': ['error', { argsIgnorePattern: '^_', caughtErrorsIgnorePattern: '^_' }],
      'max-lines': ['error', 500],
      'max-lines-per-function': ['error', 60],
      'max-params': ['error', 4],
      'max-depth': ['error', 4],
      complexity: ['error', 15],
    },
  },
];
