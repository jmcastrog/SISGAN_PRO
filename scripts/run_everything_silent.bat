@echo off
cd /d "D:\Proyectos\SISGAN_PRO"
:: 1. Iniciar servidor Node.js en segundo plano (usando el VBS para ocultar la ventana)
start /b wscript.exe "D:\Proyectos\SISGAN_PRO\start_background.vbs"
:: 2. Iniciar el visor de Delphi
start "" "D:\Proyectos\SISGAN_PRO\SisganDBViewer\SisganDBViewer.exe" /silent
