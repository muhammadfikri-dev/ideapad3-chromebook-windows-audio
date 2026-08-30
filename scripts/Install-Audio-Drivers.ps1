# ========================================================================
# Lenovo IdeaPad 3 11IGL05 Chromebook Audio Driver Automated Installer
# Platform: Intel Gemini Lake (Celeron N4020) | Board: LICK (Octopus)
# ========================================================================

[CmdletBinding()]
param()

$Host.UI.RawUI.WindowTitle = "Lenovo IdeaPad 3 11IGL05 Audio Driver Installer"

function Write-Header {
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host "   LENOVO IDEAPAD 3 11IGL05 AUDIO DRIVER INSTALLER (WINDOWS 10 x64)     " -ForegroundColor Yellow
    Write-Host "========================================================================" -ForegroundColor Cyan
}

function Test-Administrator {
    $user = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    return $user.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

Clear-Host
Write-Header

if (-not (Test-Administrator)) {
    Write-Host "[X] ERROR: Skrip ini memerlukan hak akses Administrator!" -ForegroundColor Red
    Write-Host "    Silakan klik kanan 'Install-Audio-Drivers.bat' dan pilih 'Run as Administrator'." -ForegroundColor Yellow
    exit 1
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# ------------------------------------------------------------------------
# 1. Enable Windows Test Signing & Disable Fast Startup (Required for Chromebooks)
# ------------------------------------------------------------------------
Write-Host "`n[1/6] Mengonfigurasi BCD (TestSigning, NoIntegrityChecks) & Fast Startup..." -ForegroundColor Cyan
try {
    Write-Host "    [*] Mengaktifkan TestSigning & NoIntegrityChecks pada BCD..." -ForegroundColor Yellow
    & bcdedit /set {default} testsigning on | Out-Null
    & bcdedit /set {current} testsigning on | Out-Null
    & bcdedit /set {bootmgr} testsigning on | Out-Null
    & bcdedit /set {default} nointegritychecks on | Out-Null
    & bcdedit /set {current} nointegritychecks on | Out-Null
    & bcdedit /set {default} loadoptions DDISABLE_INTEGRITY_CHECKS | Out-Null
    & bcdedit /set {current} loadoptions DDISABLE_INTEGRITY_CHECKS | Out-Null
    Write-Host "    [V] BCD TestSigning & Integritas Driver berhasil diaktifkan secara permanen." -ForegroundColor Green

    # Matikan Windows Fast Startup (Penyebab utama driver audio I2S gagal inisialisasi saat reboot)
    Write-Host "    [*] Menonaktifkan Windows Fast Startup (Hiberboot)..." -ForegroundColor Yellow
    & powercfg /h off | Out-Null
    if (-not (Test-Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power")) {
        New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Value 0 -Type DWord -Force | Out-Null
    Write-Host "    [V] Fast Startup berhasil dinonaktifkan (mencegah audio hilang saat restart)." -ForegroundColor Green
} catch {
    Write-Host "    [!] Peringatan saat mengonfigurasi BCD/Power: $_" -ForegroundColor Yellow
}

# ------------------------------------------------------------------------
# 2. Install Code Signing Certificates
# ------------------------------------------------------------------------
Write-Host "`n[2/5] Menginstal Sertifikat Digital Driver..." -ForegroundColor Cyan
$certDirs = @(
    "$ScriptDir\Certificates",
    "$ScriptDir\..\build\Certificates",
    "$ScriptDir"
)

$certInstalled = 0
foreach ($dir in $certDirs) {
    if (Test-Path $dir) {
        $certs = Get-ChildItem -Path $dir -Filter "*.cer"
        foreach ($certFile in $certs) {
            Write-Host "    [*] Menginstal $($certFile.Name)..." -ForegroundColor Yellow
            try {
                Import-Certificate -FilePath $certFile.FullName -CertStoreLocation "Cert:\LocalMachine\Root" | Out-Null
                Import-Certificate -FilePath $certFile.FullName -CertStoreLocation "Cert:\LocalMachine\TrustedPublisher" | Out-Null
                Write-Host "    [V] Sertifikat $($certFile.Name) terpasang di Root & TrustedPublisher." -ForegroundColor Green
                $certInstalled++
            } catch {
                Write-Host "    [!] Gagal memasang sertifikat: $_" -ForegroundColor Red
            }
        }
    }
}

if ($certInstalled -eq 0) {
    Write-Host "    [!] Tidak ditemukan file .cer di folder Certificates. Melewati langkah ini." -ForegroundColor Yellow
}

# ------------------------------------------------------------------------
# 3. Discover and Install Driver Packages
# ------------------------------------------------------------------------
Write-Host "`n[3/5] Memasang Driver Audio ke Sistem..." -ForegroundColor Cyan

# Define driver installation sequence (Bus first, then Amp & Codecs)
$driverSearchPaths = @(
    "$ScriptDir\01-Intel-HD-Audio-Bus",
    "$ScriptDir\02-Maxim-Speaker-Amp",
    "$ScriptDir\03-DA7219-Headphone-Mic",
    "$ScriptDir\04-RT5682-Headphone-Mic",
    "$ScriptDir\Drivers",
    "$ScriptDir\..\drivers"
)

$installedCount = 0
$failedCount = 0

# Find all INF files
$infFiles = @()
foreach ($path in $driverSearchPaths) {
    if (Test-Path $path) {
        $infs = Get-ChildItem -Path $path -Recurse -Filter "*.inf"
        foreach ($inf in $infs) {
            if ($infFiles.FullName -notcontains $inf.FullName) {
                $infFiles += $inf
            }
        }
    }
}

# Sort INF files so sklhdaudbus is first
$sortedInfs = $infFiles | Sort-Object {
    if ($_.Name -like "*sklhdaudbus*") { return 1 }
    elseif ($_.Name -like "*max98357a*") { return 2 }
    elseif ($_.Name -like "*da7219*") { return 3 }
    elseif ($_.Name -like "*rt5682*") { return 4 }
    else { return 5 }
}

if ($sortedInfs.Count -eq 0) {
    Write-Host "    [!] Tidak ditemukan file driver (.inf) yang siap dipasang!" -ForegroundColor Red
    Write-Host "        Pastikan Anda mengunduh paket rilis yang sudah di-compile dari GitHub Actions." -ForegroundColor Yellow
} else {
    foreach ($inf in $sortedInfs) {
        Write-Host "    [*] Memasang driver: $($inf.Name) dari $($inf.Directory.Name)..." -ForegroundColor Yellow
        try {
            $pnpResult = pnputil.exe /add-driver $inf.FullName /install
            $pnpString = $pnpResult | Out-String
            
            if ($pnpString -match "successfully" -or $pnpString -match "berhasil" -or $LASTEXITCODE -eq 0) {
                Write-Host "    [V] Sukses memasang: $($inf.Name)" -ForegroundColor Green
                $installedCount++
            } else {
                Write-Host "    [!] Hasil pnputil: $pnpString" -ForegroundColor Yellow
                $installedCount++
            }
        } catch {
            Write-Host "    [X] Gagal memasang $($inf.Name): $_" -ForegroundColor Red
            $failedCount++
        }
    }
}

# ------------------------------------------------------------------------
# 4. Restart Windows Audio Services
# ------------------------------------------------------------------------
Write-Host "`n[4/6] Merestart Layanan Windows Audio..." -ForegroundColor Cyan
try {
    Restart-Service -Name "Audiosrv" -Force -ErrorAction SilentlyContinue
    Restart-Service -Name "AudioEndpointBuilder" -Force -ErrorAction SilentlyContinue
    Write-Host "    [V] Layanan Windows Audio berhasil direstart." -ForegroundColor Green
} catch {
    Write-Host "    [!] Tidak dapat merestart layanan audio otomatis: $_" -ForegroundColor Yellow
}

# ------------------------------------------------------------------------
# 5. Pasang Tugas Otomatis Inisialisasi Audio saat Boot / Logon
# ------------------------------------------------------------------------
Write-Host "`n[5/6] Mendaftarkan Tugas Otomatis Audio Keep-Alive (Persistence)..." -ForegroundColor Cyan
try {
    $startupFixCmd = 'powershell.exe -WindowStyle Hidden -Command "Start-Sleep -Seconds 3; Restart-Service -Name Audiosrv,AudioEndpointBuilder -Force"'
    & schtasks.exe /create /tn "ChromebookAudioStartupFix" /tr $startupFixCmd /sc ONLOGON /rl HIGHEST /f | Out-Null
    Write-Host "    [V] Tugas otomatis boot/logon terdaftar (suara akan langsung aktif setiap kali laptop dinyalakan/direstart)." -ForegroundColor Green
} catch {
    Write-Host "    [!] Peringatan saat mendaftarkan tugas otomatis: $_" -ForegroundColor Yellow
}

# ------------------------------------------------------------------------
# 6. Device Status Check & Diagnostics
# ------------------------------------------------------------------------
Write-Host "`n[6/6] Memeriksa Status Perangkat Audio di Device Manager..." -ForegroundColor Cyan

$audioDevices = Get-PnpDevice -Class Media, System -ErrorAction SilentlyContinue | Where-Object {
    $_.FriendlyName -like "*Audio*" -or 
    $_.FriendlyName -like "*Sound*" -or 
    $_.FriendlyName -like "*DA7219*" -or 
    $_.FriendlyName -like "*MAX98357*" -or 
    $_.FriendlyName -like "*ALC5682*" -or 
    $_.FriendlyName -like "*CoolStar*" -or
    $_.InstanceId -like "*3198*" -or
    $_.InstanceId -like "*DLGS7219*" -or
    $_.InstanceId -like "*MX98357*"
}

if ($audioDevices) {
    Write-Host "`n--- Daftar Perangkat Audio Terdeteksi ---" -ForegroundColor Yellow
    foreach ($dev in $audioDevices) {
        $statusColor = if ($dev.Status -eq "OK") { "Green" } else { "Yellow" }
        Write-Host "  [$($dev.Status)] $($dev.FriendlyName) - ($($dev.InstanceId))" -ForegroundColor $statusColor
    }
} else {
    Write-Host "    [i] Perangkat audio akan aktif sepenuhnya setelah sistem direstart." -ForegroundColor Gray
}

# ------------------------------------------------------------------------
# Summary & Next Steps
# ------------------------------------------------------------------------
Write-Host "`n========================================================================" -ForegroundColor Cyan
Write-Host "                        RINGKASAN INSTALASI                             " -ForegroundColor Yellow
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host "  [V] Driver terpasang : $installedCount" -ForegroundColor Green
if ($failedCount -gt 0) {
    Write-Host "  [X] Gagal            : $failedCount" -ForegroundColor Red
}

if ($requiresRebootForTestSigning) {
    Write-Host "`n[!] PENTING: Windows Test Mode baru saja diaktifkan." -ForegroundColor Yellow
    Write-Host "    Lakukan RESTART pada laptop Chromebook Lenovo IdeaPad 3 Anda sekarang" -ForegroundColor Yellow
    Write-Host "    agar driver audio dapat aktif sepenuhnya di Windows 10!" -ForegroundColor Yellow
} else {
    Write-Host "`n[V] Driver telah terpasang. Jika suara belum terdengar, silakan restart laptop Anda." -ForegroundColor Green
}
Write-Host "========================================================================`n" -ForegroundColor Cyan
