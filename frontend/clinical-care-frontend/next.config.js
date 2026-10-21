// Clinical Care zone: served by the shell under /clinical-care.
module.exports = {
  basePath: '/clinical-care',
  eslint: { ignoreDuringBuilds: true },
};

// `node next.config.js <dev|start>` runs Next on CLINICAL_CARE_PORT from .env. Next reads the port before it loads this config,
// and npm scripts don't load .env, so the port is resolved here. When Next loads this file as its config, this block is skipped.
if (require.main === module) {
  const { spawn } = require('child_process');
  const { loadEnvConfig } = require('@next/env');

  const command = process.argv[2];
  loadEnvConfig(__dirname, command === 'dev');

  const child = spawn('next', [command, '-p', process.env.CLINICAL_CARE_PORT], { stdio: 'inherit', shell: true });
  child.on('exit', (code) => process.exit(code ?? 0));
}
