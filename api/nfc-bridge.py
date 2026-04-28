"""
NFC Bridge Server — ACR122U → WebSocket → checkin.html
========================================================
Membaca data HCE dari Flutter (nfc_host_card_emulation) dengan AID: A0 00 DA DA DA DA DA

Alur pembacaan:
  1. HP Android menempel ke ACR122U (HCE aktif)
  2. Bridge kirim SELECT AID ke HP
  3. HP merespons dengan nfc_id (bytes ASCII dari nfc_id member)
  4. Bridge decode bytes → string nfc_id
  5. Kirim ke browser via WebSocket

Persyaratan:
    pip install pyscard websockets

Jalankan:
    python nfc-bridge.py
"""

import asyncio
import json
import logging
import time
from datetime import datetime

# --- Cek dependensi ---
try:
    from smartcard.System import readers
    from smartcard.CardMonitoring import CardMonitor, CardObserver
    PYSCARD_OK = True
except ImportError:
    PYSCARD_OK = False
    print("❌ pyscard belum terpasang! Jalankan: pip install pyscard")

try:
    import websockets
    WS_OK = True
except ImportError:
    WS_OK = False
    print("❌ websockets belum terpasang! Jalankan: pip install websockets")

if not PYSCARD_OK or not WS_OK:
    input("Tekan Enter untuk keluar...")
    exit(1)

# --- Konfigurasi ---
WS_PORT = 8765
logging.basicConfig(level=logging.INFO, format="[%(asctime)s] %(message)s", datefmt="%H:%M:%S")
log = logging.getLogger("NFCBridge")

# --- WebSocket clients ---
connected_clients = set()
card_event_queue = asyncio.Queue()

# ──────────────────────────────────────────────────────────────────────────────
# APDU Commands
# ──────────────────────────────────────────────────────────────────────────────

# AID yang sama persis dengan Flutter: [0xA0, 0x00, 0xDA, 0xDA, 0xDA, 0xDA, 0xDA]
FLUTTER_AID = [0xA0, 0x00, 0xDA, 0xDA, 0xDA, 0xDA, 0xDA]

# SELECT AID command: 00 A4 04 00 <Lc=len AID> <AID bytes> 00
SELECT_AID_APDU = (
    [0x00, 0xA4, 0x04, 0x00, len(FLUTTER_AID)]
    + FLUTTER_AID
    + [0x00]  # Le
)

# GET DATA command (untuk baca response dari port 0 setelah SELECT)
GET_DATA_APDU = [0x00, 0xCA, 0x00, 0x00, 0x00]

# Fallback: baca UID kartu fisik (untuk kartu NFC biasa, bukan HCE)
GET_UID_APDU = [0xFF, 0xCA, 0x00, 0x00, 0x00]


def bytes_to_hex_str(data: list) -> str:
    return ' '.join(f'{b:02X}' for b in data)


def uid_to_nfc_id(uid_bytes: list) -> str:
    """Konversi UID bytes kartu fisik ke 10 digit desimal (fallback)."""
    four_bytes = uid_bytes[:4]
    val = int.from_bytes(bytes(four_bytes), byteorder='big')
    return str(val).zfill(10)


