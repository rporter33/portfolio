import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  // Relative base so a build works under a subpath (GitHub Pages, Cloudflare Pages, a folder
  // on a NAS) with no config change.
  base: './',
  test: {
    environment: 'node',
    include: ['src/**/*.test.js'],
  },
});
