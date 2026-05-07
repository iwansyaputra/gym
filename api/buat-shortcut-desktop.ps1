# ============================================================
# GymKu - Buat Shortcut Desktop
# Jalankan 1x, shortcut muncul di Desktop
# ============================================================

$WshShell = New-Object -comObject WScript.Shell
$Desktop   = [System.Environment]::GetFolderPath("Desktop")
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host ""
Write-Host "  GymKu - Membuat Shortcut Desktop..." -ForegroundColor Cyan
Write-Host ""

# Shortcut 1: NFC Bridge (Python)
$sc1 = $WshShell.CreateShortcut("$Desktop\GymKu NFC Bridge.lnk")
$sc1.TargetPath       = "$ScriptDir\jalankan-nfc-bridge.bat"
$sc1.WorkingDirectory = $ScriptDir
$sc1.Description      = "Jalankan NFC Bridge ACR122U untuk GymKu"
$sc1.WindowStyle      = 1
$sc1.Save()
Write-Host "  [OK] GymKu NFC Bridge.lnk" -ForegroundColor Green

# Shortcut 2: Chrome Check-in Admin
$sc2 = $WshShell.CreateShortcut("$Desktop\GymKu Admin Check-in.lnk")
$sc2.TargetPath       = "$ScriptDir\buka-chrome-checkin.bat"
$sc2.WorkingDirectory = $ScriptDir
$sc2.Description      = "Buka Chrome Admin Check-in NFC GymKu"
$sc2.WindowStyle      = 1
$sc2.Save()
Write-Host "  [OK] GymKu Admin Check-in.lnk" -ForegroundColor Green

Write-Host ""
Write-Host "  2 shortcut berhasil dibuat di Desktop!" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Cara pakai:" -ForegroundColor White
Write-Host "   1. Klik 2x [GymKu NFC Bridge]     -> jalankan Python bridge" -ForegroundColor White
Write-Host "   2. Klik 2x [GymKu Admin Check-in] -> buka Chrome NFC" -ForegroundColor White
Write-Host ""

Start-Sleep -Seconds 2
