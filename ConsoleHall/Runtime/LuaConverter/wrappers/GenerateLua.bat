@echo off
call "%~dp0..\CallCommon.bat" ConvertLua GenerateLua.bat %*
exit /b %ERRORLEVEL%
