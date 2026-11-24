// Sends a real push (FCM) for every document the dashboard writes to `notifications/{id}`,
// so customers get it even when the store app is closed. Requires the Blaze plan.
//
// Recipients:
//   target == 'all' and no targetEmail  -> every user with a device token
//   target == <uid>                      -> that user
//   targetEmail == <email>               -> users with that email (older orders have no uid)
// Each user gets the Arabic or English text according to `Users/{uid}.lang`.

const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { onCall, onRequest, HttpsError } = require('firebase-functions/v2/https');
const { logger } = require('firebase-functions');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();
const db = getFirestore();

const TAP_API = 'https://api.tap.company/v2';
const MOYASAR_API = 'https://api.moyasar.com/v1';

async function loadPaymentConfig() {
  const snap = await db.collection('store_settings').doc('payment_config').get();
  return snap.exists ? snap.data() || {} : {};
}

async function loadPaymentSecrets() {
  const snap = await db.collection('private_settings').doc('payment_secrets').get();
  if (!snap.exists) {
    throw new HttpsError('failed-precondition', 'payment_secrets_missing');
  }
  return snap.data() || {};
}

function pickSecret(secrets, { sandbox, platform }) {
  const isIos = platform === 'ios';
  const raw = sandbox
    ? (isIos ? secrets.secretKeyTestIos : secrets.secretKeyTestAndroid) ||
      secrets.secretKeyTest ||
      ''
    : (isIos ? secrets.secretKeyLiveIos : secrets.secretKeyLiveAndroid) ||
      secrets.secretKeyLive ||
      '';
  return `${raw}`.trim();
}

/** goSell mobile SDK expects sk_* secret keys bound to the app package — not pk_*. */
function assertGoSellSecret(secretKey, { sandbox, platform }) {
  if (!secretKey) {
    throw new HttpsError('failed-precondition', 'secret_missing');
  }
  if (secretKey.startsWith('pk_')) {
    throw new HttpsError(
      'failed-precondition',
      'tap_secret_is_publishable: put sk_test_/sk_live_ in payment_secrets, not pk_*',
    );
  }
  const expected = sandbox ? 'sk_test_' : 'sk_live_';
  if (!secretKey.startsWith(expected)) {
    throw new HttpsError(
      'failed-precondition',
      `tap_secret_prefix_mismatch: expected ${expected}* for ${platform} (${sandbox ? 'sandbox' : 'live'})`,
    );
  }
}

