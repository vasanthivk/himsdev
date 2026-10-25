// The shell is the single public entry point (port 3000). It owns no pages of the workflow; it forwards each path prefix to the
// zone (a separate Next.js app) that owns it - Next.js "multi-zones". Rewrites are read at BUILD time.
const zones = {
  '/patient-engagement': process.env.PATIENT_ENGAGEMENT_ZONE_URL,
  '/clinical-care': process.env.CLINICAL_CARE_ZONE_URL,
  '/diagnostics': process.env.DIAGNOSTICS_ZONE_URL,
  '/revenue-finance': process.env.REVENUE_FINANCE_ZONE_URL,
};

module.exports = {
  eslint: { ignoreDuringBuilds: true },
  // Not a NEXT_PUBLIC_ name, so it is passed to the browser code explicitly (read by lib/api.ts).
  env: { WSO2_AUTHENTICATION: process.env.WSO2_AUTHENTICATION ?? '' },
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

  // SHELL_HTTPS=true serves `dev` on https with a self-signed localhost certificate - the WSO2 IS redirect URL is https.
  const args = [command, '-p', process.env.SHELL_PORT];
  if (command === 'dev' && process.env.SHELL_HTTPS === 'true') args.push('--experimental-https');

  const child = spawn('next', args, { stdio: 'inherit', shell: true });
  child.on('exit', (code) => process.exit(code ?? 0));
}
