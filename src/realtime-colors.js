/**
 * Realtime Colors Engine
 * Inspired by realtimecolors.com & dynamic reactive color systems.
 * Provides live palette switching, HSL harmonic randomization,
 * real-time WCAG contrast calculation, and audio/alert reactive color shifts.
 */

export const CURATED_PALETTES = Object.freeze({
  aurora: {
    id: 'aurora',
    name: 'Emerald Aurora',
    tag: 'Calm & Accessible',
    primary: '#0c7770',
    primaryHover: '#0a635d',
    secondary: '#36b39b',
    accent: '#4ade80',
    light: {
      canvas: '#f4f8f7',
      paper: '#ffffff',
      ink: '#143133',
      muted: '#6f8584',
      line: '#e3ece9',
      wave1: 'rgba(12, 119, 112, 0.18)',
      wave2: 'rgba(54, 179, 155, 0.25)',
      wave3: 'rgba(74, 222, 128, 0.15)',
    },
    dark: {
      canvas: '#0f2020',
      paper: '#172c2b',
      ink: '#e3f2ef',
      muted: '#8aa3a0',
      line: '#27413f',
      wave1: 'rgba(12, 119, 112, 0.35)',
      wave2: 'rgba(54, 179, 155, 0.22)',
      wave3: 'rgba(74, 222, 128, 0.12)',
    },
  },
  violet: {
    id: 'violet',
    name: 'Cosmic Violet',
    tag: 'Modern & Electric',
    primary: '#7c3aed',
    primaryHover: '#6d28d9',
    secondary: '#a855f7',
    accent: '#ec4899',
    light: {
      canvas: '#f8f6fd',
      paper: '#ffffff',
      ink: '#1c1533',
      muted: '#766e94',
      line: '#ebe5f7',
      wave1: 'rgba(124, 58, 237, 0.16)',
      wave2: 'rgba(168, 85, 247, 0.22)',
      wave3: 'rgba(236, 72, 153, 0.14)',
    },
    dark: {
      canvas: '#120d22',
      paper: '#1c1533',
      ink: '#f3efff',
      muted: '#968bb8',
      line: '#2f2452',
      wave1: 'rgba(124, 58, 237, 0.38)',
      wave2: 'rgba(168, 85, 247, 0.24)',
      wave3: 'rgba(236, 72, 153, 0.15)',
    },
  },
  coral: {
    id: 'coral',
    name: 'Sunset Coral',
    tag: 'Warm & High-Energy',
    primary: '#e11d48',
    primaryHover: '#be123c',
    secondary: '#f59e0b',
    accent: '#fb7185',
    light: {
      canvas: '#fff7f5',
      paper: '#ffffff',
      ink: '#2d141b',
      muted: '#8d6d75',
      line: '#fae6e8',
      wave1: 'rgba(225, 29, 72, 0.15)',
      wave2: 'rgba(245, 158, 11, 0.22)',
      wave3: 'rgba(251, 113, 133, 0.16)',
    },
    dark: {
      canvas: '#200c12',
      paper: '#2e131b',
      ink: '#ffecef',
      muted: '#b38d97',
      line: '#4a202c',
      wave1: 'rgba(225, 29, 72, 0.35)',
      wave2: 'rgba(245, 158, 11, 0.20)',
      wave3: 'rgba(251, 113, 133, 0.12)',
    },
  },
  azure: {
    id: 'azure',
    name: 'Oceanic Azure',
    tag: 'Crisp & Deep Marine',
    primary: '#0284c7',
    primaryHover: '#0369a1',
    secondary: '#06b6d4',
    accent: '#38bdf8',
    light: {
      canvas: '#f0f8ff',
      paper: '#ffffff',
      ink: '#0e243a',
      muted: '#627c94',
      line: '#e1effa',
      wave1: 'rgba(2, 132, 199, 0.16)',
      wave2: 'rgba(6, 182, 212, 0.22)',
      wave3: 'rgba(56, 189, 248, 0.15)',
    },
    dark: {
      canvas: '#0a1622',
      paper: '#122334',
      ink: '#e5f3ff',
      muted: '#85a4c0',
      line: '#1c3750',
      wave1: 'rgba(2, 132, 199, 0.36)',
      wave2: 'rgba(6, 182, 212, 0.22)',
      wave3: 'rgba(56, 189, 248, 0.14)',
    },
  },
  jade: {
    id: 'jade',
    name: 'Forest Jade',
    tag: 'Botanical & Grounded',
    primary: '#15803d',
    primaryHover: '#166534',
    secondary: '#22c55e',
    accent: '#84cc16',
    light: {
      canvas: '#f2fbf4',
      paper: '#ffffff',
      ink: '#0e2817',
      muted: '#5e7d67',
      line: '#e0f3e5',
      wave1: 'rgba(21, 128, 61, 0.15)',
      wave2: 'rgba(34, 197, 94, 0.22)',
      wave3: 'rgba(132, 204, 22, 0.14)',
    },
    dark: {
      canvas: '#0b1b10',
      paper: '#132c1b',
      ink: '#e7faec',
      muted: '#7ba586',
      line: '#1f4329',
      wave1: 'rgba(21, 128, 61, 0.35)',
      wave2: 'rgba(34, 197, 94, 0.22)',
      wave3: 'rgba(132, 204, 22, 0.12)',
    },
  },
  highContrast: {
    id: 'highContrast',
    name: 'Solar Hyper-Contrast',
    tag: 'WCAG AAA Maximum Clarity',
    primary: '#0052cc',
    primaryHover: '#003d99',
    secondary: '#00875a',
    accent: '#ff9900',
    light: {
      canvas: '#ffffff',
      paper: '#ffffff',
      ink: '#000000',
      muted: '#333333',
      line: '#777777',
      wave1: 'rgba(0, 82, 204, 0.20)',
      wave2: 'rgba(0, 135, 90, 0.22)',
      wave3: 'rgba(255, 153, 0, 0.20)',
    },
    dark: {
      canvas: '#000000',
      paper: '#0a0a0a',
      ink: '#ffffff',
      muted: '#cccccc',
      line: '#888888',
      wave1: 'rgba(0, 82, 204, 0.40)',
      wave2: 'rgba(0, 135, 90, 0.35)',
      wave3: 'rgba(255, 153, 0, 0.30)',
    },
  },
});

