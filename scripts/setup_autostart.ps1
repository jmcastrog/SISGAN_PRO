# Script para registrar el auto-arranque de SISGAN PRO
$taskName = "SISGAN_PRO_Server"
$scriptPath = "D:\Proyectos\SISGAN_PRO\start_background.vbs"
$delphiPath = "D:\Proyectos\SISGAN_PRO\SisganDBViewer\SisganDBViewer.exe"

# Borrar la tarea si ya existe para evitar duplicados
schtasks /delete /tn $taskName /f 2>$null

# Crear la tarea programada que arranca el wrapper al iniciar sesion
$command = "D:\Proyectos\SISGAN_PRO\run_everything_silent.bat"

schtasks /create /tn $taskName /tr "$command" /sc onlogon /rl HIGHEST /f

Write-Host "--------------------------------------------------------"
Write-Host " TAREA ACTUALIZADA CON EXITO"
Write-Host "--------------------------------------------------------"
Write-Host "El sistema arrancara solo al encender la PC:"
Write-Host " 1. Servidor Node.js (Segundo plano)"
Write-Host " 2. Visor Delphi (Icono junto al reloj)"
Write-Host "--------------------------------------------------------"
