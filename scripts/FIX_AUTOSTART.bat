@echo off
echo ======================================================
echo    SISGAN PRO - Reparando Inicio Automatico
echo ======================================================
echo.
echo Este script necesita permisos de Administrador.
echo.
powershell -ExecutionPolicy Bypass -File "D:\Proyectos\SISGAN_PRO\setup_autostart.ps1"
echo.
echo Iniciando la tarea ahora mismo...
schtasks /run /tn "SISGAN_PRO_Server"
echo.
echo ======================================================
echo    INICIO AUTOMATICO CONFIGURADO
echo ======================================================
pause
