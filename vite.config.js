import { defineConfig } from 'vite'
// import react from '@vitejs/plugin-react';

export default defineConfig(({ command, mode }) => {
  return {
    test: {
      // globals: true,
      // requires node >= 16
      environment: "jsdom",
      // Error: Module did not self-register when using Canvas + jsdom
      // https://github.com/vitest-dev/vitest/issues/740
      threads: false,
      include: ['**/*_test.bs.js'],
    },
  }
})
