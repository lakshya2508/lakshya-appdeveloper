// @vitest-environment jsdom
import { beforeEach, describe, expect, it } from 'vitest';
import { store } from '../src/storage.js';

beforeEach(() => localStorage.clear());

describe('local storage adapter', () => {
  it('loads defaults and merges partial saved settings', () => {
    expect(store.getSettings().theme).toBe('system');
    store.saveSettings({ theme:'dark', categories:{ Siren:false } });
    expect(store.getSettings()).toMatchObject({ theme:'dark', categories:{ Siren:false, Doorbell:true } });
  });
  it('persists records newest first and clears them', () => {
    store.addRecord({ id:'old',type:'caption',text:'Older',timestamp:'2026-10-10T10:00:00Z' });
    store.addRecord({ id:'new',type:'alert',text:'Newer',category:'Alarm',timestamp:'2026-10-11T10:00:00Z' });
    expect(store.getHistory().map(row=>row.id)).toEqual(['new','old']);
    store.clearHistory();
    expect(store.getHistory()).toEqual([]);
  });
});
