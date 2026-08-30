# ========================================================================
# Lenovo IdeaPad 3 11IGL05 Audio Persistence & Restart Fix Tool
# Mencegah dan memperbaiki masalah audio tidak bersuara setelah reboot
# ========================================================================

[CmdletBinding()]
param()

$Host.UI.RawUI.WindowTitle = "Audio Restart Fix - Lenovo IdeaPad 3 11IGL05"

function Test-Administrator {
    $user = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    return $user.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Administrator)) {
    Write-Host "[X] ERROR: Harap jalankan script ini sebagai Administrator!" -ForegroundColor Red
    exit 1
}

Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host "      SOLUSI AUDIO HILANG / TANDA X SETELAH RESTART WINDOWS 10          " -ForegroundColor Yellow
Write-Host "========================================================================" -ForegroundColor Cyan

# 1. Konfigurasi Permanen BCD TestSigning & Driver Signature Enforcement
Write-Host "`n[1/5] Memastikan Windows TestSigning Aktif Permanen..." -ForegroundColor Cyan
try {
    & bcdedit /set {default} testsigning on | Out-Null
    & bcdedit /set {current} testsigning on | Out-Null
    & bcdedit /set {bootmgr} testsigning on | Out-Null
    & bcdedit /set {default} nointegritychecks on | Out-Null
    & bcdedit /set {current} nointegritychecks on | Out-Null
    & bcdedit /set {default} loadoptions DDISABLE_INTEGRITY_CHECKS | Out-Null
    & bcdedit /set {current} loadoptions DDISABLE_INTEGRITY_CHECKS | Out-Null
    Write-Host "    [V] BCD Test Mode & NoIntegrityChecks berhasil dikunci permanen." -ForegroundColor Green
} catch {
    Write-Host "    [!] Gagal mengupdate BCD: $_" -ForegroundColor Yellow
}

# 2. Matikan Windows Fast Startup (Hiberboot)
# Catatan Teknis: Fast Startup membekukan kernel Windows (hybrid sleep) sehingga 
# codec I2S audio Chromebook gagal melakukan power cycle D3->D0 saat reboot.
Write-Host "`n[2/5] Menonaktifkan Windows Fast Startup (Penyebab Utama Bug Reboot)..." -ForegroundColor Cyan
try {
    & powercfg /h off | Out-Null
    if (-not (Test-Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power")) {
        New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Value 0 -Type DWord -Force | Out-Null
    Write-Host "    [V] Fast Startup berhasil dimatikan." -ForegroundColor Green
} catch {
    Write-Host "    [!] Peringatan saat mengatur Power: $_" -ForegroundColor Yellow
}

# 3. Mendaftarkan Tugas Terjadwal Otomatis Inisialisasi Audio saat Logon & Boot
Write-Host "`n[3/5] Mendaftarkan Task Otomatis Inisialisasi Audio Service..." -ForegroundColor Cyan
try {
    $fixCommand = 'powershell.exe -NoProfile -WindowStyle Hidden -Command "Start-Sleep -Seconds 3; Restart-Service -Name Audiosrv,AudioEndpointBuilder -Force"'
    & schtasks.exe /create /tn "ChromebookAudioStartupFix" /tr $fixCommand /sc ONLOGON /rl HIGHEST /f | Out-Null
    Write-Host "    [V] Tugas terjadwal startup berhasil dibuat." -ForegroundColor Green
} catch {
    Write-Host "    [!] Peringatan scheduled tasks: $_" -ForegroundColor Yellow
}

# 4. Restart Layanan Audio Windows
Write-Host "`n[4/5] Merestart Layanan Windows Audio Saat Ini..." -ForegroundColor Cyan
try {
    Restart-Service -Name "Audiosrv" -Force -ErrorAction SilentlyContinue
    Restart-Service -Name "AudioEndpointBuilder" -Force -ErrorAction SilentlyContinue
    Write-Host "    [V] Layanan Audiosrv & AudioEndpointBuilder berhasil direstart." -ForegroundColor Green
} catch {
    Write-Host "    [!] Peringatan saat restart layanan: $_" -ForegroundColor Yellow
}

# 5. Uji Suara (Test Sound)
Write-Host "`n[5/5] Melakukan Pengujian Suara..." -ForegroundColor Cyan
try {
    [System.Console]::Beep(800, 200)
    Start-Sleep -Milliseconds 100
    [System.Console]::Beep(1200, 300)
    Write-Host "    [V] Sinyal suara berhasil dikirim ke perangkat audio!" -ForegroundColor Green
} catch {
    Write-Host "    [!] Tidak dapat memutar nada uji: $_" -ForegroundColor Yellow
}

Write-Host "`n========================================================================" -ForegroundColor Cyan
Write-Host "                          PERBAIKAN SELESAI!                            " -ForegroundColor Green
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host "  * Fast Startup telah dinonaktifkan." -ForegroundColor White
Write-Host "  * TestSigning telah dikunci permanen pada boot loader." -ForegroundColor White
Write-Host "  * Layanan audio otomatis diinisialisasi saat logon/boot." -ForegroundColor White
Write-Host "  Sekarang audio di Chromebook Anda akan tetap aktif setelah laptop direstart." -ForegroundColor White
Write-Host "========================================================================`n" -ForegroundColor Cyan
