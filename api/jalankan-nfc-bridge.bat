@echo off
echo ============================================
echo  NFC Bridge — ACR122U Reader untuk GymKu
echo  Terhubung ke: https://api.gymku.motalindo.com
echo ============================================
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
echo [INFO] Pastikan ACR122U sudah tercolok ke USB
echo [INFO] Python akan langsung hit API: https://api.gymku.motalindo.com/api/check-in/nfc
echo [INFO] Buka checkin.html di browser setelah ini
echo.

cd /d "%~dp0"
python nfc-bridge.py

pause
