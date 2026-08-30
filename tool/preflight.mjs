#!/usr/bin/env node
/**
 * Preflight check for running Job Sensei on a phone from Android Studio.
 *
 *   node tool/preflight.mjs
 *
 * Checks every part of the chain that differs between machines — Node, Flutter,
 * the .env, DNS, the database, the port, the phone — and says which one is
 * broken rather than leaving you to guess from a connection error.
 *
 * Written with no dependencies of its own so it runs on a fresh clone before
 * anything is installed.
 */

import { execFile } from 'node:child_process';
import { existsSync, readFileSync } from 'node:fs';
import net from 'node:net';
import dns from 'node:dns/promises';
import path from 'node:path';
import { promisify } from 'node:util';
import { createRequire } from 'node:module';

const run = promisify(execFile);
const ROOT = path.resolve(import.meta.dirname, '..');

let failures = 0;
let warnings = 0;

const pass = (label, detail = '') =>
  console.log(`  PASS  ${label}${detail ? ` — ${detail}` : ''}`);
const warn = (label, detail) => {
  warnings++;
  console.log(`  WARN  ${label}${detail ? ` — ${detail}` : ''}`);
};
const fail = (label, detail) => {
  failures++;
  console.log(`  FAIL  ${label}${detail ? ` — ${detail}` : ''}`);
};
const section = (title) => console.log(`\n${title}`);

/** Runs a command, returning its stdout, or null when it is not installed. */
async function tryRun(cmd, args) {
  try {
    // flutter and adb are .bat shims on Windows and execFile cannot launch a
    // .bat directly, so there the call goes through the shell. Node deprecates
    // passing an args array alongside shell:true, hence the single string.
    const viaShell = process.platform === 'win32';
    // Quote only when the path needs it — cmd.exe mishandles a quoted bare word.
    const quoted = cmd.includes(' ') ? '"' + cmd + '"' : cmd;
    const command = [quoted, ...args].join(' ');
    const { stdout } = viaShell
      ? await run(command, { timeout: 60000, shell: true })
      : await run(cmd, args, { timeout: 60000 });
    return stdout;
  } catch (error) {
    // A command that exists but exits non-zero still gives us its output.
    if (error.stdout) return error.stdout;
    return null;
  }
}

/* ------------------------------------------------------------- toolchain --- */

function checkNode() {
  section('Toolchain');
  const major = Number(process.versions.node.split('.')[0]);
  if (major >= 18) {
    pass('Node.js', `v${process.versions.node}`);
  } else {
    fail(
      'Node.js',
      `v${process.versions.node} is too old. The backend uses global fetch, which needs Node 18+.`,
    );
  }
}

async function checkFlutter() {
  const out =
    (await tryRun('flutter', ['--version'])) ??
    (await tryRun('C:\\src\\flutter\\bin\\flutter.bat', ['--version']));

  if (!out) {
    fail(
      'Flutter',
      'not found on PATH. Install it, then fully quit and reopen Android Studio.',
    );
    return;
  }

  const version = out.match(/Flutter (\d+\.\d+\.\d+)/)?.[1];
  if (!version) {
    warn('Flutter', 'installed, but the version could not be read.');
    return;
  }

  const [major, minor] = version.split('.').map(Number);
  // The project was built and verified on 3.47. Older 3.x usually works, but
  // the newer packages in pubspec are the likely first thing to break.
  if (major > 3 || (major === 3 && minor >= 27)) {
    pass('Flutter', version);
  } else {
    warn(
      'Flutter',
      `${version} is older than the 3.47 this was built on. If pub get fails, upgrade.`,
    );
  }
}

async function checkAdb() {
  const local = process.env.LOCALAPPDATA
    ? path.join(process.env.LOCALAPPDATA, 'Android', 'Sdk', 'platform-tools', 'adb.exe')
    : null;

  const adb = (await tryRun('adb', ['version']))
    ? 'adb'
    : local && existsSync(local)
      ? local
      : null;

  if (!adb) {
    warn(
      'adb',
      'not found. It ships with Android Studio, in platform-tools. Needed for adb reverse.',
    );
    return null;
  }
  pass('adb', adb === 'adb' ? 'on PATH' : adb);
  return adb;
}

