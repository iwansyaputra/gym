# -*- coding: utf-8 -*-
"""
NFC Bridge Server - ACR122U -> WebSocket -> Backend API
=======================================================
Fitur:
  - READ: Baca nfc_id dari HP Android HCE / kartu NFC fisik
  - CHECK-IN: Langsung kirim ke API https://api.gymku.motalindo.com
  - WRITE: Terima perintah write_card dari browser -> tulis user_id ke kartu NFC
  - BROADCAST: Kirim hasil check-in ke semua browser yang terhubung via WebSocket

Persyaratan:
    pip install pyscard websockets requests

Jalankan:
    python nfc-bridge.py
"""

import asyncio
import json
import logging
import time
from datetime import datetime

try:
    import requests
    REQUESTS_OK = True
except ImportError:
    REQUESTS_OK = False
    import urllib.request
    import urllib.error

# ──────────────────────────────────────────────────────────────────────────────
# KONFIGURASI API
# ──────────────────────────────────────────────────────────────────────────────
API_BASE_URL = "https://api.gymku.motalindo.com/api"
NFC_SECRET_KEY = "nfc-bridge-secret-2024"  # Harus sama dengan backend .env NFC_SECRET_KEY
CHECKIN_ENDPOINT = f"{API_BASE_URL}/check-in/nfc"

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

# Mode bridge saat ini: 'read' atau 'write'
_bridge_mode = 'read'
# Koneksi kartu aktif (untuk mode write)
_active_connection = None

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


def read_uid_fast(connection) -> dict:
    """Baca UID kartu fisik langsung — 1 APDU, sangat cepat (~50ms)."""
    try:
        uid_data, sw1, sw2 = connection.transmit(GET_UID_APDU)
        if sw1 == 0x90 and sw2 == 0x00 and uid_data:
            uid_hex = bytes_to_hex_str(uid_data)
            nfc_id  = uid_to_nfc_id(uid_data)
            log.info(f"✅ UID kartu: {uid_hex} → nfc_id: {nfc_id}")
            return {'nfc_id': nfc_id, 'source': 'uid', 'raw': uid_hex}
    except Exception as e:
        log.error(f"Baca UID gagal: {e}")
    return {'nfc_id': None, 'source': 'error', 'raw': ''}


def write_user_id_to_card(connection, user_id: int) -> dict:
    """
    Tulis user_id sebagai raw ASCII bytes ke block 4 (Mifare) atau page 4 (NTAG).
    """
    try:
        user_id_bytes = str(user_id).encode('ascii')
        chunk = list(user_id_bytes)
        if len(chunk) > 16:
            chunk = chunk[:16]
        chunk += [0x00] * (16 - len(chunk))  # Pad to 16 bytes

        # 1. Coba load key (Default FF FF FF FF FF FF)
        connection.transmit([0xFF, 0x82, 0x00, 0x00, 0x06, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF])
        # 2. Coba authenticate block 4 (untuk Mifare Classic)
        connection.transmit([0xFF, 0x86, 0x00, 0x00, 0x05, 0x01, 0x00, 0x04, 0x60, 0x00])

        # 3. Tulis 16 bytes ke block/page 4
        write_apdu = [0xFF, 0xD6, 0x00, 0x04, 0x10] + chunk
        _, sw1, sw2 = connection.transmit(write_apdu)
        
        if sw1 == 0x90 and sw2 == 0x00:
            log.info(f'✅ user_id={user_id} berhasil ditulis ke kartu (16 bytes)')
            return {'success': True}
        else:
            return {'success': False, 'error': f'Write gagal di page/block 4: SW={sw1:02X}{sw2:02X}'}
    except Exception as e:
        log.error(f'Error write kartu: {e}')
        return {'success': False, 'error': str(e)}


def read_card_user_id(connection) -> dict:
    """
    Baca user_id yang tertulis di block/page 4 kartu.
    """
    try:
        # Authenticate untuk Mifare
        connection.transmit([0xFF, 0x82, 0x00, 0x00, 0x06, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF])
        connection.transmit([0xFF, 0x86, 0x00, 0x00, 0x05, 0x01, 0x00, 0x04, 0x60, 0x00])

        # Baca 16 bytes
        read_apdu = [0xFF, 0xB0, 0x00, 0x04, 0x10]
        data, sw1, sw2 = connection.transmit(read_apdu)
        if sw1 == 0x90 and sw2 == 0x00 and data:
            raw = bytes(data)
            user_id_str = raw.split(b'\x00')[0].decode('ascii', errors='ignore').strip()
            if user_id_str and user_id_str.isdigit():
                log.info(f'✅ Kartu terprogram: user_id={user_id_str}')
                return {'nfc_id': user_id_str, 'source': 'card_written'}
    except Exception as e:
        log.warning(f'Baca page kartu gagal (mungkin bukan kartu terprogram): {e}')
    return {'nfc_id': None, 'source': 'none'}


