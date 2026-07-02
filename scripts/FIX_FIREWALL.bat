@echo off
echo ======================================================
echo    SISGAN PRO - Reparando Firewall
echo ======================================================
echo.
echo Este script necesita permisos de Administrador.
echo.
netsh advfirewall firewall add rule name="SISGAN_PRO_Node" dir=in action=allow protocol=TCP localport=5000
netsh advfirewall firewall add rule name="SISGAN_PRO_Delphi" dir=in action=allow protocol=TCP localport=5001
echo.
echo ======================================================
echo    REGLAS AGREGADAS CON EXITO
echo ======================================================
pause
