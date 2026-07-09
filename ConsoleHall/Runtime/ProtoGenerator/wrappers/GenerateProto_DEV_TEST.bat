@echo off
call "%~dp0..\CallCommon.bat" GenerateProto GenerateProto_DEV_TEST.bat %*
exit /b %ERRORLEVEL%
