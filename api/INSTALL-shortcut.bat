@echo off
chcp 65001 >nul
echo.
echo  GymKu — Membuat Shortcut di Desktop...
echo.

:: Jalankan PowerShell script untuk buat shortcut
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0buat-shortcut-desktop.ps1"

echo.
echo  Selesai! Cek Desktop Anda.
pause