def erase_card_data(connection) -> dict:
    """Hapus data dari block/page 4 dengan menimpanya dengan 0x00 (16 bytes)."""
    try:
        connection.transmit([0xFF, 0x82, 0x00, 0x00, 0x06, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF])
        connection.transmit([0xFF, 0x86, 0x00, 0x00, 0x05, 0x01, 0x00, 0x04, 0x60, 0x00])

        write_apdu = [0xFF, 0xD6, 0x00, 0x04, 0x10] + ([0x00] * 16)
        _, sw1, sw2 = connection.transmit(write_apdu)
        if sw1 == 0x90 and sw2 == 0x00:
            log.info('✅ Kartu berhasil diformat (data dihapus)')
            return {'success': True}
        else:
            return {'success': False, 'error': f'Gagal menghapus page/block 4: SW={sw1:02X}{sw2:02X}'}
    except Exception as e:
        log.error(f'Error erase kartu: {e}')
        return {'success': False, 'error': str(e)}


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


# write_ndef_to_card dihapus — diganti write_user_id_to_card (raw page, jauh lebih cepat)


class NFCCardObserver(CardObserver):
    def __init__(self, loop):
        self.loop = loop

    def update(self, observable, actions):
        global _active_connection, _bridge_mode, _pending_write_user_id
        (added_cards, removed_cards) = actions

        for card in added_cards:
            try:
                card.connection = card.createConnection()
                card.connection.connect()
                _active_connection = card.connection
                log.info("Kartu/HP terdeteksi!")

                if _bridge_mode == 'link_card':
                    # Mode link_card: baca UID instan (1 APDU), kirim ke browser
                    result = read_uid_fast(card.connection)
                    payload = {
                        "type": "card_uid_ready",
                        "nfc_id": result['nfc_id'],
                        "raw": result['raw'],
                        "timestamp": datetime.now().isoformat(),
                    }
                    self.loop.call_soon_threadsafe(card_event_queue.put_nowait, payload)
                    _bridge_mode = 'read'  # Kembali ke read mode otomatis
                    continue

                if _bridge_mode == 'write_id':
                    # Mode write_id: tulis user_id ke kartu sekarang juga
                    # _pending_write_user_id diisi oleh ws_handler saat browser kirim write_card
                    uid_result = read_uid_fast(card.connection)
                    result_write = write_user_id_to_card(card.connection, _pending_write_user_id)
                    payload = {
                        "type": "write_success" if result_write['success'] else "write_error",
                        "nfc_id": str(_pending_write_user_id),
                        "uid": uid_result.get('nfc_id', ''),
                        "message": f"user_id {_pending_write_user_id} berhasil ditulis ke kartu" if result_write['success'] else result_write.get('error', 'Gagal'),
                        "timestamp": datetime.now().isoformat(),
                    }
                    _bridge_mode = 'read'
                    self.loop.call_soon_threadsafe(card_event_queue.put_nowait, payload)
                    continue

                if _bridge_mode == 'erase_card':
                    # Mode erase_card: hapus data user_id dari kartu
                    result_erase = erase_card_data(card.connection)
                    payload = {
                        "type": "erase_success" if result_erase['success'] else "erase_error",
                        "message": "Data kartu berhasil dihapus" if result_erase['success'] else result_erase.get('error', 'Gagal'),
                        "timestamp": datetime.now().isoformat(),
                    }
                    _bridge_mode = 'read'
                    self.loop.call_soon_threadsafe(card_event_queue.put_nowait, payload)
                    continue

                if _bridge_mode == 'read_info':
                    # Mode read_info: hanya baca kartu (tidak checkin)
                    written = read_card_user_id(card.connection)
                    uid_res = read_uid_fast(card.connection)
                    payload = {
                        "type": "card_info",
                        "user_id": written['nfc_id'] if written['nfc_id'] else None,
                        "uid": uid_res['nfc_id'],
                        "timestamp": datetime.now().isoformat()
                    }
                    _bridge_mode = 'read'
                    self.loop.call_soon_threadsafe(card_event_queue.put_nowait, payload)
                    continue

                # Mode read (default) — coba baca data tertulis dulu, lalu HCE, lalu UID
                log.info("Membaca UID / HCE data...")
                # Prioritas 1: Kartu yang sudah diprogramkan (baca page 4)
                written = read_card_user_id(card.connection)
                if written['nfc_id']:
                    result = written
                    result['raw'] = ''
                else:
                    # Prioritas 2: HCE dari Flutter / kartu fisik UID
                    uid_result = read_uid_fast(card.connection)
                    if uid_result['nfc_id']:
                        hce_result = read_hce_nfc_id(card.connection)
                        result = hce_result if hce_result['nfc_id'] and hce_result['source'] != 'uid' else uid_result
                    else:
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

                    # ── Kirim check-in ke backend API ──────────────────────────
                    log.info(f"→ POST {CHECKIN_ENDPOINT} (nfc_id={nfc_id})")
                    api_result = checkin_to_api(nfc_id)
                    log.info(f"← API response: {api_result}")

                    payload = {
                        "type": "card_detected",
                        "nfc_id": nfc_id,
                        "source": result['source'],
                        "raw": result['raw'],
                        "timestamp": datetime.now().isoformat(),
                        # ── Hasil dari backend API ──
                        "checkin": api_result,
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
# API Check-in Helper
# ──────────────────────────────────────────────────────────────────────────────
def checkin_to_api(nfc_id: str) -> dict:
    """
    Kirim POST ke backend API untuk melakukan check-in member via nfc_id.
    Menggunakan NFC_SECRET_KEY sebagai autentikasi (tidak perlu JWT user).
    Returns dict: { success, message, member_name, gym_name, membership_status }
    """
    body = json.dumps({"nfc_id": nfc_id}).encode("utf-8")
    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "X-NFC-Secret": NFC_SECRET_KEY,
    }

    try:
        if REQUESTS_OK:
            resp = requests.post(
                CHECKIN_ENDPOINT,
                data=body,
                headers=headers,
                timeout=8
            )
            data = resp.json()
            if resp.status_code in (200, 201):
                log.info(f"✅ Check-in sukses: {data.get('member', {}).get('name', nfc_id)}")
            else:
                log.warning(f"⚠️ Check-in API error {resp.status_code}: {data.get('message', '')}")
            return data
        else:
            # Fallback urllib (jika requests tidak terpasang)
            req = urllib.request.Request(
                CHECKIN_ENDPOINT,
                data=body,
                headers=headers,
                method="POST"
            )
            with urllib.request.urlopen(req, timeout=8) as resp:
                raw = resp.read().decode("utf-8")
                return json.loads(raw)
    except Exception as e:
        log.error(f"❌ Gagal connect ke API: {e}")
        return {
            "success": False,
            "message": f"Tidak bisa terhubung ke server: {str(e)}"
        }


