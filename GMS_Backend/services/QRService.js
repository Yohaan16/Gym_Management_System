const crypto = require('crypto');

const QRStore = require('./QRStore');

class QRService {
  static generateJTI() {
    return crypto.randomBytes(10).toString('hex');
  }
  static async generateToken(memberId, ttlSeconds = 120) {
    if (!memberId) throw new Error('memberId required');
    const now = Math.floor(Date.now() / 1000);
    const payload = {
      memberId: Number(memberId),
      iat: now,
      exp: now + Number(ttlSeconds),
      jti: this.generateJTI()
    };

    await QRStore.set(payload.jti, payload, Number(ttlSeconds));
    return { token: payload.jti, payload, expiresAt: new Date((payload.exp) * 1000).toISOString() };
  }

  static async verifyToken(token) {
    if (!token || typeof token !== 'string') return { valid: false, reason: 'invalid_token' };

    // short-id: hex-ish and relatively short (10 bytes -> 20 hex chars)
    if (/^[0-9a-f]{18,40}$/i.test(token)) {
      const payload = await QRStore.get(token);
      if (!payload) return { valid: false, reason: 'not_found_or_expired' };
      const now = Math.floor(Date.now() / 1000);
      if (payload.exp < now) return { valid: false, reason: 'expired', payload };
      return { valid: true, payload };
    }

    return { valid: true, payload };
  }
}
      
module.exports = QRService;
