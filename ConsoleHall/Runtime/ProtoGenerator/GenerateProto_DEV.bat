@echo off
chcp 437
cls
cd /d "%~dp0"
echo Generate DEV start.
call RunProto.bat DEV
pause
