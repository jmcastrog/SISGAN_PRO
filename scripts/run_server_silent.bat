@echo off
:: Script para ejecucion automatica en segundo plano
cd /d "D:\Proyectos\SISGAN_PRO"
:: Asegurar que node_modules existe (por si acaso)
if not exist node_modules (
    npm install
)
:: Iniciar el servidor y guardar un log de errores por si acaso
npm start > server_output.log 2>&1
