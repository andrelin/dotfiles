import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

const REPO = 'andrelin/dotfiles';
const EDIT_BASE = `https://github.com/${REPO}/edit/main`;

// Map gathered file paths back to their source-of-truth locations on GitHub,
// so the "Edit this page" link points at the original file rather than the
// generated copy. Anything not in this map (or not under tips/) gets no link.
const sourcePathMap: Record<string, string> = {
  'overview.md': 'README.md',
  'tips/index.md': 'TIPS.md',
  'scripts/init.md': 'init/README.md',
  'scripts/source.md': 'source/README.md',
};

const config: Config = {
  title: 'Dotfiles',
  tagline: 'Tips, repo features, and bundled-tool basics',
  url: 'https://dotfiles.lindjo.no',
  baseUrl: '/',
  organizationName: 'andrelin',
  projectName: 'dotfiles',
  trailingSlash: false,

  onBrokenLinks: 'throw',

  markdown: {
    hooks: {
      onBrokenMarkdownLinks: 'throw',
    },
  },

  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      {
        docs: {
          path: 'docs-generated',
          routeBasePath: '/',
          sidebarPath: './sidebars.ts',
          editUrl: ({docPath}) => {
            const src =
              sourcePathMap[docPath] ??
              (docPath.startsWith('tips/') ? docPath : null);
            return src ? `${EDIT_BASE}/${src}` : undefined;
          },
        },
        blog: false,
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  themeConfig: {
    navbar: {
      title: 'Dotfiles',
      items: [
        {
          type: 'docSidebar',
          sidebarId: 'main',
          position: 'left',
          label: 'Docs',
        },
        {
          href: `https://github.com/${REPO}`,
          position: 'right',
          className: 'header-github-link',
          'aria-label': 'GitHub repository',
        },
      ],
    },
    colorMode: {
      defaultMode: 'dark',
      respectPrefersColorScheme: true,
    },
    prism: {
      additionalLanguages: ['bash', 'json', 'yaml', 'docker', 'ini', 'java', 'groovy'],
    },
    footer: {
      style: 'dark',
      links: [
        {
          label: 'Source on GitHub',
          href: `https://github.com/${REPO}`,
        },
      ],
      copyright: `© ${new Date().getFullYear()} Andreas Lind-Johansen — MIT licensed`,
    },
  } satisfies Preset.ThemeConfig,
};

// noinspection JSUnusedGlobalSymbols -- loaded by Docusaurus framework at runtime
export default config;
