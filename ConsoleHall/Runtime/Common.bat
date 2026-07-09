@echo off

if /i not "%~1"==":LoadParameters" (
	echo.
	powershell -Command "Write-Host 'This file is not meant to be run directly.' -ForegroundColor Red"
	echo Use GenerateProto.bat, GenerateLua.bat, or GenerateCipher.bat instead.
	echo.
	pause
	exit /b 1
)

set "TOOL_NAME=%~2"
set "ENV_TAG=%~3"

if not defined SCRIPT_ROOT (
	set "SCRIPT_ROOT=%~dp0"
	set "SCRIPT_ROOT=!SCRIPT_ROOT:~0,-1!"
)

if not defined RESOLVE_PS1 (
	if exist "%SCRIPT_ROOT%\ResolveParams.ps1" (
		set "RESOLVE_PS1=%SCRIPT_ROOT%\ResolveParams.ps1"
	) else (
		for %%I in ("%SCRIPT_ROOT%\..\ResolveParams.ps1") do set "RESOLVE_PS1=%%~fI"
	)
)

if not exist "!RESOLVE_PS1!" (
	powershell -Command "Write-Host 'ResolveParams.ps1 is not exist' -ForegroundColor Red"
	exit /b 1
)

for /f "usebackq tokens=1,* delims==" %%a in (`powershell -NoProfile -ExecutionPolicy Bypass -File "!RESOLVE_PS1!" -ToolName "!TOOL_NAME!" -EnvTag "!ENV_TAG!" -ScriptRoot "!SCRIPT_ROOT!" 2^>^&1`) do (
	set "%%a=%%b"
)

if not defined param1 (
	powershell -Command "Write-Host 'Failed to resolve parameters for !TOOL_NAME!' -ForegroundColor Red"
	exit /b 1
)

powershell -Command "Write-Host 'Work project is !WORK_PROJECT_PATH!' -ForegroundColor Cyan"

if defined PROTO_SOURCE_PATH (
	powershell -Command "Write-Host 'Proto source is !PROTO_SOURCE_PATH!' -ForegroundColor Cyan"
)
exit /b 0
