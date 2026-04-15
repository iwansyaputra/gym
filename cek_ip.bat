@echo off
REM Script untuk cek IP laptop dan update Flutter config
REM Jalankan script ini setiap kali pindah WiFi

echo ========================================
echo    CEK IP LAPTOP UNTUK FLUTTER APP
echo ========================================
echo.

REM Cek IP Address
echo [1] IP Address Laptop Anda:
echo.
ipconfig | findstr /i "IPv4"
echo.

REM Instruksi
echo ========================================
echo [2] CARA UPDATE IP DI FLUTTER:
echo ========================================
echo.
echo 1. Copy IP Address di atas (contoh: 192.168.100.203)
echo 2. Buka file: lib/services/api_config.dart
echo 3. Cari baris: static const String _currentIP = '...'
echo 4. Ganti IP lama dengan IP baru
echo 5. Save file
echo 6. Di terminal Flutter, tekan 'r' untuk hot reload
echo.

REM Test koneksi
echo ========================================
echo [3] TEST KONEKSI SERVER:
echo ========================================
echo.
echo Testing http://localhost:3000 ...
curl -s http://localhost:3000 >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ Server running di localhost:3000
) else (
    echo ❌ Server TIDAK running!
    echo    Jalankan: cd api ^&^& npm start
)
echo.

echo ========================================
echo [4] FIREWALL CHECK:
echo ========================================
echo.
netsh advfirewall firewall show rule name="Node.js Server" >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ Firewall rule sudah ada
) else (
    echo ⚠️  Firewall rule belum ada
    echo    Jalankan sebagai Admin:
    echo    New-NetFirewallRule -DisplayName "Node.js Server" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 3000
)
echo.

echo ========================================
echo Selesai! Tekan tombol apapun untuk keluar...
pause >nul
