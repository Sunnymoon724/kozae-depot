@echo off
cd /d "%~dp0"

if "%~1"=="" (
	echo Usage: RunProto.bat ENV [--no-copy] [--no-delete-csv]
	exit /b 1
)

setlocal enabledelayedexpansion
set "ENV=%~1"
set "DO_COPY=1"
set "DELETE_CSV=1"
set "SKIP_PAUSE=1"

:ParseArgs
shift
if "%~1"=="" goto Run
if /i "%~1"=="--no-copy" set "DO_COPY="
if /i "%~1"=="--no-delete-csv" set "DELETE_CSV="
goto ParseArgs

:Run
call GenerateProto.bat "!ENV!"
if !errorlevel! neq 0 exit /b !errorlevel!

if defined DO_COPY (
	set "CLEAR_SCREEN="
	call CopyProto.bat "!ENV!"
)
endlocal
exit /b 0
