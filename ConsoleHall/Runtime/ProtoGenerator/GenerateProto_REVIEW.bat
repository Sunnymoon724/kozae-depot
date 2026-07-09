@echo off
chcp 437
cls
cd /d "%~dp0"
echo Generate REVIEW start.
call RunProto.bat REVIEW
pause
