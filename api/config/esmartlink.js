const crypto = require('crypto');

const ESMARTLINK_BASE_URL = (
    process.env.ESMARTLINK_BASE_URL || 'https://payment-service-sbx.pakar-digital.com'
).trim().replace(/\/+$/, '');

const getBasicAuthHeader = () => {
    const username = (process.env.ESMARTLINK_USERNAME || '').trim();
    const password = (process.env.ESMARTLINK_PASSWORD || '').trim();

    if (!username || !password) {
        throw new Error('ESMARTLINK_USERNAME atau ESMARTLINK_PASSWORD belum diset');
    }

    const encoded = Buffer.from(`${username}:${password}`).toString('base64');
    return `Basic ${encoded}`;
};

const buildEsmartlinkUrl = (path) => {
    const normalizedPath = path.startsWith('/') ? path : `/${path}`;
    return `${ESMARTLINK_BASE_URL}${normalizedPath}`;
};

const esmartlinkRequest = async ({ path, method = 'GET', body }) => {
    const headers = {
        Authorization: getBasicAuthHeader(),
        'Content-Type': 'application/json',
        Accept: 'application/json'
    };

    const response = await fetch(buildEsmartlinkUrl(path), {
        method,
        headers,
        ...(body ? { body: JSON.stringify(body) } : {})
    });

    const rawText = await response.text();
    let parsed;

    try {
        parsed = rawText ? JSON.parse(rawText) : {};
    } catch (error) {
        parsed = { message: rawText };
    }

    // E-Smartlink kadang mengembalikan error business di body meskipun HTTP 200
    const bodyCode = typeof parsed?.code === 'number' ? parsed.code : null;
    const bodyStatus = String(parsed?.status || '').toLowerCase();
    const hasBusinessError =
        (bodyCode !== null && bodyCode !== 0) ||
        (bodyStatus && bodyStatus !== 'success');

    if (!response.ok) {
        const baseMessage = parsed.message || `HTTP ${response.status}`;
        if (response.status === 401 || response.status === 403 || baseMessage.toLowerCase().includes('authorization')) {
            throw new Error(
                `Authorization Failed (HTTP ${response.status}). Cek ESMARTLINK_USERNAME/ESMARTLINK_PASSWORD di .env, pastikan tanpa spasi/quote, lalu restart backend.`
            );
        }
        throw new Error(`${baseMessage} (HTTP ${response.status})`);
    }

    if (hasBusinessError) {
        if ((parsed.message || '').toLowerCase().includes('authorization')) {
            throw new Error(
                `Authorization Failed (code ${parsed.code ?? '-'}). Cek ESMARTLINK_USERNAME/ESMARTLINK_PASSWORD di .env, pastikan tanpa spasi/quote, lalu restart backend.`
            );
        }
        throw new Error(parsed.message || 'Gateway mengembalikan response error');
    }

    return parsed;
};

const calculateCallbackSignature = (payload) => {
    const emailCredential = process.env.ESMARTLINK_EMAIL_CREDENTIAL || '';
    const raw = `${payload.order_id || ''}${payload.amount || ''}${payload.channel || ''}${payload.transaction_time || ''}${emailCredential}`;
    return crypto.createHash('sha256').update(raw).digest('hex');
};

const verifyCallbackSignature = (payload) => {
    if (!process.env.ESMARTLINK_EMAIL_CREDENTIAL) {
        return true;
    }

    if (!payload.signature) {
        return false;
    }

    const expectedSignature = calculateCallbackSignature(payload);
    return expectedSignature === payload.signature;
};

module.exports = {
    esmartlinkRequest,
    verifyCallbackSignature
};
