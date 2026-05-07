@echo off
chcp 65001 >nul
echo ============================================================
echo   NFC Bridge — ACR122U Reader untuk GymKu
echo   API Server: https://api.gymku.motalindo.com
echo   WebSocket : ws://localhost:8765 (berjalan di komputer ini)
echo ============================================================
echo.

:: Cek apakah Python tersedia
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python tidak ditemukan!
    echo         Download Python dari: https://www.python.org/downloads/
    pause
    exit /b 1
)

:: Cek dan install dependensi Python
python -c "import smartcard" >nul 2>&1
if errorlevel 1 (
    echo [INFO] Menginstall pyscard...
    pip install pyscard
    echo.
)

python -c "import websockets" >nul 2>&1
if errorlevel 1 (
    echo [INFO] Menginstall websockets...
    pip install websockets
    echo.
)

python -c "import requests" >nul 2>&1
if errorlevel 1 (
    echo [INFO] Menginstall requests...
    pip install requests
    echo.
)

echo [OK] Semua dependensi tersedia.
echo.
echo ============================================================
echo   PANDUAN PENGGUNAAN:
echo.
echo   1. Pastikan ACR122U sudah tercolok ke USB komputer ini
echo   2. NFC Bridge akan berjalan di ws://localhost:8765
echo   3. Buka Admin Web di browser dengan cara:
echo.
echo      [CARA 1 - Disarankan] Jalankan Chrome dengan flag khusus:
echo      Dobel klik: buka-chrome-checkin.bat
echo.
echo      [CARA 2] Buka Chrome, ketik di address bar:
echo      chrome://flags/#unsafely-treat-insecure-origin-as-secure
echo      Masukkan: http://localhost:8765
echo      Lalu buka: https://gymku.motalindo.com/checkin.html
echo.
echo   Python akan langsung POST ke:
echo   https://api.gymku.motalindo.com/api/check-in/nfc
echo ============================================================
echo.

cd /d "%~dp0"
python nfc-bridge.py

pause
