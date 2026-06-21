@echo off
title Muninn IHA Baslatici
color 0B
echo.
echo ====================================================
echo         MUNINN IHA BASLATICIYA HOSGELDINIZ
echo ====================================================
echo.
echo Lutfen Bekleyin... Sistemler Yukleniyor...
echo.

:: PowerShell scriptini yönetici izinlerine gerek kalmadan, execution policy'yi asarak calistir
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0start_muninn.ps1"
