/**
 * NFC Bridge Server — ACR122U → WebSocket → checkin.html
 * 
 * Jalankan dengan: node nfc-bridge.js
 * Server akan berjalan di ws://localhost:8765
 * 
 * Cara kerja:
 * 1. Mendengarkan koneksi dari reader NFC (ACR122U) via PC/SC (nfc-pcsc)
 * 2. Saat kartu/HP tertempel, baca UID kartu
 * 3. Kirim UID ke semua browser client yang connect via WebSocket
 * 4. Browser checkin.html menerima UID dan lakukan lookup + check-in
 */

const { NFC } = require('nfc-pcsc');
const WebSocket = require('ws');

const WS_PORT = 8765;

// ─── WebSocket Server ──────────────────────────────────────────────────────────
const wss = new WebSocket.Server({ port: WS_PORT });
const clients = new Set();

wss.on('connection', (ws) => {
    clients.add(ws);
    console.log(`[WS] Browser terhubung. Total client: ${clients.size}`);

    // Kirim status bahwa NFC bridge sudah aktif
    ws.send(JSON.stringify({ type: 'status', message: 'NFC Bridge aktif. Menunggu kartu...' }));

    ws.on('close', () => {
        clients.delete(ws);
        console.log(`[WS] Browser terputus. Total client: ${clients.size}`);
    });

    ws.on('error', (err) => {
        console.error('[WS] Error client:', err.message);
        clients.delete(ws);
    });
});

wss.on('listening', () => {
    console.log(`\n✅ NFC Bridge WebSocket berjalan di ws://localhost:${WS_PORT}`);
    console.log('   Hubungkan browser checkin.html ke server ini');
    console.log('   Pastikan ACR122U sudah tercolok ke USB\n');
});

// ─── Broadcast ke semua browser yang terhubung ─────────────────────────────────
function broadcast(data) {
    const json = JSON.stringify(data);
    clients.forEach((ws) => {
        if (ws.readyState === WebSocket.OPEN) {
            ws.send(json);
        }
    });
}

// ─── NFC Reader (ACR122U via nfc-pcsc) ────────────────────────────────────────
const nfc = new NFC();

nfc.on('reader', (reader) => {
    console.log(`[NFC] Reader terdeteksi: ${reader.name}`);
    broadcast({ type: 'reader_connected', reader: reader.name });

    reader.on('card', (card) => {
        // UID kartu dalam format hex, contoh: "04A3B2C1D2E3F4"
        const rawUid = card.uid;

        // Konversi UID hex ke format desimal 10 digit (sesuai format nfc_id di DB)
        // Ambil 4 byte pertama dari UID dan jadikan integer
        const hexPart = rawUid.replace(/\s/g, '').slice(0, 8); // 4 byte = 8 hex char
        const numericId = parseInt(hexPart, 16).toString().padStart(10, '0');

        console.log(`\n[NFC] Kartu terdeteksi!`);
        console.log(`      UID (hex)  : ${rawUid}`);
        console.log(`      NFC ID     : ${numericId}`);
        console.log(`      Dikirim ke : ${clients.size} browser\n`);

        broadcast({
            type: 'card_detected',
            uid_hex: rawUid,
            nfc_id: numericId,
            timestamp: new Date().toISOString(),
        });
    });

    reader.on('card.off', () => {
        console.log('[NFC] Kartu dilepas dari reader');
        broadcast({ type: 'card_removed' });
    });

    reader.on('error', (err) => {
        console.error('[NFC] Error reader:', err.message);
        broadcast({ type: 'error', message: `Error reader: ${err.message}` });
    });

    reader.on('end', () => {
        console.log(`[NFC] Reader dilepas: ${reader.name}`);
        broadcast({ type: 'reader_disconnected', reader: reader.name });
    });
});

nfc.on('error', (err) => {
    console.error('[NFC] Error NFC global:', err.message);
    if (err.message.includes('PCSC')) {
        console.error('      Pastikan driver PC/SC terpasang dan ACR122U tercolok!');
    }
});

console.log('🔌 Menginisialisasi NFC reader...');
console.log('   Pastikan ACR122U sudah tercolok ke port USB\n');
