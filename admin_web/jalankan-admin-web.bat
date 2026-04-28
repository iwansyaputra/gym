@echo off
echo =============================================
echo  GymKu Admin Web Server
echo =============================================
echo.
echo Membuka admin web di http://localhost:5500
echo.

cd /d "c:\Users\Iwan\Documents\projek\membership_gym\admin_web"

:: Coba pakai Python HTTP server (hampir semua Windows ada Python)
python --version >nul 2>&1
if not errorlevel 1 (
    echo [INFO] Menjalankan dengan Python HTTP Server...
    echo [INFO] Buka browser ke: http://localhost:5500
    echo [INFO] Tekan Ctrl+C untuk berhenti
    echo.
    python -m http.server 5500
    goto :end
)

:: Fallback: pakai Node.js http-server
node --version >nul 2>&1
if not errorlevel 1 (
    echo [INFO] Menjalankan dengan Node.js...
    npx -y http-server . -p 5500 -o
    goto :end
)

echo [ERROR] Python dan Node.js tidak ditemukan!
echo         Install salah satu dari:
echo         - Python: https://python.org
echo         - Node.js: https://nodejs.org

:end
pause
