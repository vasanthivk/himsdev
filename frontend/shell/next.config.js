// The shell is the single public entry point (port 3000). It owns no pages of the workflow; it forwards each path prefix to the
// zone (a separate Next.js app) that owns it - Next.js "multi-zones". Rewrites are read at BUILD time.
const zones = {
  '/patient-access': process.env.PATIENT_ACCESS_ZONE_URL || 'http://localhost:3001',
  '/clinical-care': process.env.CLINICAL_CARE_ZONE_URL || 'http://localhost:3002',
  '/laboratory': process.env.LABORATORY_ZONE_URL || 'http://localhost:3003',
  '/revenue-cycle': process.env.REVENUE_CYCLE_ZONE_URL || 'http://localhost:3006',
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