/**
 * Converts a hex string (#ffffff or #fff) to [r, g, b] array
 */
export function hexToRgb(hex) {
  let clean = hex.replace('#', '').trim();
  if (clean.length === 3) {
    clean = clean.split('').map(c => c + c).join('');
  }
  const num = parseInt(clean, 16);
  if (Number.isNaN(num)) return [0, 0, 0];
  return [(num >> 16) & 255, (num >> 8) & 255, num & 255];
}

/**
 * Calculate WCAG 2.1 relative luminance
 */
export function getRelativeLuminance([r, g, b]) {
  const [rs, gs, bs] = [r, g, b].map(c => {
    const v = c / 255;
    return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
  });
  return 0.2126 * rs + 0.7152 * gs + 0.0722 * bs;
}

/**
 * Calculate WCAG contrast ratio between two hex colors
 */
export function getContrastRatio(hex1, hex2) {
  const lum1 = getRelativeLuminance(hexToRgb(hex1));
  const lum2 = getRelativeLuminance(hexToRgb(hex2));
  const brightest = Math.max(lum1, lum2);
  const darkest = Math.min(lum1, lum2);
  return (brightest + 0.05) / (darkest + 0.05);
}

/**
 * Returns formatted contrast badge info (e.g. { ratio: 7.2, passAAA: true, label: "7.2:1 AAA" })
 */
export function evaluateContrast(fgHex, bgHex) {
  const ratio = Math.round(getContrastRatio(fgHex, bgHex) * 10) / 10;
  const passAA = ratio >= 4.5;
  const passAAA = ratio >= 7.0;
  return {
    ratio,
    passAA,
    passAAA,
    rating: passAAA ? 'AAA' : passAA ? 'AA' : 'Fail',
    label: `${ratio}:1 ${passAAA ? 'AAA' : passAA ? 'AA' : 'Low'}`,
  };
}

/**
 * Generates an accessible, harmonious random color palette
 * using golden-ratio harmonic distribution on the HSL color wheel
 */