# ──────────────────────────────────────────────────────────────────────────────
# WebSocket Server
# ──────────────────────────────────────────────────────────────────────────────
# user_id yang akan ditulis ke kartu berikutnya saat mode write_id
_pending_write_user_id: int = 0
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
    global _bridge_mode, _pending_write_user_id
    connected_clients.add(websocket)
    log.info(f"Browser terhubung. Total: {len(connected_clients)}")
    await websocket.send(json.dumps({
        "type": "status",
        "message": "NFC Bridge aktif. Tempelkan HP/kartu ke ACR122U..."
    }))
    try:
        async for raw_msg in websocket:
            try:
                msg = json.loads(raw_msg)
            except Exception:
                continue

            msg_type = msg.get('type', '')

            if msg_type == 'set_mode':
                _bridge_mode = msg.get('mode', 'read')
                log.info(f"Mode bridge: {_bridge_mode}")
                await websocket.send(json.dumps({'type': 'status', 'message': f'Mode: {_bridge_mode}'}))

            elif msg_type == 'write_card':
                # Browser kirim user_id yang harus ditulis ke kartu
                # Bridge masuk mode write_id — saat kartu ditempel, langsung tulis
                user_id = msg.get('user_id')
                if not user_id:
                    await websocket.send(json.dumps({'type': 'write_error', 'message': 'user_id kosong'}))
                    continue
                _pending_write_user_id = int(user_id)
                _bridge_mode = 'write_id'
                log.info(f"[write_id] Siap tulis user_id={user_id} ke kartu berikutnya")
                await websocket.send(json.dumps({
                    'type': 'status',
                    'message': f'Siap tulis user_id={user_id}. Tempelkan kartu NFC ke reader...'
                }))

            elif msg_type == 'erase_card':
                _bridge_mode = 'erase_card'
                log.info("[erase_card] Siap menghapus data kartu berikutnya")
                await websocket.send(json.dumps({'type': 'status', 'message': 'Siap menghapus data, tempelkan kartu...'}))

            elif msg_type == 'read_info':
                _bridge_mode = 'read_info'
                log.info("[read_info] Siap membaca data kartu berikutnya")
                await websocket.send(json.dumps({'type': 'status', 'message': 'Siap membaca kartu, tempelkan kartu...'}))

    except Exception:
        pass
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
    print(f"   WebSocket  : ws://localhost:{WS_PORT}")
    print(f"   Backend API: {CHECKIN_ENDPOINT}")
    print(f"   Reader     : {available_readers[0]}")
    print(f"   AID        : A0 00 DA DA DA DA DA (Flutter HCE)")
    print(f"\n   Cara kerja:")
    print(f"   1. Tempelkan kartu NFC ke ACR122U")
    print(f"   2. Python baca nfc_id lalu langsung POST ke backend API")
    print(f"   3. Hasil check-in dikirim ke browser via WebSocket")
    print(f"\n   Buka admin_web/checkin.html di browser lokal\n")

    async with websockets.serve(ws_handler, "localhost", WS_PORT):
        await forward_card_events()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\nNFC Bridge dihentikan.")
