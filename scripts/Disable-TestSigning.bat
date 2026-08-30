@echo off
title Nonaktifkan Windows TestSigning Mode
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Meminta hak akses Administrator...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo ========================================================================
echo   MENONAKTIFKAN WINDOWS TESTSIGNING MODE
echo ========================================================================
echo.
echo Menjalankan perintah bcdedit...
bcdedit /set testsigning off
bcdedit /set nointegritychecks off
echo.
echo ========================================================================
echo [V] TestSigning berhasil dinonaktifkan.
echo Silakan RESTART laptop Anda.
echo ========================================================================
pause