export function generateRandomHarmonicPalette() {
  const baseHue = Math.floor(Math.random() * 360);
  const secondaryHue = (baseHue + 40) % 360;
  const accentHue = (baseHue + 160) % 360;

  const hslToHex = (h, s, l) => {
    l /= 100;
    const a = (s * Math.min(l, 1 - l)) / 100;
    const f = n => {
      const k = (n + h / 30) % 12;
      const color = l - a * Math.max(Math.min(k - 3, 9 - k, 1), -1);
      return Math.round(255 * color).toString(16).padStart(2, '0');
    };
    return `#${f(0)}${f(8)}${f(4)}`;
  };

  const primary = hslToHex(baseHue, 78, 38);
  const secondary = hslToHex(secondaryHue, 82, 48);
  const accent = hslToHex(accentHue, 88, 55);

  return {
    id: `custom-${Date.now()}`,
    name: `Harmonic #${baseHue}°`,
    tag: 'Realtime Generative',
    primary,
    primaryHover: hslToHex(baseHue, 80, 32),
    secondary,
    accent,
    light: {
      canvas: hslToHex(baseHue, 22, 97),
      paper: '#ffffff',
      ink: hslToHex(baseHue, 45, 14),
      muted: hslToHex(baseHue, 18, 48),
      line: hslToHex(baseHue, 25, 91),
      wave1: `hsla(${baseHue}, 75%, 45%, 0.16)`,
      wave2: `hsla(${secondaryHue}, 75%, 55%, 0.22)`,
      wave3: `hsla(${accentHue}, 80%, 60%, 0.14)`,
    },
    dark: {
      canvas: hslToHex(baseHue, 35, 8),
      paper: hslToHex(baseHue, 30, 14),
      ink: hslToHex(baseHue, 15, 96),
      muted: hslToHex(baseHue, 15, 65),
      line: hslToHex(baseHue, 22, 24),
      wave1: `hsla(${baseHue}, 75%, 45%, 0.35)`,
      wave2: `hsla(${secondaryHue}, 75%, 55%, 0.22)`,
      wave3: `hsla(${accentHue}, 80%, 60%, 0.14)`,
    },
  };
}

/**
 * Apply realtime palette CSS custom variables to document root
 */
export function applyRealtimePalette(palette, isDark = false) {
  if (!palette) return;
  const root = document.documentElement;
  const themeMode = isDark ? palette.dark : palette.light;

  root.style.setProperty('--primary', palette.primary);
  root.style.setProperty('--primary-hover', palette.primaryHover || palette.primary);
  root.style.setProperty('--secondary', palette.secondary);
  root.style.setProperty('--accent', palette.accent);

  root.style.setProperty('--canvas', themeMode.canvas);
  root.style.setProperty('--paper', themeMode.paper);
  root.style.setProperty('--ink', themeMode.ink);
  root.style.setProperty('--muted', themeMode.muted);
  root.style.setProperty('--line', themeMode.line);

  root.style.setProperty('--haikei-wave-1', themeMode.wave1);
  root.style.setProperty('--haikei-wave-2', themeMode.wave2);
  root.style.setProperty('--haikei-wave-3', themeMode.wave3);

  // Soft tinted elements
  root.style.setProperty('--primary-soft', `${palette.primary}18`);
  root.style.setProperty('--secondary-soft', `${palette.secondary}22`);
  root.style.setProperty('--accent-soft', `${palette.accent}20`);

  // Active glow
  root.style.setProperty('--primary-glow', `${palette.primary}40`);
  root.style.setProperty('--accent-glow', `${palette.accent}55`);
}

/**
 * Pulse real-time alert color on the root element during sound events
 */
export function triggerRealtimeAlertColor(category = 'Doorbell') {
  const root = document.documentElement;
  const alertColors = {
    Doorbell: { glow: '#f59e0b', wave: 'rgba(245, 158, 11, 0.45)' },
    Alarm: { glow: '#ef4444', wave: 'rgba(239, 68, 68, 0.50)' },
    Siren: { glow: '#dc2626', wave: 'rgba(220, 38, 38, 0.55)' },
    Knocking: { glow: '#eab308', wave: 'rgba(234, 179, 8, 0.45)' },
    Timer: { glow: '#06b6d4', wave: 'rgba(6, 182, 212, 0.45)' },
    Other: { glow: '#8b5cf6', wave: 'rgba(139, 92, 246, 0.45)' },
  };

  const choice = alertColors[category] || alertColors.Other;
  root.style.setProperty('--alert-pulse-glow', choice.glow);
  root.style.setProperty('--alert-pulse-wave', choice.wave);
  root.classList.add('realtime-alert-active');

  setTimeout(() => {
    root.classList.remove('realtime-alert-active');
  }, 2200);
}
