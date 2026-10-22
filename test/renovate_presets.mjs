// Checks the presets in renovate/ as other repos will get them, using Renovate's own code.
// renovate-config-validator reads each file alone, so it misses broken references between
// presets, typos in enum values, and what a preset resolves to once its extends are merged.
//
// Usage: RENOVATE_DIR=<dir with node_modules/renovate> node test/renovate_presets.mjs

import assert from 'node:assert/strict';
import fs from 'node:fs';

const renovate = `${process.env.RENOVATE_DIR}/node_modules/renovate/dist`;
const { getOptions } = await import(`${renovate}/config/options/index.js`);
const { mergeChildConfig } = await import(`${renovate}/config/utils.js`);
const { parsePreset } = await import(`${renovate}/config/presets/parse.js`);
const { replaceArgs } = await import(`${renovate}/config/presets/index.js`);
const { matchRegexOrGlobList } = await import(`${renovate}/util/string-match.js`);

const PREFIX = 'github>andrelin/dotfiles//renovate/';
const presets = fs.readdirSync('renovate').filter((f) => f.endsWith('.json')).map((f) => f.slice(0, -5)).sort();
const read = (file) => JSON.parse(fs.readFileSync(file, 'utf8'));
const failures = [];
const check = (name, fn) => {
  try {
    fn();
  } catch (e) {
    failures.push(`${name}: ${e.message}`);
  }
};

// Every reference to this repo's presets, in config and in the docs people copy from,
// is in the one form Renovate resolves and names a preset that exists.
for (const file of ['.github/renovate.json', 'renovate/README.md', 'CLAUDE.md', ...presets.map((p) => `renovate/${p}.json`)]) {
  for (const [ref] of fs.readFileSync(file, 'utf8').matchAll(/github>andrelin\/dotfiles[^\s"`)]*/gi)) {
    check(`${file} ${ref}`, () => {
      assert.ok(ref.startsWith(PREFIX), `not in the ${PREFIX}<name> form`);
      const name = ref.slice(PREFIX.length).replace(/\(.*$/, '');
      assert.ok(name === '<name>' || presets.includes(name), 'no such preset');
    });
  }
}

// The README table lists exactly the presets that exist.
check('README table', () => {
  const listed = [...fs.readFileSync('renovate/README.md', 'utf8').matchAll(/^\| (`.+?) \|/gm)]
    .flatMap(([, cell]) => [...cell.matchAll(/`([a-z-]+)/g)].map(([, n]) => n));
  assert.deepEqual([...listed].sort(), presets);
});

// Enum-valued options hold allowed values; the validator lets e.g. matchUpdateTypes: ["mayor"] through.
const allowed = new Map(getOptions().filter((o) => o.allowedValues).map((o) => [o.name, o.allowedValues]));
const checkEnums = (where, obj) => {
  if (Array.isArray(obj)) return obj.forEach((v, i) => checkEnums(`${where}[${i}]`, v));
  if (obj === null || typeof obj !== 'object') return;
  for (const [key, value] of Object.entries(obj)) {
    if (allowed.has(key)) {
      for (const v of [value].flat()) {
        check(`${where}.${key}`, () => assert.ok(allowed.get(key).includes(v), `${v} is not one of ${allowed.get(key).join(', ')}`));
      }
    }
    checkEnums(`${where}.${key}`, value);
  }
};
for (const p of presets) checkEnums(p, read(`renovate/${p}.json`));
checkEnums('.github/renovate.json', read('.github/renovate.json'));

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

// What a resolved config does with one update: the last matching packageRule wins.
const effective = (config, { updateType, datasource }) => {
  const result = { automerge: config.automerge ?? false, minimumReleaseAge: config.minimumReleaseAge };
  for (const rule of config.packageRules ?? []) {
    if (rule.matchUpdateTypes && !rule.matchUpdateTypes.includes(updateType)) continue;
    if (rule.matchDatasources && !rule.matchDatasources.includes(datasource)) continue;
    if (rule.matchPackageNames && !rule.matchPackageNames.includes('*')) continue;
    for (const key of Object.keys(result)) if (key in rule) result[key] = rule[key];
  }
  return result;
};

const minor = { updateType: 'minor', datasource: 'docker' };
const major = { updateType: 'major', datasource: 'github-tags' };
const policies = { 'automerge-non-major': [true, false], 'automerge-all': [true, true], 'grouped-non-major': [false, false] };
for (const [policy, [minorMerges, majorMerges]] of Object.entries(policies)) {
  check(policy, () => {
    const config = load(policy);
    assert.equal(effective(config, minor).automerge, minorMerges, 'minor automerge');
    assert.equal(effective(config, major).automerge, majorMerges, 'major automerge');
    for (const update of [minor, major, { updateType: 'patch', datasource: 'pypi' }]) {
      assert.equal(effective(config, update).minimumReleaseAge, '3 days', `hold on ${update.datasource} ${update.updateType}`);
    }
    assert.equal(config.timezone, 'Europe/Oslo');
  });
}
check('grouped-non-major security fixes', () => assert.equal(load('grouped-non-major').vulnerabilityAlerts.automerge, false));

for (const schedule of ['weekly', 'daily']) {
  check(`${schedule}-automerge-all`, () => {
    assert.deepEqual(load(`${schedule}-automerge-all`), mergeChildConfig(load('automerge-all'), load(schedule)));
  });
}

// Renovate keeps bumping the validator pin in the workflow: the renovate-comments manager this repo's
// config sets up must select the workflow file and extract the pin from it.
check('validator pin', () => {
  const workflow = '.github/workflows/renovate-presets.yml';
  const managers = resolve(read('.github/renovate.json')).customManagers ?? [];
  const manager = managers.find((m) => matchRegexOrGlobList(workflow, m.managerFilePatterns));
  assert.ok(manager, `no custom manager selects ${workflow}`);
  const m = new RegExp(manager.matchStrings[0]).exec(fs.readFileSync(workflow, 'utf8'));
  assert.ok(m, 'no renovate comment matched');
  assert.deepEqual({ datasource: m.groups.datasource, depName: m.groups.depName }, { datasource: 'npm', depName: 'renovate' });
});

for (const f of failures) console.log(`::error::${f}`);
console.log(failures.length ? `${failures.length} failure(s)` : 'All renovate preset checks passed');
process.exit(failures.length ? 1 : 0);
