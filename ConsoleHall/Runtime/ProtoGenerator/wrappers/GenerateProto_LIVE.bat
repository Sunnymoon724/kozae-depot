@echo off
call "%~dp0..\CallCommon.bat" GenerateProto GenerateProto_LIVE.bat %*
exit /b %ERRORLEVEL%
