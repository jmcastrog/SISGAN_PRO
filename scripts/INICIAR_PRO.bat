@echo off
title SISGAN PRO - Iniciando...
cd /d "%~dp0"

echo ======================================================
echo    SISGAN PRO - Sistema de Gestion Ganadera
echo ======================================================
echo.

if not exist node_modules (
    echo [1/3] Instalando dependencias necesarias...
    npm install
) else (
    echo [1/3] Dependencias ya instaladas.
)

echo [2/3] Verificando carpetas de datos...
if not exist data mkdir data
if not exist uploads mkdir uploads

echo [3/3] Iniciando Servidor...
echo.
echo >> NOTA: La direccion para conectar desde tu telefono aparecera 
echo >> en la ventana negra a continuacion (URL RED).
echo.
:: Abrir el navegador automaticamente localmente
start http://localhost:5000
npm start

pause
