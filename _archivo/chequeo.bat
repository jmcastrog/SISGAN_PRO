@echo off
netsh advfirewall firewall show rule name="SISGAN_PRO_Tailscale_5001_In"
netsh advfirewall firewall show rule name="SISGAN_PRO_Tailscale_5001_Out"
pause