def read_hce_nfc_id(connection) -> dict:
    """
    Baca nfc_id dari HP Android yang pakai HCE (nfc_host_card_emulation Flutter).

    Plugin nfc_host_card_emulation menyimpan data di 'port'. Saat reader kirim
    APDU apapun setelah SELECT AID, plugin merespons dengan data di port tersebut.

    Urutan:
    1. SELECT AID → 9000 (success)
    2. Kirim APDU trigger (00 00 00 00 00 atau 00 CA 00 00 00)
    3. Response berisi nfc_id dalam ASCII bytes

    Fallback: baca UID kartu fisik (kartu NFC biasa)
    """
    try:
        # ── STEP 1: SELECT AID ─────────────────────────────────────────────
        log.info(f"→ SELECT AID: {bytes_to_hex_str(SELECT_AID_APDU)}")
        data, sw1, sw2 = connection.transmit(SELECT_AID_APDU)
        log.info(f"← SELECT response: data={bytes_to_hex_str(data) if data else '(empty)'} SW={sw1:02X} {sw2:02X}")

        if sw1 == 0x90 and sw2 == 0x00:
            # Jika SELECT langsung bawa data → decode sebagai nfc_id
            if len(data) > 0:
                nfc_id = bytes(data).decode('ascii', errors='replace').strip('\x00').strip()
                log.info(f"✅ HCE nfc_id dari SELECT response: '{nfc_id}'")
                return {'nfc_id': nfc_id, 'source': 'hce_select', 'raw': bytes_to_hex_str(data)}

            # ── STEP 2a: Port 0 trigger — 00 00 00 00 00 ──────────────────
            # Plugin nfc_host_card_emulation: port 0 direspons saat INS=0x00
            trigger1 = [0x00, 0x00, 0x00, 0x00, 0x00]
            log.info(f"→ Port-0 trigger: {bytes_to_hex_str(trigger1)}")
            d1, s1a, s1b = connection.transmit(trigger1)
            log.info(f"← trigger response: data={bytes_to_hex_str(d1) if d1 else '(empty)'} SW={s1a:02X} {s1b:02X}")
            if (s1a == 0x90 and s1b == 0x00) and len(d1) > 0:
                nfc_id = bytes(d1).decode('ascii', errors='replace').strip('\x00').strip()
                log.info(f"✅ HCE nfc_id dari port-0 trigger: '{nfc_id}'")
                return {'nfc_id': nfc_id, 'source': 'hce_port0', 'raw': bytes_to_hex_str(d1)}

            # ── STEP 2b: GET DATA — 00 CA 00 00 00 ────────────────────────
            log.info(f"→ GET DATA: {bytes_to_hex_str(GET_DATA_APDU)}")
            d2, s2a, s2b = connection.transmit(GET_DATA_APDU)
            log.info(f"← GET DATA response: data={bytes_to_hex_str(d2) if d2 else '(empty)'} SW={s2a:02X} {s2b:02X}")
            if (s2a == 0x90 and s2b == 0x00) and len(d2) > 0:
                nfc_id = bytes(d2).decode('ascii', errors='replace').strip('\x00').strip()
                log.info(f"✅ HCE nfc_id dari GET DATA: '{nfc_id}'")
                return {'nfc_id': nfc_id, 'source': 'hce_getdata', 'raw': bytes_to_hex_str(d2)}

            # ── STEP 2c: GET RESPONSE — 00 C0 00 00 00 ────────────────────
            get_response = [0x00, 0xC0, 0x00, 0x00, 0x00]
            log.info(f"→ GET RESPONSE: {bytes_to_hex_str(get_response)}")
            d3, s3a, s3b = connection.transmit(get_response)
            log.info(f"← GET RESPONSE: data={bytes_to_hex_str(d3) if d3 else '(empty)'} SW={s3a:02X} {s3b:02X}")
            if (s3a == 0x90 and s3b == 0x00) and len(d3) > 0:
                nfc_id = bytes(d3).decode('ascii', errors='replace').strip('\x00').strip()
                log.info(f"✅ HCE nfc_id dari GET RESPONSE: '{nfc_id}'")
                return {'nfc_id': nfc_id, 'source': 'hce_getresponse', 'raw': bytes_to_hex_str(d3)}

            log.warning("Semua APDU tidak mengembalikan data dari HCE. Fallback ke UID...")

        elif sw1 == 0x6A and sw2 == 0x82:
            log.info("SELECT AID: File Not Found (6A82) → Kartu fisik biasa. Baca UID...")
        else:
            log.warning(f"SELECT AID SW tidak dikenal: {sw1:02X} {sw2:02X}")

    except Exception as e:
        log.warning(f"APDU error: {e}. Fallback baca UID...")

    # ── STEP 3: Fallback — baca UID kartu fisik ────────────────────────────
    try:
        uid_data, sw1, sw2 = connection.transmit(GET_UID_APDU)
        if sw1 == 0x90 and sw2 == 0x00 and uid_data:
            uid_hex = bytes_to_hex_str(uid_data)
            nfc_id  = uid_to_nfc_id(uid_data)
            log.info(f"✅ Kartu fisik UID: {uid_hex} → nfc_id: {nfc_id}")
            return {'nfc_id': nfc_id, 'source': 'uid', 'raw': uid_hex}
    except Exception as e:
        log.error(f"Baca UID juga gagal: {e}")

    return {'nfc_id': None, 'source': 'error', 'raw': ''}