/* -------------------------------------------------------------- the .env --- */

function readEnv() {
  section('Backend configuration');
  const file = path.join(ROOT, 'backend', '.env');

  if (!existsSync(file)) {
    fail(
      'backend/.env',
      'missing. It is gitignored, so it never arrives with a clone — create it yourself.',
    );
    return null;
  }

  const env = {};
  for (const line of readFileSync(file, 'utf8').split(/\r?\n/)) {
    const match = line.match(/^\s*([A-Z_]+)\s*=\s*(.*)$/);
    if (match) env[match[1]] = match[2].trim();
  }
  pass('backend/.env', 'found');

  if (env.PORT === '1190') {
    pass('PORT', '1190');
  } else if (env.PORT) {
    warn('PORT', `${env.PORT} — the assignment expects 1190.`);
  } else {
    warn('PORT', 'not set, so the server will default to 5000, not 1190.');
  }

  if (!env.JWT_SECRET) {
    fail('JWT_SECRET', 'not set. Sign-in will fail.');
  } else {
    pass('JWT_SECRET', 'set');
  }

  if (!env.MONGODB_URI) {
    fail('MONGODB_URI', 'not set.');
    return env;
  }
  if (env.MONGODB_URI.includes('<') || env.MONGODB_URI.includes('>')) {
    fail(
      'MONGODB_URI',
      'still contains angle brackets — the placeholder was not fully replaced.',
    );
    return env;
  }
  if (!/^mongodb(\+srv)?:\/\//.test(env.MONGODB_URI)) {
    fail('MONGODB_URI', 'must start with mongodb:// or mongodb+srv://');
    return env;
  }
  pass('MONGODB_URI', env.MONGODB_URI.startsWith('mongodb+srv://') ? 'SRV form' : 'direct host form');

  // The database name is whatever sits between the last "/" of the host list
  // and the query string. Both URI forms put it in the same place.
  const afterHosts = env.MONGODB_URI.split('@').pop().split('?')[0];
  const dbName = afterHosts.includes('/') ? afterHosts.split('/').pop() : '';
  if (dbName) {
    pass('database name', dbName);
  } else {
    warn(
      'MONGODB_URI',
      'no database name before the "?" — Mongo will use "test" rather than jobsensei.',
    );
  }

  return env;
}

/* ------------------------------------------------------------------- dns --- */

/**
 * `mongodb+srv://` needs an SRV lookup, which some networks and local DNS
 * proxies refuse. This is the failure that looks like a credentials problem but
 * is not, so it is worth naming precisely.
 */
async function checkSrv(uri) {
  if (!uri || !uri.startsWith('mongodb+srv://')) return;

  section('DNS');
  const host = uri.replace('mongodb+srv://', '').split('@').pop().split('/')[0];
  const record = `_mongodb._tcp.${host}`;

  try {
    const records = await dns.resolveSrv(record);
    pass('SRV lookup', `${records.length} hosts for ${host}`);
  } catch (error) {
    fail(
      'SRV lookup',
      `${error.code} for ${host}. Your DNS will not resolve SRV records, so ` +
        'mongodb+srv:// cannot connect.',
    );
    console.log(
      '        Fix either way:\n' +
        '          - set your DNS to 1.1.1.1, or\n' +
        '          - use the direct-host mongodb:// form of the connection string',
    );
  }
}

/* -------------------------------------------------------------- database --- */

