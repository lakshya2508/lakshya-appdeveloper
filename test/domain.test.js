import { describe, expect, it } from 'vitest';
import { filterHistory, parseRecord } from '../src/domain.js';

describe('record model', () => {
  it('normalizes valid timestamps and rejects malformed records', () => {
    expect(parseRecord({ id:'1', type:'caption', text:'Hello', timestamp:'2026-10-12T10:00:00Z' }).timestamp).toBe('2026-10-12T10:00:00.000Z');
    expect(parseRecord({ id:1, type:'caption', text:'Hello', timestamp:'bad' })).toBeNull();
  });
  it('filters by text, category, and kind', () => {
    const rows=[{text:'Meeting starts',category:'',type:'caption'},{text:'Sample siren',category:'Siren',type:'alert'}];
    expect(filterHistory(rows,'siren','alert')).toHaveLength(1);
    expect(filterHistory(rows,'meeting','alert')).toHaveLength(0);
    expect(filterHistory(rows,'')).toHaveLength(2);
  });
});
