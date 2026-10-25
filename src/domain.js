export const DEFAULT_SETTINGS = Object.freeze({
  theme: 'system', palette: 'aurora', customColors: null, textScale: 1, highContrast: false, reducedMotion: false,
  vibration: false, retention: true,
  categories: { Doorbell: true, Alarm: true, Siren: true, Knocking: true, Timer: true, Other: true },
});

export function parseRecord(value) {
  if (!value || typeof value !== 'object' || typeof value.id !== 'string' || typeof value.type !== 'string' || typeof value.text !== 'string') return null;
  const time = new Date(value.timestamp);
  if (!Number.isFinite(time.getTime())) return null;
  return { id: value.id, type: value.type, text: value.text, timestamp: time.toISOString(), category: String(value.category || '') };
}

export function filterHistory(records, query = '', type = 'all') {
  const needle = query.trim().toLowerCase();
  return records.filter(row => (type === 'all' || row.type === type) && (!needle || `${row.text} ${row.category}`.toLowerCase().includes(needle)));
}

export function formatTime(value) {
  return new Intl.DateTimeFormat(undefined, { hour: 'numeric', minute: '2-digit' }).format(new Date(value));
}
