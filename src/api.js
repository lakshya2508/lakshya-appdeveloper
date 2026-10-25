// Replace MockHistoryRepository with HttpHistoryRepository when a real service exists.
// No live endpoint or remote transmission is configured in this portfolio prototype.
export class MockHistoryRepository {
  async list() { return []; }
  async create(record) { return { ...record }; }
}

export class HttpHistoryRepository {
  constructor(baseUrl) { this.baseUrl = baseUrl.replace(/\/$/, ''); }
  async request(path, options = {}) {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 8000);
    try {
      const response = await fetch(`${this.baseUrl}${path}`, { ...options, signal: controller.signal, headers: { 'Content-Type': 'application/json', ...options.headers } });
      if (!response.ok) throw new Error(`Service returned HTTP ${response.status}`);
      return response.status === 204 ? null : response.json();
    } finally { clearTimeout(timer); }
  }
  list() { return this.request('/records'); }
  create(record) { return this.request('/records', { method: 'POST', body: JSON.stringify(record) }); }
}
