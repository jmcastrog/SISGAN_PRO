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
echo Servidor corriendo en http://localhost:5000
:: Abrir el navegador automaticamente
start http://localhost:5000
echo.
npm start

pause
