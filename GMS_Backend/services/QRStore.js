
class QRStore {
  constructor() {
    this.map = new Map();
  }

  async set(key, value, ttlSeconds = 120) {
    if (!key) throw new Error('key required');
    const now = Date.now();
    const expireAt = now + (ttlSeconds * 1000);

    // clear existing timer
    const existing = this.map.get(key);
    if (existing && existing.timer) clearTimeout(existing.timer);

    const timer = setTimeout(() => {
      this.map.delete(key);
    }, ttlSeconds * 1000);
    // unref so timers don't keep node process alive in tests
    if (timer.unref) try { timer.unref(); } catch (_) {}

    this.map.set(key, { value, expireAt, timer });
    return true;
  }

  async get(key) {
    const entry = this.map.get(key);
    if (!entry) return null;
    if (Date.now() > entry.expireAt) {
      // expired - cleanup
      if (entry.timer) clearTimeout(entry.timer);
      this.map.delete(key);
      return null;
    }
    return entry.value;
  }

  async del(key) {
    const entry = this.map.get(key);
    if (!entry) return false;
    if (entry.timer) clearTimeout(entry.timer);
    this.map.delete(key);
    return true;
  }
}

module.exports = new QRStore();
