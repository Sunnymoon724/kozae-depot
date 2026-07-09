@echo off
call "%~dp0..\CallCommon.bat" GenerateProto GenerateProto_QA.bat %*
exit /b %ERRORLEVEL%