async function checkDatabase(uri) {
  if (!uri) return;
  section('Database');

  const mongoosePath = path.join(ROOT, 'backend', 'node_modules', 'mongoose');
  if (!existsSync(mongoosePath)) {
    warn(
      'backend dependencies',
      'not installed, so the connection was not tested. Run npm install in backend/.',
    );
    return;
  }
  pass('backend dependencies', 'installed');

  try {
    // Resolved from backend/, where mongoose is actually installed — a bare
    // import here would look next to this script and fail.
    const backendRequire = createRequire(
      path.join(ROOT, 'backend', 'package.json'),
    );
    const mongoose = backendRequire('mongoose');
    await mongoose.connect(uri, { serverSelectionTimeoutMS: 15000 });
    const { databases } = await mongoose.connection.db.admin().listDatabases();
    pass('MongoDB connection', `connected to "${mongoose.connection.name}"`);

    const jobs = await mongoose.connection.db.collection('jobs').countDocuments();
    const profiles = await mongoose.connection.db
      .collection('careerprofiles')
      .countDocuments();

    if (jobs === 0) {
      warn('jobs collection', 'empty. Run npm run seed, then npm run import:jobs.');
    } else {
      pass('jobs collection', `${jobs} jobs`);
    }
    pass('career profiles', `${profiles} stored`);

    void databases;
    await mongoose.disconnect();
  } catch (error) {
    fail('MongoDB connection', error.message.split('\n')[0]);
  }
}

/* ------------------------------------------------------------------ port --- */

function portState(port) {
  return new Promise((resolve) => {
    const socket = net.createConnection({ host: '127.0.0.1', port });
    const done = (state) => {
      socket.destroy();
      resolve(state);
    };
    socket.setTimeout(2000);
    socket.on('connect', () => done('in-use'));
    socket.on('timeout', () => done('free'));
    socket.on('error', () => done('free'));
  });
}

async function checkServer(port) {
  section(`API on port ${port}`);
  const state = await portState(port);

  if (state === 'free') {
    warn('server', `nothing listening on ${port}. Start it with npm start in backend/.`);
    return false;
  }

  try {
    const res = await fetch(`http://127.0.0.1:${port}/api/health`);
    if (res.ok) {
      pass('server', 'responding on /api/health');
      return true;
    }
    fail('server', `something is on ${port} but /api/health returned ${res.status}.`);
  } catch (error) {
    fail('server', `port ${port} is busy but not with this API (${error.message}).`);
  }
  return false;
}

/* ----------------------------------------------------------------- phone --- */

async function checkPhone(adb, port) {
  if (!adb) return;
  section('Phone');

  const devices = await tryRun(adb, ['devices']);
  const lines = (devices ?? '')
    .split(/\r?\n/)
    .slice(1)
    .filter((l) => l.trim() && !l.startsWith('*'));

  const ready = lines.filter((l) => l.includes('\tdevice'));
  const unauthorised = lines.filter((l) => l.includes('unauthorized'));

  if (unauthorised.length) {
    fail(
      'device',
      'connected but unauthorised. Accept the "Allow USB debugging?" prompt on the handset.',
    );
  } else if (ready.length === 0) {
    warn(
      'device',
      'none connected. Plug the phone in with USB debugging on, and use a data cable.',
    );
  } else {
    pass('device', `${ready.length} connected`);
  }

  const reverse = await tryRun(adb, ['reverse', '--list']);
  if ((reverse ?? '').includes(`tcp:${port}`)) {
    pass('adb reverse', `tcp:${port} mapped`);
  } else if (ready.length) {
    fail(
      'adb reverse',
      `not mapped. Run: adb reverse tcp:${port} tcp:${port}  (it is lost on every replug)`,
    );
  }
}

/* ------------------------------------------------------------------ main --- */

console.log('Job Sensei preflight\n====================');

checkNode();
await checkFlutter();
const adb = await checkAdb();

const env = readEnv();
const port = Number(env?.PORT) || 1190;

await checkSrv(env?.MONGODB_URI);
await checkDatabase(env?.MONGODB_URI);
await checkServer(port);
await checkPhone(adb, port);

section('Summary');
if (failures === 0 && warnings === 0) {
  console.log('  Everything checks out. Run:');
  console.log(
    `    flutter run --dart-define=API_BASE_URL=http://127.0.0.1:${port}/api`,
  );
} else {
  console.log(`  ${failures} failure(s), ${warnings} warning(s).`);
  console.log('  Failures will stop the app working. Warnings usually just mean');
  console.log('  something is not started yet.');
}
console.log('');

process.exitCode = failures > 0 ? 1 : 0;