async function tapFetch(path, secret, { method = 'GET', body } = {}) {
  const res = await fetch(`${TAP_API}${path}`, {
    method,
    headers: {
      Authorization: `Bearer ${secret}`,
      'Content-Type': 'application/json',
      Accept: 'application/json',
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const json = await res.json().catch(() => ({}));
  if (!res.ok) {
    const msg = json?.errors?.[0]?.description || json?.message || `tap_http_${res.status}`;
    const err = new Error(msg);
    err.status = res.status;
    err.payload = json;
    throw err;
  }
  return json;
}

// Must match the Firestore database location (us-central1 works for the default "nam5").
const REGION = 'us-central1';
const FCM_BATCH = 500;
const STALE_TOKEN_ERRORS = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
  'messaging/invalid-argument',
]);

function tokensOf(user) {
  const tokens = new Set(Array.isArray(user.fcmTokens) ? user.fcmTokens : []);
  if (user.fcmToken) tokens.add(user.fcmToken);
  return [...tokens].filter((t) => typeof t === 'string' && t.length > 0);
}

async function recipients(data) {
  const target = data.target || 'all';
  const email = (data.targetEmail || '').trim().toLowerCase();
  const users = db.collection('Users');
  if (target === 'all' && !email) return (await users.get()).docs;
  if (target !== 'all') {
    const doc = await users.doc(target).get();
    if (doc.exists) return [doc];
  }
  if (!email) return [];
  const byEmail = await users.where('email', '==', data.targetEmail.trim()).get();
  return byEmail.docs;
}

exports.sendAdminPush = onDocumentCreated({ document: 'notifications/{id}', region: REGION }, async (event) => {
  const snap = event.data;
  if (!snap) return;
  const data = snap.data();
  const docs = await recipients(data);

  // token -> { ref, lang }
  const owners = new Map();
  for (const doc of docs) {
    const user = doc.data();
    const lang = user.lang === 'en' ? 'en' : 'ar';
    for (const token of tokensOf(user)) owners.set(token, { ref: doc.ref, lang });
  }

  const text = {
    ar: { title: data.titleAr || data.title || '', body: data.bodyAr || data.body || '' },
    en: { title: data.title || data.titleAr || '', body: data.body || data.bodyAr || '' },
  };
  const payloadData = { notificationId: event.params.id, type: String(data.type || ''), orderId: String(data.orderId || '') };

  let success = 0;
  let failure = 0;
  const stale = [];
  for (const lang of ['ar', 'en']) {
    const tokens = [...owners.entries()].filter(([, o]) => o.lang === lang).map(([t]) => t);
    for (let i = 0; i < tokens.length; i += FCM_BATCH) {
      const chunk = tokens.slice(i, i + FCM_BATCH);
      const response = await getMessaging().sendEachForMulticast({
        tokens: chunk,
        notification: text[lang],
        data: payloadData,
        android: { priority: 'high', notification: { sound: 'default' } },
        apns: { payload: { aps: { sound: 'default' } } },
      });
      success += response.successCount;
      failure += response.failureCount;
      response.responses.forEach((r, index) => {
        if (!r.success && r.error && STALE_TOKEN_ERRORS.has(r.error.code)) stale.push(chunk[index]);
      });
    }
  }

  await Promise.all(
    stale.map((token) =>
      owners.get(token).ref.update({ fcmTokens: FieldValue.arrayRemove(token) }).catch(() => null),
    ),
  );
  await snap.ref.update({ push: { sentAt: FieldValue.serverTimestamp(), success, failure, removedTokens: stale.length } });
  // Tells the store app to stop showing these as local notifications (avoids duplicates).
  await db.collection('config').doc('app').set({ pushEnabled: true }, { merge: true });
  logger.info('admin push sent', { id: event.params.id, recipients: docs.length, success, failure, stale: stale.length });
});

/// Every minute: find drops whose launchAt has passed, notify reminder subscribers, mark live.
exports.sendDropLaunchPush = onSchedule({ schedule: 'every 1 minutes', region: REGION }, async () => {
  const now = new Date();
  const due = await db
    .collection('drops')
    .where('status', '==', 'scheduled')
    .where('launchAt', '<=', now)
    .get();

  for (const dropDoc of due.docs) {
    const data = dropDoc.data() || {};
    if (data.pushSentAt) continue;

    const reminders = await dropDoc.ref.collection('reminders').get();
    const owners = new Map();
    for (const reminder of reminders.docs) {
      const uid = reminder.id;
      const userDoc = await db.collection('Users').doc(uid).get();
      if (!userDoc.exists) continue;
      const user = userDoc.data() || {};
      const lang = user.lang === 'en' ? 'en' : 'ar';
      for (const token of tokensOf(user)) owners.set(token, { ref: userDoc.ref, lang });
    }

    const titleAr = data.titleAr || data.title || 'الإطلاق بدأ';
    const titleEn = data.title || data.titleAr || 'The drop is live';
    const text = {
      ar: { title: titleAr, body: 'المجموعة متاحة الآن في التطبيق — تسوّق قبل نفاد القطع' },
      en: { title: titleEn, body: 'The collection is live in the app — shop before it sells out' },
    };
    const payloadData = { type: 'drop_launch', dropId: dropDoc.id };

    let success = 0;
    let failure = 0;
    const stale = [];
    for (const lang of ['ar', 'en']) {
      const tokens = [...owners.entries()].filter(([, o]) => o.lang === lang).map(([t]) => t);
      for (let i = 0; i < tokens.length; i += FCM_BATCH) {
        const chunk = tokens.slice(i, i + FCM_BATCH);
        if (chunk.length === 0) continue;
        const response = await getMessaging().sendEachForMulticast({
          tokens: chunk,
          notification: text[lang],
          data: payloadData,
          android: { priority: 'high', notification: { sound: 'default' } },
          apns: { payload: { aps: { sound: 'default' } } },
        });
        success += response.successCount;
        failure += response.failureCount;
        response.responses.forEach((r, index) => {
          if (!r.success && r.error && STALE_TOKEN_ERRORS.has(r.error.code)) stale.push(chunk[index]);
        });
      }
    }

    await Promise.all(
      stale.map((token) => owners.get(token).ref.update({ fcmTokens: FieldValue.arrayRemove(token) }).catch(() => null)),
    );
    await dropDoc.ref.update({
      status: 'live',
      pushSentAt: FieldValue.serverTimestamp(),
      push: { success, failure, removedTokens: stale.length },
    });
    logger.info('drop launch push sent', { id: dropDoc.id, reminders: reminders.size, success, failure });
  }
});

async function sendDirectPush({ userDocs, titleAr, titleEn, bodyAr, bodyEn, data }) {
  const owners = new Map();
  for (const doc of userDocs) {
    if (!doc.exists) continue;
    const user = doc.data() || {};
    const lang = user.lang === 'en' ? 'en' : 'ar';
    for (const token of tokensOf(user)) owners.set(token, { ref: doc.ref, lang });
  }
  const text = {
    ar: { title: titleAr, body: bodyAr },
    en: { title: titleEn, body: bodyEn },
  };
  let success = 0;
  let failure = 0;
  const stale = [];
  for (const lang of ['ar', 'en']) {
    const tokens = [...owners.entries()].filter(([, o]) => o.lang === lang).map(([t]) => t);
    for (let i = 0; i < tokens.length; i += FCM_BATCH) {
      const chunk = tokens.slice(i, i + FCM_BATCH);
      if (chunk.length === 0) continue;
      const response = await getMessaging().sendEachForMulticast({
        tokens: chunk,
        notification: text[lang],
        data: Object.fromEntries(Object.entries(data || {}).map(([k, v]) => [k, String(v ?? '')])),
        android: { priority: 'high', notification: { sound: 'default' } },
        apns: { payload: { aps: { sound: 'default' } } },
      });
      success += response.successCount;
      failure += response.failureCount;
      response.responses.forEach((r, index) => {
        if (!r.success && r.error && STALE_TOKEN_ERRORS.has(r.error.code)) stale.push(chunk[index]);
      });
    }
  }
  await Promise.all(
    stale.map((token) => owners.get(token).ref.update({ fcmTokens: FieldValue.arrayRemove(token) }).catch(() => null)),
  );
  return { success, failure };
}

function stockMap(data) {
  const raw = data && data.stock && typeof data.stock === 'object' ? data.stock : {};
  const out = {};
  for (const [k, v] of Object.entries(raw)) out[k] = Number(v) || 0;
  return out;
}

/// When a size goes from 0 → >0, notify active waitlist shoppers and soft-link them to add-to-cart.
exports.onProductStockChange = onDocumentUpdated({ document: 'products/{id}', region: REGION }, async (event) => {
  const before = event.data.before.data() || {};
  const after = event.data.after.data() || {};
  const beforeStock = stockMap(before);
  const afterStock = stockMap(after);
  const restocked = [];
  for (const size of new Set([...Object.keys(beforeStock), ...Object.keys(afterStock)])) {
    if ((beforeStock[size] || 0) <= 0 && (afterStock[size] || 0) > 0) restocked.push(size);
  }
  if (restocked.length === 0) return;

  const productId = `${after.productid || event.params.id}`;
  const nameAr = after.nameAr || after.name || productId;
  const nameEn = after.name || after.nameAr || productId;

  for (const size of restocked) {
    const wait = await db
      .collection('stockWaitlist')
      .where('productId', '==', productId)
      .where('size', '==', size)
      .where('active', '==', true)
      .get();
    if (wait.empty) continue;

    const userDocs = [];
    for (const w of wait.docs) {
      const uid = w.data().uid;
      if (!uid) continue;
      const userDoc = await db.collection('Users').doc(uid).get();
      if (userDoc.exists) userDocs.push(userDoc);
    }

    await sendDirectPush({
      userDocs,
      titleAr: 'مقاسك متوفر الآن',
      titleEn: 'Your size is back',
      bodyAr: `${nameAr} — المقاس ${size} عاد للمخزون. اضغطي للإضافة للسلة`,
      bodyEn: `${nameEn} — size ${size} is back in stock. Tap to add to bag`,
      data: { type: 'back_in_stock', productId, size },
    });

    const batch = db.batch();
    for (const w of wait.docs) {
      batch.update(w.ref, { active: false, notifiedAt: FieldValue.serverTimestamp() });
    }
    await batch.commit();
    logger.info('back-in-stock notified', { productId, size, count: wait.size });
  }
});

/// Abandoned cart recovery: gentle nudge at 2h, stronger at 24h.
exports.cartRecoverySchedule = onSchedule({ schedule: 'every 15 minutes', region: REGION }, async () => {
  const now = Date.now();
  const snap = await db.collection('cartSnapshots').where('itemCount', '>', 0).get();
  for (const doc of snap.docs) {
    const data = doc.data() || {};
    const updatedAt = data.updatedAt && data.updatedAt.toDate ? data.updatedAt.toDate().getTime() : 0;
    if (!updatedAt) continue;
    const ageMs = now - updatedAt;
    const uid = doc.id;
    const userDoc = await db.collection('Users').doc(uid).get();
    if (!userDoc.exists) continue;

    if (ageMs >= 2 * 60 * 60 * 1000 && !data.reminded2h) {
      await sendDirectPush({
        userDocs: [userDoc],
        titleAr: 'نسيتِ شيئاً في السلة؟',
        titleEn: 'Still in your bag?',
        bodyAr: 'قطعك بانتظارك — أكملي الطلب قبل نفاد المقاسات',
        bodyEn: 'Your pieces are waiting — finish checkout before sizes sell out',
        data: { type: 'cart_recovery', stage: '2h' },
      });
      await doc.ref.update({ reminded2h: true });
    }

    if (ageMs >= 24 * 60 * 60 * 1000 && !data.reminded24h) {
      await sendDirectPush({
        userDocs: [userDoc],
        titleAr: 'سلتك تنتظرك منذ يوم',
        titleEn: 'Your bag is still waiting',
        bodyAr: 'آخر تذكير — أكملي الطلب أو احفظي القطع للمفضلة',
        bodyEn: 'Last nudge — complete your order or save pieces to favorites',
        data: { type: 'cart_recovery', stage: '24h' },
      });
      await doc.ref.update({ reminded24h: true });
    }
  }
});

// ---------------------------------------------------------------------------
// Tap Payments
// ---------------------------------------------------------------------------
// go_sell_sdk_flutter requires secret keys in configureApp. Keys are NEVER
// hardcoded and NEVER stored in public Firestore. They are issued only to
// authenticated shoppers for a payment session, then charge status is verified
// server-side with the same private_settings secrets.

/**
 * Returns ephemeral SDK credentials for the current sandbox/live mode.
 * Auth required. Secrets are not persisted on the client by our code.
 */
exports.issueTapSdkSession = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'login_required');
  }
  const config = await loadPaymentConfig();
  if (!config.isTapEnabled) {
    throw new HttpsError('failed-precondition', 'tap_disabled');
  }
  const sandbox = config.isSandboxMode !== false;
  const platform = request.data?.platform === 'ios' ? 'ios' : 'android';
  const secrets = await loadPaymentSecrets();
  const secretKey = pickSecret(secrets, { sandbox, platform });
  assertGoSellSecret(secretKey, { sandbox, platform });

  const publishableKey = (
    sandbox ? config.publishableKeyTest || '' : config.publishableKeyLive || ''
  ).trim();

  const androidBundleId = `${config.androidBundleId || ''}`.trim();
  const iosBundleId = `${config.iosBundleId || ''}`.trim();

  logger.info('issueTapSdkSession', {
    uid: request.auth.uid,
    platform,
    sandbox,
    secretPrefix: secretKey.slice(0, 8),
    secretLen: secretKey.length,
    androidBundleId,
    iosBundleId,
  });

  return {
    sandbox,
    publishableKey,
    secretKey,
    merchantId: `${config.merchantId || ''}`.trim(),
    applePayMerchantId: `${config.applePayMerchantId || ''}`.trim(),
    currency: (config.currency || 'SAR').toUpperCase(),
    countryCode: (config.countryCode || 'SA').toUpperCase(),
    androidBundleId,
    iosBundleId,
    supportedMethods: Array.isArray(config.supportedMethods) ? config.supportedMethods : [],
  };
});

