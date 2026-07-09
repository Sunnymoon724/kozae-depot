@echo off
chcp 437
cls
cd /d "%~dp0"
echo Generate QA start.
call RunProto.bat QA
pause
