@echo off
setlocal EnableDelayedExpansion
title Solusi Audio Hilang Saat Restart - Lenovo IdeaPad 3 11IGL05

echo ========================================================================
echo   MEMPERBAIKI AUDIO CHROMEBOOK LENOVO IDEAPAD 3 SETELAH RESTART
echo ========================================================================
echo.

:: Memeriksa Hak Akses Administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [X] Hak akses Administrator diperlukan!
    echo     Membuka ulang dengan hak Administrator...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: Jalankan skrip PowerShell perbaikan permanen
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Fix-Audio-Restart-Issue.ps1"

echo.
echo ========================================================================
pause