/**
 * Verifies a Tap charge with the secret key and marks payments/{id} captured.
 */
exports.verifyTapCharge = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'login_required');
  }
  const chargeId = `${request.data?.chargeId || ''}`.trim();
  const paymentDocId = `${request.data?.paymentDocId || ''}`.trim();
  const expectedAmount = Number(request.data?.amount || 0);
  if (!chargeId) {
    throw new HttpsError('invalid-argument', 'charge_id_required');
  }

  const config = await loadPaymentConfig();
  const sandbox = config.isSandboxMode !== false;
  const platform = request.data?.platform === 'ios' ? 'ios' : 'android';
  const secrets = await loadPaymentSecrets();
  const secretKey = pickSecret(secrets, { sandbox, platform });
  if (!secretKey) {
    throw new HttpsError('failed-precondition', 'secret_missing');
  }

  let charge;
  try {
    charge = await tapFetch(`/charges/${encodeURIComponent(chargeId)}`, secretKey);
  } catch (e) {
    logger.error('verifyTapCharge fetch failed', e);
    throw new HttpsError('internal', e.message || 'tap_verify_failed');
  }

  const status = `${charge.status || ''}`.toUpperCase();
  const amount = Number(charge.amount || 0);
  const currency = `${charge.currency || ''}`.toUpperCase();
  const expectedCurrency = `${config.currency || 'SAR'}`.toUpperCase();
  const captured = status === 'CAPTURED' || status === 'AUTHORIZED';

  if (expectedAmount > 0 && Math.abs(amount - expectedAmount) > 0.05) {
    throw new HttpsError('failed-precondition', 'amount_mismatch');
  }
  if (currency && expectedCurrency && currency !== expectedCurrency) {
    throw new HttpsError('failed-precondition', 'currency_mismatch');
  }

  const patch = {
    tapChargeId: chargeId,
    tapStatus: status,
    verifiedAt: FieldValue.serverTimestamp(),
    amount,
    currency: currency || expectedCurrency,
    status: captured ? 'captured' : 'failed',
    raw: {
      id: charge.id,
      status: charge.status,
      amount: charge.amount,
      currency: charge.currency,
      method: charge.source?.payment_method || charge.source?.method || '',
    },
  };

  if (paymentDocId) {
    const ref = db.collection('payments').doc(paymentDocId);
    const snap = await ref.get();
    if (snap.exists) {
      const data = snap.data() || {};
      if (data.userUid && data.userUid !== request.auth.uid && !(await isAdminUid(request.auth))) {
        throw new HttpsError('permission-denied', 'payment_owner_mismatch');
      }
      await ref.set(patch, { merge: true });
    }
  }

  return {
    ok: captured,
    status,
    amount,
    currency: currency || expectedCurrency,
    chargeId,
  };
});

