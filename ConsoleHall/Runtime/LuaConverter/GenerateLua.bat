@echo off

if not defined DONT_CLEAR (
	chcp 437
	cls
)

setlocal enabledelayedexpansion

cd /d "%~dp0"
set "SCRIPT_ROOT=%CD%"

	if exist "%SCRIPT_ROOT%\Common.bat" (
		set "COMMON_BAT=%SCRIPT_ROOT%\Common.bat"
	) else (
		for %%I in ("%SCRIPT_ROOT%\..\Common.bat") do set "COMMON_BAT=%%~fI"
)

echo Current path : %CD%

echo.
powershell -Command "Write-Host 'Set parameters' -ForegroundColor Blue"
echo.

call "!COMMON_BAT!" :LoadParameters LuaConverter "" || exit /b 1

echo.
powershell -Command "Write-Host 'Start generation' -ForegroundColor Magenta"
echo.

cd /d "%SCRIPT_ROOT%\KZLuaConverter"

KZLuaConverter.exe "!param1!" "!param2!"

if !errorlevel! neq 0 (
	powershell -Command "Write-Host 'Generation is failed. Error code: !errorlevel!' -ForegroundColor Red"

	pause
	exit /b 1
)

echo.
powershell -Command "Write-Host 'Finish generation' -ForegroundColor Magenta"
echo.

if not defined SKIP_PAUSE (
	pause
)
