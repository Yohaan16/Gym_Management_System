// services/FCMService.js
// ─────────────────────────────────────────────────────────────────────────────
// Sends push notifications via Firebase Cloud Messaging V1 API.
// Uses a Service Account JSON file for authentication (OAuth2 access token).
//
// FCM V1 API endpoint:
//   POST https://fcm.googleapis.com/v1/projects/{projectId}/messages:send
//
// Authentication:
//   Uses google-auth-library to generate a short-lived OAuth2 access token
//   from the service account credentials. Tokens are cached for 50 minutes
//   to avoid unnecessary re-authentication on every notification.
// ─────────────────────────────────────────────────────────────────────────────

const { GoogleAuth } = require('google-auth-library');
const path           = require('path');

const SERVICE_ACCOUNT_PATH = path.join(
  __dirname, '../config/firebase-service-account.json'
);
const PROJECT_ID = process.env.FIREBASE_PROJECT_ID;
const FCM_URL    = `https://fcm.googleapis.com/v1/projects/${PROJECT_ID}/messages:send`;

// ── Token cache — reuse access tokens for up to 50 minutes ───────────────────
let _cachedToken      = null;
let _tokenExpiresAt   = 0;

class FCMService {

  // ══════════════════════════════════════════════════════════════════════════
  // SEND TO ONE TOKEN
  // ══════════════════════════════════════════════════════════════════════════

  /**
   * Sends a push notification to a single FCM device token.
   *
   * @param {string} fcmToken  — the device's FCM registration token
   * @param {string} title     — notification title
   * @param {string} body      — notification body
   * @param {object} data      — optional key-value data payload (string values only)
   */
  static async sendToToken(fcmToken, title, body, data = {}) {
    if (!fcmToken) return;

    const accessToken = await this._getAccessToken();

    const message = {
      message: {
        token: fcmToken,
        notification: { title, body },
        android: {
          priority: 'high',
          notification: {
            sound:        'default',
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
          },
        },
        apns: {
          payload: {
            aps: { sound: 'default' },
          },
        },
        data: Object.fromEntries(
          Object.entries(data).map(([k, v]) => [k, String(v)])
        ),
      },
    };

    const response = await fetch(FCM_URL, {
      method:  'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type':  'application/json',
      },
      body: JSON.stringify(message),
    });

    if (!response.ok) {
      const err = await response.json();
      console.error('[FCM] Failed to send notification:', err);
      return null;
    }

    const result = await response.json();
    console.log('[FCM] Notification sent:', result.name);
    return result;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SEND TO MULTIPLE TOKENS
  // Sends to each token individually (FCM V1 does not support multicast
  // in the same way as legacy API — each message targets one token).
  // ══════════════════════════════════════════════════════════════════════════

  /**
   * Sends a push notification to multiple FCM device tokens.
   * Skips null/empty tokens silently.
   *
   * @param {string[]} fcmTokens — array of device FCM tokens
   * @param {string}   title
   * @param {string}   body
   * @param {object}   data      — optional data payload
   */
  static async sendToTokens(fcmTokens, title, body, data = {}) {
    const validTokens = fcmTokens.filter(Boolean);
    if (validTokens.length === 0) return;

    const results = await Promise.allSettled(
      validTokens.map(token => this.sendToToken(token, title, body, data))
    );

    const succeeded = results.filter(r => r.status === 'fulfilled').length;
    const failed    = results.filter(r => r.status === 'rejected').length;

    console.log(
      `[FCM] Batch complete: ${succeeded} sent, ${failed} failed ` +
      `out of ${validTokens.length} tokens.`
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GET ACCESS TOKEN
  // Uses google-auth-library to generate an OAuth2 access token from the
  // service account. Tokens are cached for 50 minutes.
  // ══════════════════════════════════════════════════════════════════════════

  static async _getAccessToken() {
    const now = Date.now();

    // Return cached token if still valid
    if (_cachedToken && now < _tokenExpiresAt) {
      return _cachedToken;
    }

    const auth  = new GoogleAuth({
      keyFile: SERVICE_ACCOUNT_PATH,
      scopes:  ['https://www.googleapis.com/auth/firebase.messaging'],
    });

    const client      = await auth.getClient();
    const tokenResult = await client.getAccessToken();

    _cachedToken    = tokenResult.token;
    _tokenExpiresAt = now + 50 * 60 * 1000; // cache for 50 minutes

    return _cachedToken;
  }
}

module.exports = FCMService;