async function isAdminUid(auth) {
  const email = `${auth?.token?.email || ''}`.trim().toLowerCase();
  if (!email) return false;
  const doc = await db.collection('admins').doc(email).get();
  return doc.exists;
}

/**
 * Tap webhook (configure postURL in GoSell session to this HTTPS endpoint).
 * Updates payments by charge id when present.
 */
exports.tapWebhook = onRequest({ region: REGION }, async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).send('method_not_allowed');
    return;
  }
  try {
    const body = typeof req.body === 'string' ? JSON.parse(req.body || '{}') : req.body || {};
    const chargeId = body.id || body.charge_id || body.object?.id;
    const status = `${body.status || body.object?.status || ''}`.toUpperCase();
    if (!chargeId) {
      res.status(400).json({ ok: false, error: 'missing_charge_id' });
      return;
    }
    const q = await db.collection('payments').where('tapChargeId', '==', chargeId).limit(1).get();
    const patch = {
      tapStatus: status,
      webhookAt: FieldValue.serverTimestamp(),
      status: status === 'CAPTURED' || status === 'AUTHORIZED' ? 'captured' : status.toLowerCase(),
    };
    if (!q.empty) {
      await q.docs[0].ref.set(patch, { merge: true });
    } else {
      await db.collection('payments').doc(String(chargeId)).set(
        {
          tapChargeId: chargeId,
          ...patch,
          source: 'webhook',
        },
        { merge: true },
      );
    }
    res.json({ ok: true });
  } catch (e) {
    logger.error('tapWebhook error', e);
    res.status(500).json({ ok: false });
  }
});

