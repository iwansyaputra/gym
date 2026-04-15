@echo off
echo ================================================
echo   PERBAIKAN FIREWALL WINDOWS - PORT 3000
echo ================================================
echo.
echo Script ini akan membuka port 3000 di Windows Firewall
echo agar backend API bisa diakses dari HP/perangkat lain
echo.
pause

echo.
echo [1/2] Menambahkan rule untuk TCP port 3000...
netsh advfirewall firewall add rule name="GymKu API - TCP 3000" dir=in action=allow protocol=TCP localport=3000

echo.
echo [2/2] Menambahkan rule untuk UDP port 3000...
netsh advfirewall firewall add rule name="GymKu API - UDP 3000" dir=in action=allow protocol=UDP localport=3000

echo.
echo ================================================
echo   SELESAI!
echo ================================================
echo.
echo Port 3000 sudah dibuka di Windows Firewall
echo Sekarang HP bisa akses ke: http://192.168.25.62:3000
echo.
echo Untuk melihat rule firewall:
echo   netsh advfirewall firewall show rule name=all
echo.
echo Untuk menghapus rule (jika perlu):
echo   netsh advfirewall firewall delete rule name="GymKu API - TCP 3000"
echo   netsh advfirewall firewall delete rule name="GymKu API - UDP 3000"
echo.
pause
