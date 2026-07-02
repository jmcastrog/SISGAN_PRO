@echo off
echo ======================================================
echo    SISGAN PRO - Habilitando Tailscale Full
echo ======================================================
echo.
echo Este script necesita permisos de Administrador.
echo.
netsh advfirewall firewall add rule name="SISGAN_PRO_Tailscale_In" dir=in action=allow remoteip=100.64.0.0/10
netsh advfirewall firewall add rule name="SISGAN_PRO_Tailscale_Out" dir=out action=allow remoteip=100.64.0.0/10
echo.
echo ======================================================
echo    TAILSCALE HABILITADO EN EL FIREWALL
echo ======================================================
pause
