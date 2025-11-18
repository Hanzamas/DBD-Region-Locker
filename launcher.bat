@echo off
Title Hanz Jamal Region Locker Launcher

:: --- BAGIAN 1: CEK APAKAH UDAH RUN AS ADMIN? ---
:: Kalau belum admin, dia bakal minta izin otomatis.
net session >nul 2>&1
if %errorLevel% == 0 (
    goto :run_script
) else (
    echo Meminta akses Administrator...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit
)

:run_script
:: --- BAGIAN 2: JALANIN SCRIPT DENGAN BYPASS ---
:: "%~dp0" artinya folder tempat file ini berada.
:: Jadi script .ps1 dan file .bat ini HARUS SATU FOLDER.

echo Sedang membuka DbD Region Locker...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0dbd locker by hanz.ps1"

pause