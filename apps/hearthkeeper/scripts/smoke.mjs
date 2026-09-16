// End-to-end smoke test against the built app.
//
// The unit tests cover the rules; this covers the thing the rules exist for — that a tester can
// open the page, log a finding, and still have it after a reload with the network switched off.
// Run: npm run build && npm run smoke  (needs `npm i -D playwright`; the browser must be present)

import fs from 'node:fs';
import http from 'node:http';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { chromium } from 'playwright';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../dist');
const PORT = Number(process.env.SMOKE_PORT ?? 4173);
const TYPES = {
  '.html': 'text/html',
  '.js': 'text/javascript',
  '.css': 'text/css',
  '.svg': 'image/svg+xml',
  '.webmanifest': 'application/manifest+json',
};

const failures = [];
function check(label, condition, detail = '') {
  if (condition) console.log(`  ok   ${label}`);
  else {
    console.log(`  FAIL ${label} ${detail}`);
    failures.push(label);
  }
}

if (!fs.existsSync(root)) {
  console.error('No dist/ — run `npm run build` first.');
  process.exit(1);
}

const server = http.createServer((request, response) => {
  const url = request.url.split('?')[0];
  const file = path.join(root, url === '/' ? 'index.html' : url);
  if (!file.startsWith(root) || !fs.existsSync(file) || fs.statSync(file).isDirectory()) {
    response.writeHead(404);
    return response.end('not found');
  }
  response.writeHead(200, { 'content-type': TYPES[path.extname(file)] ?? 'application/octet-stream' });
  response.end(fs.readFileSync(file));
});
await new Promise((resolve) => server.listen(PORT, resolve));

const browser = await chromium.launch({
  executablePath: process.env.CHROMIUM_PATH || undefined,
  args: ['--no-sandbox'],
});

try {
  console.log('journal flow (phone viewport)');
  const page = await browser.newPage({ viewport: { width: 420, height: 900 } });
  const errors = [];
  page.on('console', (message) => message.type() === 'error' && errors.push(message.text()));
  page.on('pageerror', (error) => errors.push(String(error)));

  await page.goto(`http://localhost:${PORT}/`, { waitUntil: 'networkidle' });
  check('page loads', (await page.title()).includes('Hearthkeeper'));

  await page.getByRole('button', { name: 'Journal' }).click();
  await page.getByPlaceholder('Quest giver missing after phase change').fill('Skyborne glider drops on zone edge');
  await page.locator('.field:has-text("Severity") select').selectOption('blocker');
  await page.locator('.field:has-text("Where") select').selectOption('zephras-isle');
  await page.getByRole('button', { name: 'Log it' }).click();
  check('finding is logged', (await page.locator('.finding').count()) === 1);

  const report = await page.locator('.preview').textContent();
  check('export carries the build stamp', report.includes('build beta-phase-1'), report.slice(0, 80));
  check('export groups by severity', report.includes('## Blocker (1)'));

  await page.getByPlaceholder('Quest giver missing after phase change').fill('skyborne glider drops on zone edge!');
  await page.locator('.field:has-text("Where") select').selectOption('zephras-isle');
  check('near-duplicate is caught', (await page.locator('.note--warn').count()) > 0);

  console.log('roster validation');
  await page.getByRole('button', { name: 'Roster' }).click();
  const form = page.locator('form').first();
  await form.locator('.field').nth(0).locator('input').fill('Sarkoth');
  await form.locator('.field').nth(1).locator('select').selectOption('undead');
  await form.locator('.field').nth(2).locator('select').selectOption('Paladin');
  check('new combination is flagged', (await page.locator('.note--good').count()) === 1);
  await page.getByRole('button', { name: 'Add', exact: true }).click();
  check('character is added', (await page.locator('.character').count()) === 1);

  console.log('persistence and offline');
  await page.reload({ waitUntil: 'networkidle' });
  await page.getByRole('button', { name: 'Journal' }).click();
  check('findings survive a reload', (await page.locator('.finding').count()) === 1);

  const registered = await page.evaluate(() => navigator.serviceWorker.getRegistration().then(Boolean));
  check('service worker registers', registered);
  await page.context().setOffline(true);
  await page.reload({ waitUntil: 'load' });
  check('app still loads with the network off', (await page.locator('h1').textContent()) === 'Hearthkeeper');
  check('data still there offline', (await page.locator('.tab__count').textContent()) === '1');
  await page.context().setOffline(false);
  check('no console errors', errors.length === 0, errors.join(' | '));
  await page.close();

  console.log('phase clock');
  for (const [label, when, cap, reachable] of [
    ['phase 1', '2026-09-20T12:00:00Z', '20', '0 of 1'],
    ['phase 2', '2026-10-06T12:00:00Z', '30', '0 of 2'],
  ]) {
    const clocked = await browser.newPage({ viewport: { width: 900, height: 1200 } });
    await clocked.clock.install({ time: new Date(when) });
    await clocked.goto(`http://localhost:${PORT}/`, { waitUntil: 'networkidle' });
    check(`${label} shows cap ${cap}`, (await clocked.locator('.hero__number').textContent()).trim() === cap);
    await clocked.getByRole('button', { name: 'Coverage' }).click();
    const line = await clocked.locator('.card .muted').first().textContent();
    check(`${label} counts only reachable content (${reachable})`, line.startsWith(reachable));
    await clocked.close();
  }
} finally {
  await browser.close();
  server.close();
}

console.log(failures.length ? `\n${failures.length} check(s) failed` : '\nall checks passed');
process.exit(failures.length ? 1 : 0);
