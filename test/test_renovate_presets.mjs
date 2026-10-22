// Checks the presets in renovate/ as other repos will get them, using Renovate's own code.
// renovate-config-validator reads each file alone, so it misses broken references between
// presets, typos in enum values, and what a preset does once its extends are merged.
//
// Usage: RENOVATE_DIR=<dir with node_modules/renovate> node test/test_renovate_presets.mjs

// Renovate falls back to the machine's zone when a schedule has none; pin it so a missing
// timezone fails here as it would in CI, not only on a UTC machine.
process.env.TZ = 'UTC';

import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

if (!process.env.RENOVATE_DIR) {
  console.error('Usage: RENOVATE_DIR=<dir with node_modules/renovate> node test/test_renovate_presets.mjs');
  process.exit(2);
}
const modules = path.resolve(process.env.RENOVATE_DIR, 'node_modules');
const load = async (file) => import(pathToFileURL(path.join(modules, file)).href);
process.chdir(fileURLToPath(new URL('..', import.meta.url)));

const { getOptions } = await load('renovate/dist/config/options/index.js');
const { mergeChildConfig } = await load('renovate/dist/config/utils.js');
const { parsePreset } = await load('renovate/dist/config/presets/parse.js');
const { replaceArgs, resolveConfigPresets } = await load('renovate/dist/config/presets/index.js');
const { applyPackageRules } = await load('renovate/dist/util/package-rules/index.js');
const { isScheduledNow } = await load('renovate/dist/workers/repository/update/branch/schedule.js');
const { matchRegexOrGlobList } = await load('renovate/dist/util/string-match.js');
const { DateTime, Settings } = await load('luxon/build/es6/luxon.mjs');

const PREFIX = 'github>andrelin/dotfiles//renovate/';
const presets = fs.readdirSync('renovate').filter((f) => f.endsWith('.json')).map((f) => f.slice(0, -5)).sort();
const read = (file) => JSON.parse(fs.readFileSync(file, 'utf8'));
const failures = [];
const check = async (name, fn) => {
  try {
    await fn();
  } catch (e) {
    failures.push(`${name}: ${e.message}`);
  }
};

