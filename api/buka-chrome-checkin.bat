@echo off
chcp 65001 >nul
echo.
echo [GymKu] Membuka Chrome dengan izin WebSocket lokal (ws://localhost)...
echo.

:: Cari Chrome di lokasi umum
set CHROME=""
if exist "C:\Program Files\Google\Chrome\Application\chrome.exe" (
    set CHROME="C:\Program Files\Google\Chrome\Application\chrome.exe"
) else if exist "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" (
    set CHROME="C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
) else if exist "%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe" (
    set CHROME="%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe"
)

if %CHROME%=="" (
    echo [ERROR] Google Chrome tidak ditemukan!
    echo         Silakan install Chrome dari: https://www.google.com/chrome/
    pause
    exit /b 1
)

:: Buka Chrome dengan flag yang mengizinkan ws:// dari halaman HTTPS localhost
:: --allow-insecure-localhost mengizinkan koneksi ke localhost via ws://
:: --user-data-dir terpisah agar tidak konflik dengan Chrome yang sudah buka
%CHROME% ^
  --allow-insecure-localhost ^
  --unsafely-treat-insecure-origin-as-secure="ws://localhost:8765,ws://127.0.0.1:8765" ^
  --user-data-dir="%TEMP%\gymku-chrome-nfc" ^
  "https://gymku.motalindo.com/checkin.html"

echo.
echo [INFO] Chrome dibuka dengan WebSocket lokal aktif.