function pickMoyasarSecret(secrets, sandbox) {
  return `${sandbox ? secrets.moyasarSecretKeyTest || '' : secrets.moyasarSecretKeyLive || ''}`.trim();
}

/**
 * Confirms a Moyasar payment id with the secret key (never shipped to the app).
 * Auth required.
 */
exports.verifyMoyasarPayment = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'login_required');
  }
  const paymentId = `${request.data?.paymentId || ''}`.trim();
  const paymentDocId = `${request.data?.paymentDocId || ''}`.trim();
  const orderRef = `${request.data?.orderRef || ''}`.trim();
  const expectedAmountHalalas = Number(request.data?.expectedAmountHalalas || 0);
  if (!paymentId) {
    throw new HttpsError('invalid-argument', 'payment_id_required');
  }

  const config = await loadPaymentConfig();
  if (!config.isMoyasarEnabled) {
    throw new HttpsError('failed-precondition', 'moyasar_disabled');
  }
  const sandbox = config.isSandboxMode !== false;
  const secrets = await loadPaymentSecrets();
  const secret = pickMoyasarSecret(secrets, sandbox);
  if (!secret) {
    throw new HttpsError('failed-precondition', 'moyasar_secret_missing');
  }
  if (secret.startsWith('pk_')) {
    throw new HttpsError('failed-precondition', 'moyasar_secret_is_publishable');
  }

  const auth = Buffer.from(`${secret}:`).toString('base64');
  const res = await fetch(`${MOYASAR_API}/payments/${encodeURIComponent(paymentId)}`, {
    headers: {
      Authorization: `Basic ${auth}`,
      Accept: 'application/json',
    },
  });
  const body = await res.json().catch(() => ({}));
  if (!res.ok) {
    logger.warn('verifyMoyasarPayment fetch failed', {
      status: res.status,
      paymentId,
      message: body?.message,
    });
    throw new HttpsError('failed-precondition', body?.message || 'moyasar_fetch_failed');
  }

  const status = `${body.status || ''}`.toLowerCase();
  const amount = Number(body.amount || 0);
  if (expectedAmountHalalas > 0 && amount !== expectedAmountHalalas) {
    throw new HttpsError('failed-precondition', 'amount_mismatch');
  }

  const paid = status === 'paid' || status === 'captured';
  const patch = {
    gateway: 'moyasar',
    moyasarPaymentId: paymentId,
    moyasarStatus: status,
    amountHalalas: amount,
    currency: `${body.currency || config.currency || 'SAR'}`.toUpperCase(),
    orderRef: orderRef || null,
    verifiedAt: FieldValue.serverTimestamp(),
    status: paid ? 'paid' : status,
    userUid: request.auth.uid,
  };

  if (paymentDocId) {
    await db.collection('payments').doc(paymentDocId).set(patch, { merge: true });
  } else {
    await db.collection('payments').doc(paymentId).set(patch, { merge: true });
  }

  logger.info('verifyMoyasarPayment', {
    uid: request.auth.uid,
    paymentId,
    status,
    paid,
    amount,
  });

  return {
    ok: paid,
    status,
    paymentId,
    amount,
    currency: patch.currency,
  };
});