// Every reference to these presets, in config and in the docs people copy from,
// is in the one form Renovate resolves and names a preset that exists.
const tracked = execFileSync('git', ['ls-files', '*.md', '*.json'], { encoding: 'utf8' }).split('\n').filter(Boolean);
for (const file of tracked) {
  for (const [ref] of fs.readFileSync(file, 'utf8').matchAll(/github>andrelin\/dotfiles[^\s"`)]*/gi)) {
    await check(`${file} ${ref}`, () => {
      assert.ok(ref.startsWith(PREFIX), `not in the ${PREFIX}<name> form`);
      assert.ok(presets.includes(ref.slice(PREFIX.length).replace(/\(.*$/, '')), 'no such preset');
    });
  }
}

// The README table lists exactly the presets that exist.
await check('README table', () => {
  const listed = [...fs.readFileSync('renovate/README.md', 'utf8').matchAll(/^\| (`.+?) \|/gm)]
    .flatMap(([, cell]) => [...cell.matchAll(/`([a-z-]+)/g)].map(([, n]) => n));
  assert.deepEqual([...listed].sort(), presets);
});

// Enum-valued options hold allowed values; the validator lets e.g. matchUpdateTypes: ["mayor"] through.
const options = new Map(getOptions().map((o) => [o.name, o]));
const checkEnums = async (where, obj) => {
  if (Array.isArray(obj)) return Promise.all(obj.map((v, i) => checkEnums(`${where}[${i}]`, v)));
  if (obj === null || typeof obj !== 'object') return;
  for (const [key, value] of Object.entries(obj)) {
    const allowed = options.get(key)?.allowedValues;
    if (allowed) {
      for (const v of [value].flat()) {
        await check(`${where}.${key}`, () => assert.ok(allowed.includes(v), `${v} is not one of ${allowed.join(', ')}`));
      }
    }
    await checkEnums(`${where}.${key}`, value);
  }
};
for (const p of presets) await checkEnums(p, read(`renovate/${p}.json`));
await checkEnums('.github/renovate.json', read('.github/renovate.json'));

// Resolve a config the way Renovate does: each extended preset in order, then the config itself.
// This repo's presets are read from the working tree; built-in ones go through Renovate's resolver.
const resolve = async (config) => {
  let merged = {};
  for (const ref of config.extends ?? []) {
    let preset;
    if (ref.startsWith(PREFIX)) {
      const { presetPath, presetName, params } = parsePreset(ref);
      assert.equal(presetPath, 'renovate', `${ref} is outside renovate/`);
      const raw = read(`renovate/${presetName}.json`);
      preset = await resolve(params ? replaceArgs(raw, Object.fromEntries(params.map((v, i) => [`arg${i}`, v]))) : raw);
    } else {
      ({ config: preset } = await resolveConfigPresets({ extends: [ref] }));
    }
    merged = mergeChildConfig(merged, preset);
  }
  const { extends: _, description: __, ...own } = config;
  return mergeChildConfig(merged, own);
};
const resolved = (p) => resolve({ extends: [`${PREFIX}${p}`] });
// Renovate's default for an option the resolved config leaves unset.
const value = (config, name) => config[name] ?? options.get(name).default;

// What a resolved config does with one update, through Renovate's own packageRule matching.
const update = (config, { updateType, datasource = 'npm', packageName = 'example', manager = 'npm', depType }) =>
  applyPackageRules({ ...config, updateType, datasource, packageName, depName: packageName, manager, depType });

// Whether a config's schedule (or automergeSchedule) is open at an Oslo wall-clock time,
// by Renovate's own schedule check.
const openAt = (config, isoOsloTime, key = 'schedule') => {
  const millis = DateTime.fromISO(isoOsloTime, { zone: 'Europe/Oslo' }).toMillis();
  Settings.now = () => millis;
  try {
    return isScheduledNow(config, key);
  } finally {
    Settings.now = () => Date.now();
  }
};
// 2026-11-02 is a Monday. 00:30 Monday in Oslo is still Sunday in UTC, so a schedule that lost
// its timezone fails there.
const T = {
  monStart: '2026-11-02T00:30', monLate: '2026-11-02T12:30', monAfter: '2026-11-02T13:30',
  tue: '2026-11-03T10:00', wed: '2026-11-04T10:00', fri: '2026-11-06T10:00', sat: '2026-11-07T10:00', sun: '2026-11-08T10:00',
};

// The faked clock only works if it reaches the luxon copy Renovate's schedule code uses.
const probe = { schedule: ['* 0-12 * * 1'], timezone: 'Europe/Oslo' };
if (!(openAt(probe, T.monLate) && !openAt(probe, T.sat))) {
  console.log('::error::the faked clock does not reach Renovate\'s schedule check; the window checks would read the real clock');
  process.exit(1);
}

const policies = { 'automerge-non-major': [true, false], 'automerge-all': [true, true], 'grouped-non-major': [false, false] };
for (const [policy, [minorMerges, majorMerges]] of Object.entries(policies)) {
  await check(policy, async () => {
    const config = await resolved(policy);
    assert.equal((await update(config, { updateType: 'minor' })).automerge ?? false, minorMerges, 'minor automerge');
    assert.equal((await update(config, { updateType: 'major', datasource: 'github-tags' })).automerge ?? false, majorMerges, 'major automerge');
    for (const u of [{ updateType: 'minor', datasource: 'docker' }, { updateType: 'major' }, { updateType: 'patch', datasource: 'pypi' }]) {
      assert.equal((await update(config, u)).minimumReleaseAge, '3 days', `hold on ${u.datasource ?? 'npm'} ${u.updateType}`);
    }
    assert.equal(value(config, 'minimumReleaseAgeBehaviour'), 'timestamp-optional', 'a release with no publish date would be held forever');
    assert.equal((await update(config, { updateType: 'pinDigest', datasource: 'github-tags', manager: 'github-actions', depType: 'action' })).pinDigests, true, 'action digests pinned');
    assert.equal(value(config, 'rangeStrategy'), 'bump', 'manifest bumps');
    // Non-major updates of every kind share one group; majors get their own PR.
    const groups = await Promise.all(['minor', 'patch', 'pin', 'pinDigest', 'digest'].map(async (t) => (await update(config, { updateType: t })).groupName));
    assert.ok(groups[0] && groups.every((g) => g === groups[0]), `non-major updates split across groups: ${groups}`);
    assert.equal(value(config, 'separateMajorMinor'), true, 'majors must get their own PR');
    // Merging goes through a PR and isn't windowed; open PRs keep being rebased outside the window.
    assert.notEqual(value(config, 'automergeType'), 'branch', 'automerge onto the branch');
    assert.equal(openAt(config, T.sat, 'automergeSchedule'), true, 'merging is windowed');
    assert.equal(value(config, 'updateNotScheduled'), true, 'open PRs not rebased outside the window');
    assert.equal(openAt(config, T.sat), true, 'a policy alone has no schedule');
    // Security fixes are always raised, merged at any time without the hold, except where nothing merges.
    assert.equal(value(config, 'osvVulnerabilityAlerts'), true, 'OSV alerts');
    const alerts = config.vulnerabilityAlerts;
    assert.equal(alerts.enabled, true, 'security fixes raised');
    assert.equal(alerts.automerge, minorMerges, 'security fixes merge themselves');
    assert.equal(alerts.minimumReleaseAge, null, 'security fixes skip the hold');
    assert.equal(openAt(alerts, T.sat), true, 'security fixes ignore the schedule');
  });
}

const windows = {
  weekly: { monStart: true, monLate: true, monAfter: false, tue: false, wed: false, fri: false, sat: false, sun: false },
  daily: { monStart: true, monLate: true, monAfter: false, tue: true, wed: true, fri: true, sat: false, sun: false },
};
for (const [schedule, expected] of Object.entries(windows)) {
  for (const preset of [schedule, `${schedule}-automerge-all`]) {
    await check(`${preset} window`, async () => {
      const config = await resolved(preset);
      for (const [time, open] of Object.entries(expected)) assert.equal(openAt(config, T[time]), open, `open at ${T[time]}`);
    });
  }
  await check(`${schedule}-automerge-all`, async () => {
    assert.deepEqual(await resolved(`${schedule}-automerge-all`), mergeChildConfig(await resolved('automerge-all'), await resolved(schedule)));
  });
}

// renovate-comments: up to ten file patterns as arguments, `#` or `//` comments.
await check('renovate-comments', async () => {
  const { customManagers: [manager] } = await resolve({ extends: [`${PREFIX}renovate-comments(\\.ya?ml$,\\.toml$)`] });
  const selected = ['a.yml', 'b.toml', 'c.json'].filter((f) => matchRegexOrGlobList(f, manager.managerFilePatterns));
  assert.deepEqual(selected, ['a.yml', 'b.toml'], 'files selected by two arguments');
  for (const line of ['version: 1.2.3 # renovate: npm=left-pad', 'const v = "1.2.3"; // renovate: npm=left-pad']) {
    const m = new RegExp(manager.matchStrings[0]).exec(line);
    assert.deepEqual(m && [m.groups.currentValue, m.groups.datasource, m.groups.depName], ['1.2.3', 'npm', 'left-pad'], line);
  }
});

// This repo's own config: daily, majors merge, TypeScript held below 7, lockfiles refreshed,
// and the renovate bump in its own PR so a release that breaks this script holds back nothing else.
await check('.github/renovate.json', async () => {
  const config = await resolve(read('.github/renovate.json'));
  assert.equal(openAt(config, T.tue), true, 'daily');
  assert.equal((await update(config, { updateType: 'major' })).automerge, true, 'majors merge');
  assert.equal((await update(config, { updateType: 'major', packageName: 'typescript' })).allowedVersions, '<7', 'TypeScript hold');
  assert.deepEqual([config.lockFileMaintenance.enabled, config.lockFileMaintenance.automerge], [true, true], 'lockfile maintenance');
  const renovate = await update(config, { updateType: 'minor', packageName: 'renovate' });
  assert.notEqual(renovate.groupName, (await update(config, { updateType: 'minor' })).groupName, 'renovate grouped with the rest');
});

// Renovate keeps bumping the validator pin in the workflow: the renovate-comments manager this repo's
// config sets up must select the workflow file and extract a version from it.
await check('validator pin', async () => {
  const workflow = '.github/workflows/renovate-presets.yml';
  const managers = (await resolve(read('.github/renovate.json'))).customManagers ?? [];
  const manager = managers.find((m) => matchRegexOrGlobList(workflow, m.managerFilePatterns));
  assert.ok(manager, `no custom manager selects ${workflow}`);
  const m = new RegExp(manager.matchStrings[0]).exec(fs.readFileSync(workflow, 'utf8'));
  assert.ok(m, 'no renovate comment matched');
  assert.deepEqual({ datasource: m.groups.datasource, depName: m.groups.depName }, { datasource: 'npm', depName: 'renovate' });
  assert.match(m.groups.currentValue, /^\d+\.\d+\.\d+$/, 'the pin is a version Renovate can bump');
});

for (const f of failures) console.log(`::error::${f}`);
console.log(failures.length ? `${failures.length} failure(s)` : 'All renovate preset checks passed');
process.exit(failures.length ? 1 : 0);
