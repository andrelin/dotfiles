// Checks the presets in renovate/ as other repos will get them, using Renovate's own code.
// renovate-config-validator reads each file alone, so it misses broken references between
// presets, typos in enum values, and what a preset does once its extends are merged.
//
// Usage: RENOVATE_DIR=<dir with node_modules/renovate> node test/renovate_presets.mjs

import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';

if (!process.env.RENOVATE_DIR) {
  console.error('Usage: RENOVATE_DIR=<dir with node_modules/renovate> node test/renovate_presets.mjs');
  process.exit(2);
}
process.chdir(new URL('..', import.meta.url).pathname);

const modules = `${process.env.RENOVATE_DIR}/node_modules`;
const { getOptions } = await import(`${modules}/renovate/dist/config/options/index.js`);
const { mergeChildConfig } = await import(`${modules}/renovate/dist/config/utils.js`);
const { parsePreset } = await import(`${modules}/renovate/dist/config/presets/parse.js`);
const { replaceArgs } = await import(`${modules}/renovate/dist/config/presets/index.js`);
const { applyPackageRules } = await import(`${modules}/renovate/dist/util/package-rules/index.js`);
const { isScheduledNow } = await import(`${modules}/renovate/dist/workers/repository/update/branch/schedule.js`);
const { matchRegexOrGlobList } = await import(`${modules}/renovate/dist/util/string-match.js`);
// The same luxon instance Renovate's schedule code reads the clock from.
const { DateTime, Settings } = await import(`${modules}/luxon/build/es6/luxon.mjs`);

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
const allowed = new Map(getOptions().filter((o) => o.allowedValues).map((o) => [o.name, o.allowedValues]));
const checkEnums = async (where, obj) => {
  if (Array.isArray(obj)) return Promise.all(obj.map((v, i) => checkEnums(`${where}[${i}]`, v)));
  if (obj === null || typeof obj !== 'object') return;
  for (const [key, value] of Object.entries(obj)) {
    if (allowed.has(key)) {
      for (const v of [value].flat()) {
        await check(`${where}.${key}`, () => assert.ok(allowed.get(key).includes(v), `${v} is not one of ${allowed.get(key).join(', ')}`));
      }
    }
    await checkEnums(`${where}.${key}`, value);
  }
};
for (const p of presets) await checkEnums(p, read(`renovate/${p}.json`));
await checkEnums('.github/renovate.json', read('.github/renovate.json'));

// Resolve a config the way Renovate does: each extended preset in order, then the config itself.
// Built-in presets (config:recommended and so on) aren't this repo's to test and are skipped.
const resolve = (config) => {
  let merged = {};
  for (const ref of config.extends ?? []) {
    if (!ref.startsWith(PREFIX)) continue;
    const { presetName, params } = parsePreset(ref);
    const preset = read(`renovate/${presetName.replace(/^renovate\//, '')}.json`);
    merged = mergeChildConfig(merged, resolve(params ? replaceArgs(preset, Object.fromEntries(params.map((v, i) => [`arg${i}`, v]))) : preset));
  }
  const { extends: _, description: __, ...own } = config;
  return mergeChildConfig(merged, own);
};
const load = (p) => resolve({ extends: [`${PREFIX}${p}`] });

// What a resolved config does with one update, through Renovate's own packageRule matching.
const update = (config, { updateType, datasource = 'npm', packageName = 'example' }) =>
  applyPackageRules({ ...config, updateType, datasource, packageName, depName: packageName, manager: 'npm' });

// Whether a config's schedule is open at a given Oslo wall-clock time, by Renovate's own schedule check.
const openAt = (config, isoOsloTime) => {
  const millis = DateTime.fromISO(isoOsloTime, { zone: 'Europe/Oslo' }).toMillis();
  Settings.now = () => millis;
  try {
    return isScheduledNow(config);
  } finally {
    Settings.now = () => Date.now();
  }
};
// 2026-11-02 is a Monday.
const MONDAY_MORNING = '2026-11-02T12:30';
const MONDAY_AFTERNOON = '2026-11-02T13:30';
const TUESDAY_MORNING = '2026-11-03T10:00';
const SATURDAY_MORNING = '2026-11-07T10:00';

