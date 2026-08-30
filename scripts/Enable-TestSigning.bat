@echo off
title Aktifkan Windows TestSigning Mode
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Meminta hak akses Administrator...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo ========================================================================
echo   MENGAKTIFKAN WINDOWS TESTSIGNING MODE (UNTUK CHROMEBOOK DRIVER)
echo ========================================================================
echo.
echo Menjalankan perintah bcdedit...
bcdedit /set testsigning on
bcdedit /set nointegritychecks on
echo.
echo ========================================================================
echo [V] TestSigning berhasil diaktifkan!
echo Silakan RESTART laptop Lenovo IdeaPad 3 Anda agar perubahan berlaku.
echo ========================================================================
pause
