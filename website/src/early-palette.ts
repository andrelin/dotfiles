// Synchronous head-injected script. Picks a random palette before the page
// paints, applies the `--ifm-color-primary*` vars (plus optional `extras`)
// to documentElement, and stores the result on `window.__dotfilesPalette`
// for `randomLogo.ts` to read. Running in <head> avoids the flash of
// default colors that you get when a clientModule swaps them post-paint.
//
// Body bg for the rainbow palette is handled by a CSS attribute selector
// (`html[data-palette='rainbow'] body { ... }`) since <body> doesn't exist
// yet when this script runs. We use a `data-palette` attribute rather than a
// class because React 19's hydration overwrites `documentElement.className`
// (stripping anything we add), but leaves `data-*` attributes and inline
// CSS custom properties alone.
//
// This file is read by docusaurus.config.ts, transpiled to JS via esbuild,
// and inlined into <head> via `headTags`. It is NOT bundled with the rest
// of the site code, so it must be self-contained — no imports.

type Palette = {
  name: string;
  primary: string;
  dark: string;
  darker: string;
  darkest: string;
  light: string;
  lighter: string;
  lightest: string;
  extras?: Record<string, string>;
  darkOnly?: boolean;
  weight?: number;
  darkWeight?: number;
};

type Shades = Pick<
  Palette,
  'primary' | 'dark' | 'darker' | 'darkest' | 'light' | 'lighter' | 'lightest'
>;

