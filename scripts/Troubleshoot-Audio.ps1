# ========================================================================
# Lenovo IdeaPad 3 11IGL05 Chromebook Audio Diagnostic & Troubleshooting Tool
# ========================================================================

[CmdletBinding()]
param()

$Host.UI.RawUI.WindowTitle = "IdeaPad 3 Audio Diagnostic Tool"

function Write-Header {
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host "      LENOVO IDEAPAD 3 11IGL05 AUDIO DIAGNOSTIC & TROUBLESHOOTING       " -ForegroundColor Yellow
    Write-Host "========================================================================" -ForegroundColor Cyan
}

Clear-Host
Write-Header

$report = @()
$report += "========================================================================"
$report += "AUDIO DIAGNOSTIC REPORT - LENOVO IDEAPAD 3 11IGL05 (WINDOWS 10 x64)"
$report += "Generated at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$report += "========================================================================`n"

# 1. OS & Architecture Info
$os = Get-CimInstance Win32_OperatingSystem
Write-Host "[1/6] Memeriksa Sistem Operasi..." -ForegroundColor Cyan
Write-Host "    OS : $($os.Caption) ($($os.OSArchitecture)) Build $($os.BuildNumber)" -ForegroundColor Green
$report += "[1] OS Info: $($os.Caption) ($($os.OSArchitecture)) Build $($os.BuildNumber)"

# 2. TestSigning Status
Write-Host "`n[2/6] Memeriksa Status Windows TestSigning..." -ForegroundColor Cyan
$bcd = bcdedit | Out-String
$isTestSigning = $bcd -match "testsigning\s+Yes"
if ($isTestSigning) {
    Write-Host "    [V] Windows TestSigning: AKTIF (Benar untuk custom driver)" -ForegroundColor Green
    $report += "[2] TestSigning: ENABLED (OK)"
} else {
    Write-Host "    [!] Windows TestSigning: TIDAK AKTIF!" -ForegroundColor Red
    Write-Host "        Jalankan 'Enable-TestSigning.bat' lalu restart laptop agar driver berfungsi." -ForegroundColor Yellow
    $report += "[2] TestSigning: DISABLED (Action Required)"
}

# 3. Audio Services
Write-Host "`n[3/6] Memeriksa Layanan Windows Audio..." -ForegroundColor Cyan
$audiosrv = Get-Service -Name "Audiosrv" -ErrorAction SilentlyContinue
$endpoint = Get-Service -Name "AudioEndpointBuilder" -ErrorAction SilentlyContinue

$audiosrvColor = if ($audiosrv -and $audiosrv.Status -eq "Running") { "Green" } else { "Red" }
$endpointColor = if ($endpoint -and $endpoint.Status -eq "Running") { "Green" } else { "Red" }
Write-Host "    Audiosrv             : $($audiosrv.Status)" -ForegroundColor $audiosrvColor
Write-Host "    AudioEndpointBuilder : $($endpoint.Status)" -ForegroundColor $endpointColor
$report += "[3] Audio Services: Audiosrv=$($audiosrv.Status), AudioEndpointBuilder=$($endpoint.Status)"

# 4. Hardware ID Scan
Write-Host "`n[4/6] Memindai Hardware Audio Chromebook..." -ForegroundColor Cyan
$targetHwIds = @(
    @{ Name = "Intel Gemini Lake HD Audio Controller"; Pattern = "3198" },
    @{ Name = "Maxim MAX98357A Speaker Amplifier";   Pattern = "MX98357" },
    @{ Name = "Maxim MAX98360A Speaker Amplifier";   Pattern = "MX98360" },
    @{ Name = "Dialog DA7219 Headphone Codec";       Pattern = "DLGS7219" },
    @{ Name = "Realtek ALC5682 Audio Codec";         Pattern = "10EC5682" }
)

$report += "`n[4] Hardware Devices:"
foreach ($item in $targetHwIds) {
    $matched = Get-PnpDevice -ErrorAction SilentlyContinue | Where-Object { $_.InstanceId -like "*$($item.Pattern)*" }
    if ($matched) {
        foreach ($dev in $matched) {
            $color = if ($dev.Status -eq "OK") { "Green" } else { "Yellow" }
            Write-Host "    [$($dev.Status)] $($item.Name)" -ForegroundColor $color
            Write-Host "        ID     : $($dev.InstanceId)" -ForegroundColor Gray
            Write-Host "        Driver : $($dev.FriendlyName)" -ForegroundColor Gray
            $report += "    - [$($dev.Status)] $($item.Name) | ID: $($dev.InstanceId) | Name: $($dev.FriendlyName)"
        }
    } else {
        Write-Host "    [-] $($item.Name): Belum terdeteksi di bus ACPI/PCI" -ForegroundColor DarkGray
        $report += "    - [NOT FOUND] $($item.Name)"
    }
}

# 5. Playback Devices Check
Write-Host "`n[5/6] Memeriksa Output Audio Aktif..." -ForegroundColor Cyan
$soundDevices = Get-CimInstance Win32_SoundDevice -ErrorAction SilentlyContinue
if ($soundDevices) {
    $report += "`n[5] Sound Devices (WMI):"
    foreach ($sd in $soundDevices) {
        Write-Host "    [V] $($sd.Caption) (Status: $($sd.Status))" -ForegroundColor Green
        $report += "    - $($sd.Caption) | Status: $($sd.Status) | PNPDeviceID: $($sd.PNPDeviceID)"
    }
} else {
    Write-Host "    [!] Belum ada perangkat suara aktif yang terdaftar di Windows." -ForegroundColor Yellow
    $report += "`n[5] Sound Devices: NONE ACTIVE"
}

# 6. Audio Playback Test
Write-Host "`n[6/6] Menjalankan Uji Suara (Test Beep)..." -ForegroundColor Cyan
try {
    [console]::beep(800, 300)
    [console]::beep(1200, 400)
    Write-Host "    [V] Sinyal suara berhasil dikirim ke speaker/headphone." -ForegroundColor Green
    $report += "`n[6] Sound Test: Beep signal sent successfully"
} catch {
    Write-Host "    [!] Tidak dapat memutar suara beep: $_" -ForegroundColor Yellow
    $report += "`n[6] Sound Test Failed: $_"
}

# Save Report
$reportPath = "$PSScriptRoot\audio_diag_report.txt"
$report | Out-File -FilePath $reportPath -Encoding utf8
Write-Host "`n========================================================================" -ForegroundColor Cyan
Write-Host "Laporan diagnostik lengkap telah disimpan ke:" -ForegroundColor Green
Write-Host "  $reportPath" -ForegroundColor Yellow
Write-Host "========================================================================`n" -ForegroundColor Cyan
