// Icon-swap client module. Reads the palette picked synchronously by the
// head-injected `early-palette.js` (on `window.__dotfilesPalette`) and
// swaps the favicon, navbar logo, and title logo to match.
//
// Title logo is always the dot-files brand mark (recolored to the palette's
// `light` shade, or one of the multicolor dot-files variants when the
// rainbow palette rolls). Navbar/favicon are picked at random from a pool
// of brand-mark variants so the navbar gets some surprise per load. The
// README body image is not touched and stays static.
//
// CSS vars and rainbow body bg are handled by `early-palette.js` and
// `custom.css` respectively — this module only deals with images.
//
// Note: `Window.__dotfilesPalette` is augmented globally below so other
// code (and TS) can read the active palette.

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
};

declare global {
  interface Window {
    __dotfilesPalette?: Palette;
  }
}

type IconDef = {
  path: string;
  // Color in the SVG that gets replaced with the palette's `light` shade.
  // null means "leave colors alone" (rainbow icons).
  accent: string | null;
};

const BASE_ICONS: ReadonlyArray<IconDef> = [
  {path: '/img/logo-dot-dash.svg',      accent: '#38bdf8'},
  {path: '/img/logo-dot-files.svg',     accent: '#38bdf8'},
  {path: '/img/logo-tilde-dot.svg',     accent: '#38bdf8'},
  {path: '/img/logo-prompt-cursor.svg', accent: '#839496'},
];

const RAINBOW_ICONS: ReadonlyArray<IconDef> = [
  {path: '/img/logo-rainbow-dot-dash.svg',        accent: null},
  {path: '/img/logo-rainbow-dot-files-left.svg',  accent: null},
  {path: '/img/logo-rainbow-dot-files-right.svg', accent: null},
  {path: '/img/logo-rainbow-tilde-dot.svg',       accent: null},
  {path: '/img/logo-rainbow-prompt-cursor.svg',   accent: null},
];

// Used during SSR so types resolve cleanly; the real palette comes from
// `window.__dotfilesPalette` at runtime.
const FALLBACK: Palette = {
  name: 'sky-on-blue',
  primary: '#0284c7', dark: '#0369a1', darker: '#075985', darkest: '#0c4a6e',
  light: '#38bdf8', lighter: '#7dd3fc', lightest: '#bae6fd',
};

const palette: Palette =
  typeof window !== 'undefined' && window.__dotfilesPalette
    ? window.__dotfilesPalette
    : FALLBACK;

const iconPool: ReadonlyArray<IconDef> =
  palette.name === 'rainbow' ? RAINBOW_ICONS : BASE_ICONS;
const icon: IconDef = iconPool[Math.floor(Math.random() * iconPool.length)];

let iconDataUri: string | null = null;

async function loadIcon(): Promise<string> {
  if (iconDataUri) return iconDataUri;
  const res = await fetch(icon.path);
  const text = await res.text();
  const recolored = icon.accent
    ? text.replaceAll(icon.accent, palette.light)
    : text;
  iconDataUri = 'data:image/svg+xml;utf8,' + encodeURIComponent(recolored);
  return iconDataUri;
}

function setFavicon(href: string): void {
  // Browsers often skip refetching when only `href` mutates on an existing
  // <link>. Removing and recreating the element forces a fresh load.
  const head = document.head;
  head.querySelectorAll('link[rel="icon"], link[rel="shortcut icon"]').forEach(
    (link) => link.remove(),
  );
  const link = document.createElement('link');
  link.rel = 'icon';
  link.type = 'image/svg+xml';
  link.href = href;
  head.appendChild(link);
}

function setNavbarLogo(href: string): void {
  document.querySelectorAll<HTMLImageElement>('.navbar__logo img').forEach((img) => {
    img.src = href;
    img.removeAttribute('srcset');
  });
}

// The title logo (next to the Overview heading) is always the dot-files
// brand mark — the navbar rolls a random shape but the brand mark stays
// recognizable on every page. Recolored to the palette's `light` shade;
// rainbow uses one of the multicolor dot-files variants directly.
let titleLogoDataUri: string | null = null;

async function loadTitleLogo(): Promise<string> {
  if (titleLogoDataUri) return titleLogoDataUri;
  const isRainbow = palette.name === 'rainbow';
  const path = isRainbow
    ? '/img/logo-rainbow-dot-files-left.svg'
    : '/img/logo-dot-files.svg';
  const res = await fetch(path);
  const text = await res.text();
  const recolored = isRainbow
    ? text
    : text.replaceAll('#38bdf8', palette.light);
  titleLogoDataUri = 'data:image/svg+xml;utf8,' + encodeURIComponent(recolored);
  return titleLogoDataUri;
}

async function setTitleLogo(): Promise<void> {
  const src = await loadTitleLogo();
  document.querySelectorAll<HTMLImageElement>('.title-logo').forEach((img) => {
    img.src = src;
  });
}

async function applyIcon(): Promise<void> {
  if (typeof document === 'undefined') return;
  const src = await loadIcon();
  setFavicon(src);
  setNavbarLogo(src);
  await setTitleLogo();
}

export function onRouteDidUpdate(): void {
  void applyIcon();
}

if (typeof window !== 'undefined') {
  void applyIcon();
}
