// The shell is the single public entry point (port 3000). It owns no pages of the workflow; it forwards each path prefix to the
// zone (a separate Next.js app) that owns it - Next.js "multi-zones". Rewrites are read at BUILD time.
const zones = {
  '/patient-access': process.env.PATIENT_ACCESS_ZONE_URL,
  '/clinical-care': process.env.CLINICAL_CARE_ZONE_URL,
  '/laboratory': process.env.LABORATORY_ZONE_URL,
  '/revenue-cycle': process.env.REVENUE_CYCLE_ZONE_URL,
};

module.exports = {
  eslint: { ignoreDuringBuilds: true },
  async rewrites() {
    return Object.entries(zones).flatMap(([prefix, url]) => [
      { source: prefix, destination: `${url}${prefix}` },
      { source: `${prefix}/:path*`, destination: `${url}${prefix}/:path*` },
    ]);
  },
};

// `node next.config.js <dev|start>` runs Next on SHELL_PORT from .env. Next reads the port before it loads this config,
// and npm scripts don't load .env, so the port is resolved here. When Next loads this file as its config, this block is skipped.
if (require.main === module) {
  const { spawn } = require('child_process');
  const { loadEnvConfig } = require('@next/env');

  const command = process.argv[2];
  loadEnvConfig(__dirname, command === 'dev');

  const child = spawn('next', [command, '-p', process.env.SHELL_PORT], { stdio: 'inherit', shell: true });
  child.on('exit', (code) => process.exit(code ?? 0));
}