# ──────────────────────────────────────────────────────────────────────────────
# Card Observer
# ──────────────────────────────────────────────────────────────────────────────
# Cooldown dict: { nfc_id: last_sent_timestamp }
_last_sent: dict = {}
COOLDOWN_SECONDS = 5  # Minimal jarak antar event untuk NFC ID yang sama


class NFCCardObserver(CardObserver):
    def __init__(self, loop):
        self.loop = loop

    def update(self, observable, actions):
        (added_cards, removed_cards) = actions

        for card in added_cards:
            try:
                card.connection = card.createConnection()
                card.connection.connect()
                log.info("Kartu/HP terdeteksi! Membaca data...")

                result = read_hce_nfc_id(card.connection)

                if result['nfc_id']:
                    nfc_id = result['nfc_id']
                    now = time.time()

                    # ── Cek cooldown: jangan kirim event yang sama dalam 5 detik ──
                    last = _last_sent.get(nfc_id, 0)
                    if now - last < COOLDOWN_SECONDS:
                        sisa = round(COOLDOWN_SECONDS - (now - last), 1)
                        log.warning(f"[COOLDOWN] {nfc_id} diabaikan — tunggu {sisa}s lagi")
                        continue  # Skip broadcast, jangan kirim ke browser

                    _last_sent[nfc_id] = now
                    log.info(f"NFC ID: '{nfc_id}' (source: {result['source']})")
                    payload = {
                        "type": "card_detected",
                        "nfc_id": nfc_id,
                        "source": result['source'],
                        "raw": result['raw'],
                        "timestamp": datetime.now().isoformat(),
                    }
                else:
                    log.error("Gagal membaca NFC ID")
                    payload = {
                        "type": "error",
                        "message": "Gagal membaca NFC ID dari kartu/HP",
                        "timestamp": datetime.now().isoformat(),
                    }

            except Exception as e:
                log.error(f"Error saat memproses kartu: {e}")
                payload = {
                    "type": "error",
                    "message": f"Error: {str(e)}",
                    "timestamp": datetime.now().isoformat(),
                }

            self.loop.call_soon_threadsafe(card_event_queue.put_nowait, payload)

        for card in removed_cards:
            log.info("Kartu/HP dilepas dari reader")
            self.loop.call_soon_threadsafe(
                card_event_queue.put_nowait,
                {"type": "card_removed", "timestamp": datetime.now().isoformat()}
            )


# ──────────────────────────────────────────────────────────────────────────────
# WebSocket Server
# ──────────────────────────────────────────────────────────────────────────────
async def broadcast(data: dict):
    if not connected_clients:
        return
    msg = json.dumps(data)
    dead = set()
    for ws in connected_clients:
        try:
            await ws.send(msg)
        except Exception:
            dead.add(ws)
    connected_clients.difference_update(dead)


async def forward_card_events():
    while True:
        event = await card_event_queue.get()
        await broadcast(event)


async def ws_handler(websocket, path=None):
    connected_clients.add(websocket)
    log.info(f"Browser terhubung. Total: {len(connected_clients)}")
    await websocket.send(json.dumps({
        "type": "status",
        "message": "NFC Bridge aktif. Tempelkan HP ke ACR122U..."
    }))
    try:
        await websocket.wait_closed()
    finally:
        connected_clients.discard(websocket)
        log.info(f"Browser terputus. Total: {len(connected_clients)}")


# ──────────────────────────────────────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────────────────────────────────────
async def main():
    loop = asyncio.get_event_loop()

    available_readers = readers()
    if not available_readers:
        log.error("Tidak ada NFC reader terdeteksi! Pastikan ACR122U tercolok.")
        input("Tekan Enter untuk keluar...")
        return

    log.info(f"NFC Reader: {available_readers[0]}")

    card_monitor = CardMonitor()
    observer = NFCCardObserver(loop)
    card_monitor.addObserver(observer)

    print(f"\n✅ NFC Bridge siap!")
    print(f"   WebSocket : ws://localhost:{WS_PORT}")
    print(f"   Reader    : {available_readers[0]}")
    print(f"   AID       : A0 00 DA DA DA DA DA (Flutter HCE)")
    print(f"\n   Tempelkan HP (Flutter app aktif) ke ACR122U")
    print(f"   Buka checkin.html di browser\n")

    async with websockets.serve(ws_handler, "localhost", WS_PORT):
        await forward_card_events()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\nNFC Bridge dihentikan.")