/**
 * Server-side VIP progress after a shop order is created.
 * Clients cannot write isVip / orderCount / vipSince (Firestore rules).
 */
exports.onOrderCreatedBumpVip = onDocumentCreated(
  { document: 'orders/{orderId}', region: REGION },
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const data = snap.data() || {};
    const uid = `${data.user_uid || ''}`.trim();
    if (!uid) {
      logger.info('onOrderCreatedBumpVip skip: no user_uid', { orderId: event.params.orderId });
      return;
    }

    let required = 2;
    try {
      const commerce = await db.collection('config').doc('commerce').get();
      const raw = commerce.data()?.vipOrdersRequired;
      if (typeof raw === 'number' && Number.isFinite(raw) && raw > 0) {
        required = Math.floor(raw);
      }
    } catch (err) {
      logger.warn('onOrderCreatedBumpVip commerce read failed', err);
    }

    const ref = db.collection('Users').doc(uid);
    await db.runTransaction(async (tx) => {
      const userSnap = await tx.get(ref);
      const existing = userSnap.exists ? userSnap.data() || {} : {};
      const current =
        typeof existing.orderCount === 'number'
          ? existing.orderCount
          : parseInt(`${existing.orderCount ?? 0}`, 10) || 0;
      const next = current + 1;
      const isVip = next >= required || existing.isVip === true;
      const patch = {
        orderCount: next,
        isVip,
        uid,
      };
      if (isVip && !existing.vipSince) {
        patch.vipSince = FieldValue.serverTimestamp();
      }
      tx.set(ref, patch, { merge: true });
    });

    logger.info('onOrderCreatedBumpVip', { uid, orderId: event.params.orderId, required });
  },
);

