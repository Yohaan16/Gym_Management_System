/*
 * Simple smoke tester for POST /api/attendance/scan
 * Usage: node scripts/smoke-test-attendance.js <memberId>
 * - Requires the backend to be running locally (DEFAULT: http://localhost:3000)
 * - This script uses the local QRService to generate a valid token and POSTs it twice
 */

// Prefer the global fetch (Node 18+); fall back to node-fetch (v2/v3) when available.
let fetchFn = globalThis.fetch;
try {
  if (!fetchFn) {
    const nf = require('node-fetch');
    fetchFn = (nf && nf.default) ? nf.default : nf;
  }
} catch (e) {
  /* ignore - fetch may not be available */
}

if (!fetchFn) throw new Error('fetch is not available in this environment; install node-fetch or run on Node 18+');

const fetch = fetchFn;
const QRService = require('../services/QRService');

const BACKEND = process.env.BACKEND_URL || 'http://localhost:3000';
const memberId = process.argv[2] || 1;

async function run() {
  try {
    const { token } = await QRService.generateToken(memberId, 30);
    console.log('Generated token (short-lived) for member', memberId, '->', token);

    if (!/^[0-9a-f]{18,40}$/.test(token)) console.warn('Warning: token does not look like short-id; length:', token.length);

    const res1 = await fetch(`${BACKEND}/api/attendance/scan`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      // scanner clients should POST { qr: '<short-id>' } — support both shapes on server
      body: JSON.stringify({ qr: token }),
    });
    console.log('\nFirst scan status:', res1.status);
    console.log('Body:', await res1.json().catch(() => '<non-json>'));

    const res2 = await fetch(`${BACKEND}/api/attendance/scan`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ token }),
    });
    console.log('\nSecond scan status:', res2.status);
    console.log('Body:', await res2.json().catch(() => '<non-json>'));

    // --- call recent attendance endpoint to reproduce prior LIMIT issue ---
    const recent = await fetch(`${BACKEND}/api/attendance/recent?limit=10`);
    console.log('\nGET /api/attendance/recent?limit=10 ->', recent.status);
    console.log('Recent body sample:', await recent.json().catch(() => '<non-json>'));

  } catch (err) {
    console.error('smoke test failed', err);
    process.exitCode = 1;
  }
}

run();
