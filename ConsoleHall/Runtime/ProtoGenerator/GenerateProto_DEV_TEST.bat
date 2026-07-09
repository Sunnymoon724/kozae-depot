@echo off
chcp 437
cls
cd /d "%~dp0"
echo Generate DEV_TEST start.
call RunProto.bat DEV --no-delete-csv
pause
