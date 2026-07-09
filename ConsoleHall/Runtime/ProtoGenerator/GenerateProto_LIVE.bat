@echo off
chcp 437
cls
cd /d "%~dp0"
echo Generate LIVE start.
call RunProto.bat LIVE
pause
