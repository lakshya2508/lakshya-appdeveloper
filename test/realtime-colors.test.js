import { describe, expect, it } from 'vitest';
import {
  hexToRgb,
  getRelativeLuminance,
  getContrastRatio,
  evaluateContrast,
  generateRandomHarmonicPalette,
  CURATED_PALETTES,
} from '../src/realtime-colors.js';

describe('Realtime Colors Engine', () => {
  it('converts hex strings to correct RGB tuples', () => {
    expect(hexToRgb('#ffffff')).toEqual([255, 255, 255]);
    expect(hexToRgb('#000000')).toEqual([0, 0, 0]);
    expect(hexToRgb('#fff')).toEqual([255, 255, 255]);
    expect(hexToRgb('#0c7770')).toEqual([12, 119, 112]);
  });

  it('calculates accurate relative luminance and contrast ratio', () => {
    const whiteLum = getRelativeLuminance([255, 255, 255]);
    const blackLum = getRelativeLuminance([0, 0, 0]);
    expect(whiteLum).toBeCloseTo(1, 1);
    expect(blackLum).toBeCloseTo(0, 1);

    const maxContrast = getContrastRatio('#ffffff', '#000000');
    expect(maxContrast).toBeCloseTo(21, 0);

    const minContrast = getContrastRatio('#ffffff', '#ffffff');
    expect(minContrast).toBeCloseTo(1, 1);
  });

  it('correctly rates contrast compliant with WCAG guidelines', () => {
    const high = evaluateContrast('#000000', '#ffffff');
    expect(high.passAA).toBe(true);
    expect(high.passAAA).toBe(true);
    expect(high.rating).toBe('AAA');

    const low = evaluateContrast('#aaaaaa', '#ffffff');
    expect(low.passAAA).toBe(false);
  });

  it('generates harmonic accessible palettes', () => {
    const generated = generateRandomHarmonicPalette();
    expect(generated.primary).toMatch(/^#[0-9a-f]{6}$/i);
    expect(generated.secondary).toMatch(/^#[0-9a-f]{6}$/i);
    expect(generated.accent).toMatch(/^#[0-9a-f]{6}$/i);
    expect(generated.light.canvas).toBeDefined();
    expect(generated.dark.canvas).toBeDefined();
  });

  it('provides all curated palettes with proper themes', () => {
    expect(CURATED_PALETTES.aurora).toBeDefined();
    expect(CURATED_PALETTES.violet).toBeDefined();
    expect(CURATED_PALETTES.coral).toBeDefined();
    expect(CURATED_PALETTES.azure).toBeDefined();
    expect(CURATED_PALETTES.jade).toBeDefined();
    expect(CURATED_PALETTES.highContrast).toBeDefined();
  });
});
