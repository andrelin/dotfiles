#!/usr/bin/env tsx
// Gather repo docs into website/docs-generated/ for Docusaurus to consume.
// Source files stay in their canonical locations; this script produces a
// transient tree that's gitignored and rebuilt on every `npm run build|start`.

import fs from 'node:fs';
import path from 'node:path';

const REPO = 'andrelin/dotfiles';
const REPO_ROOT = path.resolve(__dirname, '..', '..');
const OUT = path.resolve(__dirname, '..', 'docs-generated');

const SOURCE_DIRS = [
  'bin',
  'init',
  'source',
  'copy',
  'link',
  'conf',
  'hooks',
  'test',
  '.github',
];
const ROOT_FILES = [
  '.gitignore',
  '.gitattributes',
  '.markdownlint.json',
  '.shellcheckrc',
  'LICENSE',
];

const escapeRe = (s: string): string => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const sourceDirsAlt = SOURCE_DIRS.map(escapeRe).join('|');
const rootFilesAlt = ROOT_FILES.map(escapeRe).join('|');

function read(rel: string): string {
  return fs.readFileSync(path.join(REPO_ROOT, rel), 'utf8');
}

function ensureDir(p: string): void {
  fs.mkdirSync(p, {recursive: true});
}

function write(rel: string, content: string): void {
  const full = path.join(OUT, rel);
  ensureDir(path.dirname(full));
  // Always end with a single trailing newline.
  fs.writeFileSync(full, content.replace(/\n*$/, '\n'));
}

function stripDoctoc(s: string): string {
  return s
    .replace(/<!-- START doctoc[\s\S]*?<!-- END doctoc[^>]*-->\n*/g, '')
    .replace(/<!-- DOCTOC SKIP -->\n*/g, '');
}

// MDX (Docusaurus's renderer) parses `<...>` as JSX, breaking standard markdown
// autolinks like `<https://example.com>`. Rewrite them to explicit `[url](url)`.
function rewriteAutolinks(s: string): string {
  return s.replace(/<(https?:\/\/[^>\s]+)>/g, '[$1]($1)');
}

function stripH1(s: string): string {
  return s.replace(/^# [^\n]*\n+/, '');
}

function rewriteRepoLinks(content: string): string {
  // Inline links to source-dirs (with optional ./ or ../ prefix), bare or with subpath.
  // Bare dir → tree/main/<dir>; with subpath → blob/main/<dir>/<sub>.
  let out = content.replace(
    new RegExp(`\\]\\((?:\\.\\.?\\/)?(${sourceDirsAlt})((?:\\/[^)\\s#]+)?)\\)`, 'g'),
    (_m: string, dir: string, sub: string) =>
      `](https://github.com/${REPO}/${sub ? 'blob' : 'tree'}/main/${dir}${sub})`,
  );

  // Reference-style: [foo]: bin/foo
  out = out.replace(
    new RegExp(`^(\\[[^\\]]+\\]):\\s*(?:\\.\\.?\\/)?((?:${sourceDirsAlt})\\/\\S+)$`, 'gm'),
    `$1: https://github.com/${REPO}/blob/main/$2`,
  );

  // Root-level files (.gitignore, LICENSE, etc.).
  out = out.replace(
    new RegExp(`\\]\\((${rootFilesAlt})\\)`, 'g'),
    `](https://github.com/${REPO}/blob/main/$1)`,
  );

  return out;
}

type FrontMatterValue = string | number | boolean;

function frontMatter(
  fields: Record<string, FrontMatterValue>,
  body: string,
): string {
  const yaml = Object.entries(fields)
    .map(([k, v]) => `${k}: ${typeof v === 'string' ? JSON.stringify(v) : v}`)
    .join('\n');
  return `---\n${yaml}\n---\n\n${body}`;
}

function titleCase(s: string): string {
  return s.replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase());
}

// ---- clean output ----
fs.rmSync(OUT, {recursive: true, force: true});
ensureDir(OUT);

