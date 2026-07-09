@echo off
call "%~dp0..\CallCommon.bat" GenerateProto RunProto.bat %*
exit /b %ERRORLEVEL%
