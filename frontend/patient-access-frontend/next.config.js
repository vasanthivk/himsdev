// Patient Access zone: served by the shell under /patient-access. basePath makes Next.js prefix routes and assets with it.
module.exports = {
  basePath: '/patient-access',
  eslint: { ignoreDuringBuilds: true },
  // Not a NEXT_PUBLIC_ name, so it is passed to the browser code explicitly (read by lib/api.ts).
  env: { WSO2_AUTHENTICATION: process.env.WSO2_AUTHENTICATION ?? '' },
};

// `node next.config.js <dev|start>` runs Next on PATIENT_ACCESS_PORT from .env. Next reads the port before it loads this config,
// and npm scripts don't load .env, so the port is resolved here. When Next loads this file as its config, this block is skipped.
if (require.main === module) {
  const { spawn } = require('child_process');
  const { loadEnvConfig } = require('@next/env');

  const command = process.argv[2];
  loadEnvConfig(__dirname, command === 'dev');

  const child = spawn('next', [command, '-p', process.env.PATIENT_ACCESS_PORT], { stdio: 'inherit', shell: true });
  child.on('exit', (code) => process.exit(code ?? 0));
}