// ---- overview (root README.md) ----
{
  let body = stripDoctoc(read('README.md'));
  // The README's H1 is `<logo> Dotfiles` (logo decorative). On the docs site
  // the H1 is the page title — replace it with `<logo alt="Dotfiles"> Overview`
  // so it reads as "Dotfiles Overview" with the logo carrying the wordmark.
  body = body.replace(
    /^# .*$/m,
    '# <img src="/img/logo-dot-files.svg" alt="Dotfiles" class="title-logo" width="56" /> Overview',
  );
  // Drop the README's own pointer to the rendered site — circular on the site itself.
  body = body.replace(/^Browseable docs:.*\n+/m, '');
  // Internal docs links: point at the gathered tree, not the source-tree
  // paths (TIPS.md / tips/) which won't exist on the site.
  body = body
    .replace(/\]\(TIPS\.md\)/g, '](./tips/index.md)')
    .replace(/\]\(tips\/\)/g, '](./tips/index.md)')
    .replace(/\]\(tips\/([^)]+)\)/g, '](./tips/$1)');
  body = rewriteAutolinks(rewriteRepoLinks(body));
  write(
    'overview.md',
    frontMatter(
      {
        title: 'Overview',
        sidebar_label: 'Overview',
        sidebar_position: 1,
        slug: '/',
      },
      body,
    ),
  );
}

// ---- tips index (TIPS.md) ----
{
  const raw = stripH1(stripDoctoc(read('TIPS.md')));
  // tips/foo.md -> ./foo.md (we're already inside docs-generated/tips/)
  const rewritten = raw.replace(/\]\(tips\/([^)]+)\)/g, '](./$1)');
  write(
    'tips/index.md',
    frontMatter(
      {
        title: 'Tips',
        sidebar_label: 'Index',
      },
      rewriteAutolinks(rewriteRepoLinks(rewritten)),
    ),
  );
}

// ---- _category_.json for tips ----
fs.writeFileSync(
  path.join(OUT, 'tips', '_category_.json'),
  JSON.stringify(
    {
      label: 'Tips',
      position: 2,
      link: {type: 'doc', id: 'tips/index'},
    },
    null,
    2,
  ) + '\n',
);

// ---- individual tip files ----
const tipsDir = path.join(REPO_ROOT, 'tips');
for (const f of fs.readdirSync(tipsDir).sort()) {
  if (!f.endsWith('.md')) continue;
  const raw = fs.readFileSync(path.join(tipsDir, f), 'utf8');
  const cleaned = stripDoctoc(raw);
  const h1 = cleaned.match(/^# ([^\n]+)/);
  const title = h1 ? h1[1] : f.replace(/\.md$/, '');

  const numMatch = f.match(/^(\d+)_(.+)\.md$/);
  const sidebarLabel = numMatch
    ? `${numMatch[1]}. ${titleCase(numMatch[2])}`
    : title;

  const body = rewriteAutolinks(rewriteRepoLinks(stripH1(cleaned)));
  write(
    `tips/${f}`,
    frontMatter(
      {
        title,
        sidebar_label: sidebarLabel,
      },
      body,
    ),
  );
}

// ---- scripts reference (init/README.md, source/README.md) ----
{
  const body = rewriteAutolinks(stripH1(stripDoctoc(read('init/README.md'))));
  write(
    'scripts/init.md',
    frontMatter(
      {
        title: 'Init Scripts',
        sidebar_label: 'Init scripts',
        sidebar_position: 1,
      },
      body,
    ),
  );
}
{
  const body = rewriteAutolinks(stripH1(stripDoctoc(read('source/README.md'))));
  write(
    'scripts/source.md',
    frontMatter(
      {
        title: 'Source Scripts',
        sidebar_label: 'Source scripts',
        sidebar_position: 2,
      },
      body,
    ),
  );
}

fs.writeFileSync(
  path.join(OUT, 'scripts', '_category_.json'),
  JSON.stringify(
    {
      label: 'Reference',
      position: 3,
    },
    null,
    2,
  ) + '\n',
);

console.log(`Gathered docs to ${path.relative(process.cwd(), OUT)}`);