await check('recommended pins action digests', () => assert.ok(read('renovate/recommended.json').extends.includes('helpers:pinGitHubActionDigests')));

const policies = { 'automerge-non-major': [true, false], 'automerge-all': [true, true], 'grouped-non-major': [false, false] };
for (const [policy, [minorMerges, majorMerges]] of Object.entries(policies)) {
  await check(policy, async () => {
    const config = load(policy);
    assert.equal((await update(config, { updateType: 'minor' })).automerge ?? false, minorMerges, 'minor automerge');
    assert.equal((await update(config, { updateType: 'major', datasource: 'github-tags' })).automerge ?? false, majorMerges, 'major automerge');
    for (const u of [{ updateType: 'minor', datasource: 'docker' }, { updateType: 'major' }, { updateType: 'patch', datasource: 'pypi' }]) {
      assert.equal((await update(config, u)).minimumReleaseAge, '3 days', `hold on ${u.datasource ?? 'npm'} ${u.updateType}`);
    }
    // Non-major updates of every kind share one group; majors stay out of it.
    const groups = await Promise.all(['minor', 'patch', 'pin', 'pinDigest', 'digest'].map(async (t) => (await update(config, { updateType: t })).groupName));
    assert.ok(groups[0] && groups.every((g) => g === groups[0]), `non-major updates split across groups: ${groups}`);
    assert.notEqual(config.separateMajorMinor, false, 'majors must get their own PR');
    assert.equal(openAt(config, SATURDAY_MORNING), true, 'a policy alone has no schedule');
  });
}

for (const policy of ['automerge-non-major', 'automerge-all']) {
  await check(`${policy} security fixes`, () => {
    const alerts = load(policy).vulnerabilityAlerts;
    assert.equal(alerts.automerge, true, 'security fixes merge themselves');
    assert.equal(alerts.minimumReleaseAge, null, 'security fixes skip the hold');
    assert.equal(openAt(alerts, SATURDAY_MORNING), true, 'security fixes ignore the schedule');
  });
}
await check('grouped-non-major security fixes', () => assert.equal(load('grouped-non-major').vulnerabilityAlerts.automerge, false));

const windows = {
  weekly: { [MONDAY_MORNING]: true, [MONDAY_AFTERNOON]: false, [TUESDAY_MORNING]: false, [SATURDAY_MORNING]: false },
  daily: { [MONDAY_MORNING]: true, [MONDAY_AFTERNOON]: false, [TUESDAY_MORNING]: true, [SATURDAY_MORNING]: false },
};
for (const [schedule, expected] of Object.entries(windows)) {
  for (const preset of [schedule, `${schedule}-automerge-all`]) {
    await check(`${preset} window`, () => {
      const config = load(preset);
      for (const [time, open] of Object.entries(expected)) assert.equal(openAt(config, time), open, `open at ${time}`);
    });
  }
  await check(`${schedule}-automerge-all`, () => {
    assert.deepEqual(load(`${schedule}-automerge-all`), mergeChildConfig(load('automerge-all'), load(schedule)));
  });
}

// This repo's own config: daily, majors merge, TypeScript held below 7, lockfiles refreshed,
// and the renovate bump in its own PR so a release that breaks this script holds back nothing else.
await check('.github/renovate.json', async () => {
  const config = resolve(read('.github/renovate.json'));
  assert.equal(openAt(config, TUESDAY_MORNING), true, 'daily');
  assert.equal((await update(config, { updateType: 'major' })).automerge, true, 'majors merge');
  assert.equal((await update(config, { updateType: 'major', packageName: 'typescript' })).allowedVersions, '<7', 'TypeScript hold');
  assert.deepEqual([config.lockFileMaintenance.enabled, config.lockFileMaintenance.automerge], [true, true], 'lockfile maintenance');
  const renovate = await update(config, { updateType: 'minor', packageName: 'renovate' });
  assert.notEqual(renovate.groupName, (await update(config, { updateType: 'minor' })).groupName, 'renovate grouped with the rest');
});

// Renovate keeps bumping the validator pin in the workflow: the renovate-comments manager this repo's
// config sets up must select the workflow file and extract a version from it.
await check('validator pin', () => {
  const workflow = '.github/workflows/renovate-presets.yml';
  const managers = resolve(read('.github/renovate.json')).customManagers ?? [];
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
