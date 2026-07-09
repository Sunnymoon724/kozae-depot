@echo off
call "%~dp0..\CallCommon.bat" GenerateProto CopyProto.bat %*
exit /b %ERRORLEVEL%
