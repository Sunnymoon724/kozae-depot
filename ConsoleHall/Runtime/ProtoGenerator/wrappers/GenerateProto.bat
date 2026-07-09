@echo off
call "%~dp0..\CallCommon.bat" GenerateProto GenerateProto.bat %*
exit /b %ERRORLEVEL%
