@echo off
setlocal enabledelayedexpansion

if "%~1"=="" (
	echo Usage: CallCommon.bat ^<CommonToolFolder^> ^<BatName^> [args...]
	exit /b 1
)
if "%~2"=="" (
	echo Usage: CallCommon.bat ^<CommonToolFolder^> ^<BatName^> [args...]
	exit /b 1
)

set "TOOL_ROOT=%~dp0"
set "TOOL_ROOT=!TOOL_ROOT:~0,-1!"

for %%P in ("!TOOL_ROOT!\..") do set "PROJECT_ROOT=%%~fP"

if not exist "!PROJECT_ROOT!\Project.env" (
	echo Project.env not found in !PROJECT_ROOT!
	exit /b 1
)

for /f "usebackq eol=# tokens=1,* delims==" %%a in ("!PROJECT_ROOT!\Project.env") do (
	if /i "%%a"=="WORK_PROJECT_PATH" set "WRAP_WORK_PROJECT_PATH=%%b"
	if /i "%%a"=="DATA_ROOT_PATH" set "WRAP_DATA_ROOT_PATH=%%b"
	if /i "%%a"=="PROTO_SOURCE_PATH" set "WRAP_PROTO_SOURCE_PATH=%%b"
)

if not defined WRAP_WORK_PROJECT_PATH (
	echo WORK_PROJECT_PATH is not set in Project.env
	exit /b 1
)
if not defined WRAP_DATA_ROOT_PATH set "WRAP_DATA_ROOT_PATH=!WRAP_WORK_PROJECT_PATH!"
if not defined WRAP_PROTO_SOURCE_PATH set "WRAP_PROTO_SOURCE_PATH=!WRAP_DATA_ROOT_PATH!\Document\Proto"

set "COMMON_BAT=!TOOL_ROOT!\..\..\..\Common\Tool\%~1\%~2"
if not exist "!COMMON_BAT!" (
	echo Common bat not found: !COMMON_BAT!
	exit /b 1
)

call "!COMMON_BAT!" %~3 %~4 %~5 %~6 %~7 %~8 %~9
exit /b !ERRORLEVEL!
