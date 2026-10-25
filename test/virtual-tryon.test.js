// @vitest-environment jsdom
import { describe, it, expect, beforeEach, vi } from 'vitest';
import {
  TRYON_CATALOG,
  SAMPLE_AVATARS,
  tryonStore,
  tryonState,
  filterCatalog,
  renderVirtualTryOn,
  executeVirtualTryOn,
} from '../src/virtual-tryon.js';

describe('Virtual Try-On Web Module', () => {
  beforeEach(() => {
    localStorage.clear();
    tryonState.viewMode = 'tryon';
    tryonState.selectedCategory = 'all';
    tryonState.selectedItem = TRYON_CATALOG[0];
    tryonState.hasResult = false;
    tryonState.isGenerating = false;
  });

  describe('Catalog & Avatars', () => {
    it('contains valid catalog items matching reference repo', () => {
      expect(TRYON_CATALOG.length).toBeGreaterThanOrEqual(3);
      const sunglass = TRYON_CATALOG.find(i => i.id === 'sunglass');
      const helmet = TRYON_CATALOG.find(i => i.id === 'helmet');
      const shoe = TRYON_CATALOG.find(i => i.id === 'shoe');

      expect(sunglass).toBeDefined();
      expect(sunglass.category).toBe('eyewear');
      expect(sunglass.glb).toBe('/assets/rayban_sunglasses.glb');

      expect(helmet).toBeDefined();
      expect(helmet.category).toBe('headwear');
      expect(helmet.glb).toBe('/assets/helmet.glb');

      expect(shoe).toBeDefined();
      expect(shoe.category).toBe('footwear');
      expect(shoe.glb).toBe('/assets/shoe.glb');
    });

    it('filters catalog accurately by category', () => {
      expect(filterCatalog('all').length).toBe(TRYON_CATALOG.length);
      const eyewear = filterCatalog('eyewear');
      expect(eyewear.every(i => i.category === 'eyewear')).toBe(true);
      const footwear = filterCatalog('footwear');
      expect(footwear.every(i => i.category === 'footwear')).toBe(true);
    });

    it('contains sample avatars for quick testing', () => {
      expect(SAMPLE_AVATARS.length).toBeGreaterThanOrEqual(3);
      expect(SAMPLE_AVATARS[0].name).toContain('Alex');
    });
  });

  describe('Storage & Config', () => {
    it('persists and retrieves custom API endpoint and token', () => {
      expect(tryonStore.getEndpoint()).toBe('');
      tryonStore.saveEndpoint('https://api.replicate.com/v1/try-on');
      tryonStore.saveToken('token_xyz_123');

      expect(tryonStore.getEndpoint()).toBe('https://api.replicate.com/v1/try-on');
      expect(tryonStore.getToken()).toBe('token_xyz_123');
    });

    it('stores and clears try-on history sessions', () => {
      const session = {
        id: 'sess-1',
        itemName: 'Aviator Glasses',
        engine: 'Local Neural Warp Engine',
        timestamp: new Date().toISOString(),
        durationMs: 320,
      };

      tryonStore.saveSession(session);
      expect(tryonStore.getSessions().length).toBe(1);
      expect(tryonStore.getSessions()[0].itemName).toBe('Aviator Glasses');

      tryonStore.clearSessions();
      expect(tryonStore.getSessions().length).toBe(0);
    });
  });

  describe('HTML Rendering', () => {
    it('renders hero, mode switcher, person dropzone, and split slider', () => {
      const html = renderVirtualTryOn();

      expect(html).toContain('VIRTUAL TRY-ON STUDIO');
      expect(html).toContain('AI Virtual Try-On');
      expect(html).toContain('3D Spatial Orbit');
      expect(html).toContain('Person Image');
      expect(html).toContain('Garment & Accessory');
      expect(html).toContain('Generate Virtual Try-On');
      expect(html).toContain('split-slider-viewport');
      expect(html).toContain('AFTER (TRY-ON)');
      expect(html).toContain('BEFORE (ORIGINAL)');
    });

    it('renders 3D spatial orbit view when mode is 3d', () => {
      tryonState.viewMode = '3d';
      const html = renderVirtualTryOn();

      expect(html).toContain('SPATIAL 3D MESH VIEWER');
      expect(html).toContain('tryon3dCanvas');
      expect(html).toContain('Orbit');
      expect(html).toContain('Wireframe');
    });
  });

  describe('Execution Pipeline', () => {
    it('simulates local multi-stage neural synthesis with progress callbacks', async () => {
      const progressList = [];
      const stageList = [];

      await new Promise(resolve => {
        executeVirtualTryOn(
          (prog, stage) => {
            progressList.push(prog);
            stageList.push(stage);
          },
          session => {
            expect(session.engine).toBe('Local Neural Warp Engine');
            expect(session.durationMs).toBeGreaterThanOrEqual(0);
            expect(tryonState.hasResult).toBe(true);
            resolve();
          }
        );
      });

      expect(progressList.length).toBeGreaterThan(1);
      expect(progressList[progressList.length - 1]).toBe(100);
      expect(tryonStore.getSessions().length).toBe(1);
    });
  });
});
