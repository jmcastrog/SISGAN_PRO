@echo off
title SISGAN PRO
cd /d "%~dp0"

netstat -an | find "LISTEN" | find ":5000" >nul
if errorlevel 1 (
    if not exist node_modules npm install
    if not exist uploads mkdir uploads
    start /B node server.js
    timeout /t 3 /nobreak >nul
)

start http://localhost:5000