(function (): void {
  if (typeof document === 'undefined') return;

  const PALETTES: ReadonlyArray<Palette> = [
    // Tailwind-derived neutrals — primary 600, light 400 (icon accent).
    {name: 'emerald', primary: '#059669', dark: '#047857', darker: '#065f46', darkest: '#064e3b', light: '#34d399', lighter: '#6ee7b7', lightest: '#a7f3d0'},
    {name: 'violet',  primary: '#7c3aed', dark: '#6d28d9', darker: '#5b21b6', darkest: '#4c1d95', light: '#a78bfa', lighter: '#c4b5fd', lightest: '#ddd6fe'},
    {name: 'amber',   primary: '#d97706', dark: '#b45309', darker: '#92400e', darkest: '#78350f', light: '#fbbf24', lighter: '#fcd34d', lightest: '#fde68a'},
    {name: 'rose',    primary: '#e11d48', dark: '#be123c', darker: '#9f1239', darkest: '#881337', light: '#fb7185', lighter: '#fda4af', lightest: '#fecdd3'},
    {name: 'teal',    primary: '#0d9488', dark: '#0f766e', darker: '#115e59', darkest: '#134e4a', light: '#2dd4bf', lighter: '#5eead4', lightest: '#99f6e4'},
    {name: 'indigo',  primary: '#4f46e5', dark: '#4338ca', darker: '#3730a3', darkest: '#312e81', light: '#818cf8', lighter: '#a5b4fc', lightest: '#c7d2fe'},

    // Themed accent — sky blue.
    {name: 'sky-on-blue', primary: '#0284c7', dark: '#0369a1', darker: '#075985', darkest: '#0c4a6e', light: '#38bdf8', lighter: '#7dd3fc', lightest: '#bae6fd'},

    // Solarized dark: full theme — dark teal background and base0 fg. Dark mode only, rare.
    {
      name: 'solarized',
      primary: '#268bd2', dark: '#1f7ab8', darker: '#196a9e', darkest: '#135988',
      light: '#4f9adc', lighter: '#79b1e2', lightest: '#a3c9eb',
      darkOnly: true,
      weight: 0.4,
      extras: {
        '--ifm-background-color': '#002b36',
        '--ifm-background-surface-color': '#073642',
        '--ifm-navbar-background-color': '#002b36',
        '--ifm-footer-background-color': '#002b36',
        '--ifm-color-content': '#839496',
        '--ifm-color-content-secondary': '#586e75',
        '--ifm-font-color-base': '#839496',
        '--ifm-heading-color': '#93a1a1',
        '--ifm-link-color': '#268bd2',
        '--ifm-code-color': '#839496',
        '--ifm-code-background': '#073642',
      },
    },

    // Terminal green: full theme — hard black bg, green text. Dark mode only, rare.
    {
      name: 'terminal-green',
      primary: '#16a34a', dark: '#15803d', darker: '#166534', darkest: '#14532d',
      light: '#4ade80', lighter: '#86efac', lightest: '#bbf7d0',
      darkOnly: true,
      weight: 0.4,
      extras: {
        '--ifm-background-color': '#000000',
        '--ifm-background-surface-color': '#0a0a0a',
        '--ifm-navbar-background-color': '#000000',
        '--ifm-footer-background-color': '#000000',
        '--ifm-color-content': '#4ade80',
        '--ifm-color-content-secondary': '#4ade80',
        '--ifm-font-color-base': '#4ade80',
        '--ifm-heading-color': '#86efac',
        '--ifm-link-color': '#86efac',
        '--ifm-code-color': '#4ade80',
        '--ifm-code-background': '#0a0a0a',
      },
    },

    // Rainbow: pairs with multicolor icons; primary varies per load.
    // Background is a subtle rainbow gradient via the `palette-rainbow`
    // class set below, styled in custom.css.
    {
      name: 'rainbow',
      primary: '#d946ef', dark: '#c026d3', darker: '#a21caf', darkest: '#86198f',
      light: '#e879f9', lighter: '#f0abfc', lightest: '#f5d0fe',
      weight: 1,
      darkWeight: 0.4,
    },
  ];

  // Per-load rainbow primary variants — picked when the rainbow palette rolls.
  const RAINBOW_VARIANTS: ReadonlyArray<Shades> = [
    {primary: '#dc2626', dark: '#b91c1c', darker: '#991b1b', darkest: '#7f1d1d', light: '#f87171', lighter: '#fca5a5', lightest: '#fecaca'},
    {primary: '#ea580c', dark: '#c2410c', darker: '#9a3412', darkest: '#7c2d12', light: '#fb923c', lighter: '#fdba74', lightest: '#fed7aa'},
    {primary: '#d97706', dark: '#b45309', darker: '#92400e', darkest: '#78350f', light: '#fbbf24', lighter: '#fcd34d', lightest: '#fde68a'},
    {primary: '#16a34a', dark: '#15803d', darker: '#166534', darkest: '#14532d', light: '#4ade80', lighter: '#86efac', lightest: '#bbf7d0'},
    {primary: '#2563eb', dark: '#1d4ed8', darker: '#1e40af', darkest: '#1e3a8a', light: '#60a5fa', lighter: '#93c5fd', lightest: '#bfdbfe'},
    {primary: '#9333ea', dark: '#7e22ce', darker: '#6b21a8', darkest: '#581c87', light: '#c084fc', lighter: '#d8b4fe', lightest: '#e9d5ff'},
  ];

  const PREVIOUS_PALETTE_KEY = 'dotfiles-previous-palette';

  function detectDarkMode(): boolean {
    const dataTheme = document.documentElement.getAttribute('data-theme');
    if (dataTheme === 'dark') return true;
    if (dataTheme === 'light') return false;
    try {
      const stored = window.localStorage.getItem('theme');
      if (stored === 'dark') return true;
      if (stored === 'light') return false;
    } catch {
      // localStorage may be blocked.
    }
    return window.matchMedia('(prefers-color-scheme: dark)').matches;
  }

  function weightOf(p: Palette, isDark: boolean): number {
    if (isDark && p.darkWeight !== undefined) return p.darkWeight;
    return p.weight ?? 1;
  }

  function getPreviousPalette(): string | null {
    try {
      return window.localStorage.getItem(PREVIOUS_PALETTE_KEY);
    } catch {
      return null;
    }
  }

  function rememberPalette(name: string): void {
    try {
      window.localStorage.setItem(PREVIOUS_PALETTE_KEY, name);
    } catch {
      // localStorage may be blocked.
    }
  }

  function pickPalette(isDark: boolean): Palette {
    const previous = getPreviousPalette();
    let available = PALETTES.filter((p) => !p.darkOnly || isDark);
    // Skip the previous pick so the same theme doesn't roll twice in a row,
    // unless filtering would leave no choices at all.
    if (previous && available.length > 1) {
      const filtered = available.filter((p) => p.name !== previous);
      if (filtered.length > 0) available = filtered;
    }
    const totalWeight = available.reduce(
      (sum, p) => sum + weightOf(p, isDark),
      0,
    );
    let r = Math.random() * totalWeight;
    let selected: Palette = available[0];
    for (const p of available) {
      r -= weightOf(p, isDark);
      if (r <= 0) {
        selected = p;
        break;
      }
    }
    rememberPalette(selected.name);
    if (selected.name === 'rainbow') {
      const v = RAINBOW_VARIANTS[Math.floor(Math.random() * RAINBOW_VARIANTS.length)];
      selected = {...selected, ...v};
    }
    return selected;
  }

  // In dark mode, regular palettes need a brighter primary to read on a dark
  // bg — Docusaurus's own default does this by hand (lighter base + scale
  // shifted up). Mirror that: shift `light → primary`, and bump the rest of
  // the scale up one slot. Skip darkOnly palettes since they're already
  // designed around a dark surface.
  function adjustForMode(p: Palette, isDark: boolean): Palette {
    if (!isDark || p.darkOnly) return p;
    return {
      ...p,
      darkest: p.darker,
      darker: p.dark,
      dark: p.primary,
      primary: p.light,
      light: p.lighter,
      lighter: p.lightest,
      lightest: p.lightest,
    };
  }

  const isDark = detectDarkMode();
  const palette = adjustForMode(pickPalette(isDark), isDark);

  const root = document.documentElement;
  root.style.setProperty('--ifm-color-primary', palette.primary);
  root.style.setProperty('--ifm-color-primary-dark', palette.dark);
  root.style.setProperty('--ifm-color-primary-darker', palette.darker);
  root.style.setProperty('--ifm-color-primary-darkest', palette.darkest);
  root.style.setProperty('--ifm-color-primary-light', palette.light);
  root.style.setProperty('--ifm-color-primary-lighter', palette.lighter);
  root.style.setProperty('--ifm-color-primary-lightest', palette.lightest);
  if (palette.extras) {
    for (const [k, v] of Object.entries(palette.extras)) {
      root.style.setProperty(k, v);
    }
  }
  if (palette.name === 'rainbow') {
    root.setAttribute('data-palette', 'rainbow');
  }

  (window as Window & {__dotfilesPalette?: Palette}).__dotfilesPalette = palette;
})();
