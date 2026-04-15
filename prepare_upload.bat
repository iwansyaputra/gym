@echo off
echo ========================================
echo   PERSIAPAN FILE UPLOAD KE CPANEL
echo ========================================
echo.

REM Buat folder untuk upload
set UPLOAD_DIR=upload_cpanel
if exist %UPLOAD_DIR% (
    echo Menghapus folder lama...
    rmdir /s /q %UPLOAD_DIR%
)

echo Membuat folder upload...
mkdir %UPLOAD_DIR%
echo.

echo Menyalin file-file penting...
echo.

REM Copy file utama
echo [1/9] Copying package.json...
copy api\package.json %UPLOAD_DIR%\ > nul

echo [2/9] Copying server.js...
copy api\server.js %UPLOAD_DIR%\ > nul

echo [3/9] Copying .env.example...
copy api\.env.example %UPLOAD_DIR%\.env > nul

REM Copy folder-folder
echo [4/9] Copying config/...
xcopy api\config %UPLOAD_DIR%\config\ /E /I /Y > nul

echo [5/9] Copying controllers/...
xcopy api\controllers %UPLOAD_DIR%\controllers\ /E /I /Y > nul

echo [6/9] Copying middleware/...
xcopy api\middleware %UPLOAD_DIR%\middleware\ /E /I /Y > nul

echo [7/9] Copying models/...
if exist api\models (
    xcopy api\models %UPLOAD_DIR%\models\ /E /I /Y > nul
    echo     - Models copied
) else (
    echo     - No models folder found (skip)
)

echo [8/9] Copying routes/...
xcopy api\routes %UPLOAD_DIR%\routes\ /E /I /Y > nul

echo [9/9] Copying services/...
if exist api\services (
    xcopy api\services %UPLOAD_DIR%\services\ /E /I /Y > nul
    echo     - Services copied
) else (
    echo     - No services folder found (skip)
)

echo.
echo ========================================
echo   MEMBUAT FILE ZIP
echo ========================================
echo.

REM Hapus file ZIP lama jika ada
if exist backend-api.zip (
    del backend-api.zip
)

REM Compress ke ZIP menggunakan PowerShell
powershell -Command "Compress-Archive -Path '%UPLOAD_DIR%\*' -DestinationPath 'backend-api.zip' -Force"

REM Tunggu sebentar
timeout /t 2 /nobreak > nul

if exist backend-api.zip (
    echo.
    echo ========================================
    echo   SUKSES!
    echo ========================================
    echo.
    echo File ZIP berhasil dibuat: backend-api.zip
    echo Ukuran: 
    powershell -Command "(Get-Item 'backend-api.zip').Length / 1KB | ForEach-Object {'{0:N2} KB' -f $_}"
    echo.
    echo LANGKAH SELANJUTNYA:
    echo 1. Upload file 'backend-api.zip' ke cPanel
    echo 2. Extract di folder public_html/gym
    echo 3. Edit file .env (sesuaikan database)
    echo 4. Setup Node.js App di cPanel
    echo 5. Run npm install
    echo 6. Start aplikasi
    echo.
    echo Baca tutorial lengkap: DEPLOYMENT_CPANEL.md
    echo.
    
    REM Hapus folder temporary
    echo Membersihkan folder temporary...
    rmdir /s /q %UPLOAD_DIR%
    
    echo.
    echo File siap upload: backend-api.zip
    echo.
    start explorer .
) else (
    echo.
    echo ERROR: Gagal membuat file ZIP
    echo.
)

pause
