@echo off
setlocal EnableDelayedExpansion
title Lenovo IdeaPad 3 11IGL05 Audio Driver Installer

:: Check for Administrator Privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Requesting Administrator Privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

pushd "%~dp0"
echo ========================================================================
echo    LENOVO IDEAPAD 3 11IGL05 CHROMEBOOK AUDIO DRIVER INSTALLER
echo    Target OS: Windows 10 64-bit ^| Platform: Intel Gemini Lake
echo ========================================================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-Audio-Drivers.ps1"

echo.
echo ========================================================================
echo Proses instalasi selesai. Tekan sembarang tombol untuk keluar...
echo ========================================================================
pause >nul
popd
