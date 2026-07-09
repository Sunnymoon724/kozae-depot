@echo off
call "%~dp0..\CallCommon.bat" GenerateProto GenerateProto_DEV.bat %*
exit /b %ERRORLEVEL%