/**
 * One-shot: replace dummy category thumbnails with editorial fashion images.
 * Safe to call again — skips if store_settings/migrations.categoryImagesV1 is true.
 */
exports.migrateCategoryImagesOnce = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'login_required');
  }

  const flagRef = db.collection('store_settings').doc('migrations');
  const flagSnap = await flagRef.get();
  if (flagSnap.exists && flagSnap.data()?.categoryImagesV1 === true && !request.data?.force) {
    return { ok: true, skipped: true, reason: 'already_migrated' };
  }

  const images = {
    womens_clothing:
      'https://images.unsplash.com/photo-1483985988355-763728e1935b?auto=format&fit=crop&w=1200&q=80',
    womens_dresses:
      'https://images.unsplash.com/photo-1595777457583-95e059d581b8?auto=format&fit=crop&w=1200&q=80',
    womens_shoes:
      'https://images.unsplash.com/photo-1543163521-1a27263297a6?auto=format&fit=crop&w=1200&q=80',
    bags:
      'https://images.unsplash.com/photo-1584917865442-de89df76afd3?auto=format&fit=crop&w=1200&q=80',
    mens_shirts:
      'https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?auto=format&fit=crop&w=1200&q=80',
    mens_shoes:
      'https://images.unsplash.com/photo-1549298916-b41d501d3772?auto=format&fit=crop&w=1200&q=80',
    girls_dresses:
      'https://images.unsplash.com/photo-1518831959646-742c3a14ebf7?auto=format&fit=crop&w=1200&q=80',
    jewellery:
      'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?auto=format&fit=crop&w=1200&q=80',
    watches:
      'https://images.unsplash.com/photo-1523275335684-37898b6baf30?auto=format&fit=crop&w=1200&q=80',
    sunglasses:
      'https://images.unsplash.com/photo-1572635196237-14b3f281503f?auto=format&fit=crop&w=1200&q=80',
    beauty:
      'https://images.unsplash.com/photo-1596462502278-27bfdc403348?auto=format&fit=crop&w=1200&q=80',
    fragrances:
      'https://images.unsplash.com/photo-1541643600914-78b084683601?auto=format&fit=crop&w=1200&q=80',
  };

  const batch = db.batch();
  let updated = 0;
  for (const [id, image] of Object.entries(images)) {
    const ref = db.collection('cat').doc(id);
    batch.set(ref, { image, imageUpdatedAt: FieldValue.serverTimestamp() }, { merge: true });
    updated += 1;
  }
  batch.set(
    flagRef,
    { categoryImagesV1: true, categoryImagesAt: FieldValue.serverTimestamp() },
    { merge: true },
  );
  await batch.commit();

  logger.info('migrateCategoryImagesOnce', { uid: request.auth.uid, updated });
  return { ok: true, skipped: false, updated };
});
