@echo off
cd /d "%~dp0"
setlocal
set SKIP_PAUSE=1
set DELETE_CSV=1

call GenerateProto.bat "DEV"
call GenerateProto.bat "QA"
call GenerateProto.bat "REVIEW"
call GenerateProto.bat "LIVE"
endlocal

if not defined SKIP_PAUSE (
	pause
)
