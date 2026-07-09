@echo off
call "%~dp0..\CallCommon.bat" GenerateProto GenerateProto_ALL.bat %*
exit /b %ERRORLEVEL%
