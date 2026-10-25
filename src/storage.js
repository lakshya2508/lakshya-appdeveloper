import { DEFAULT_SETTINGS, parseRecord } from './domain.js';

const safeRead = (key, fallback) => {
  try { const value = localStorage.getItem(key); return value ? JSON.parse(value) : fallback; } catch { return fallback; }
};
const safeWrite = (key, value) => { try { localStorage.setItem(key, JSON.stringify(value)); return true; } catch { return false; } };

export const store = {
  getSettings() {
    const saved = safeRead('hearassist.settings', {});
    return { ...DEFAULT_SETTINGS, ...saved, categories: { ...DEFAULT_SETTINGS.categories, ...(saved.categories || {}) } };
  },
  saveSettings(settings) { return safeWrite('hearassist.settings', settings); },
  getHistory() { return safeRead('hearassist.history', []).map(parseRecord).filter(Boolean).sort((a, b) => b.timestamp.localeCompare(a.timestamp)); },
  addRecord(record) { const rows = this.getHistory(); rows.unshift(parseRecord(record)); return safeWrite('hearassist.history', rows.filter(Boolean).slice(0, 200)); },
  clearHistory() { return safeWrite('hearassist.history', []); },
  hasOnboarded() { try { return localStorage.getItem('hearassist.onboarded') === 'true'; } catch { return true; } },
  completeOnboarding() { try { localStorage.setItem('hearassist.onboarded', 'true'); } catch {} },
};
