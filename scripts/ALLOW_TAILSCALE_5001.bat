@echo off
echo ======================================================
echo    SISGAN PRO - Habilitando Tailscale (puerto 5001)
echo ======================================================
echo.

:: Regla de entrada para TCP 5001 desde la sub‑red Tailscale (100.64.0.0/10)
netsh advfirewall firewall add rule name="SISGAN_PRO_Tailscale_5001_In" dir=in action=allow protocol=TCP localport=5001 remoteip=100.64.0.0/10

:: Regla de salida para TCP 5001 hacia la sub‑red Tailscale
netsh advfirewall firewall add rule name="SISGAN_PRO_Tailscale_5001_Out" dir=out action=allow protocol=TCP localport=5001 remoteip=100.64.0.0/10

echo.
echo ======================================================
echo    REGLAS TAILSCALE 5001 HABILITADAS EN EL FIREWALL
echo ======================================================
pause
