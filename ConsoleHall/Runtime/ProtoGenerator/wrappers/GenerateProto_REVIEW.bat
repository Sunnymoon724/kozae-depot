@echo off
call "%~dp0..\CallCommon.bat" GenerateProto GenerateProto_REVIEW.bat %*
exit /b %ERRORLEVEL%
