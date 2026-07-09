@echo off

if defined CLEAR_SCREEN (
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

if "%~1"=="" (
	powershell -Command "Write-Host 'Development environment is empty.' -ForegroundColor Red"

	pause
	exit /b 1
)

set "environment=%~1"

call "!COMMON_BAT!" :LoadParameters ProtoGenerator "%environment%" || exit /b 1

echo.
powershell -Command "Write-Host 'Copy bytes files' -ForegroundColor Blue"
echo.

if not exist "!param5!" (
	mkdir "!param5!"
)

xcopy /Y /I "!param4!" "!param5!\" >nul 2>&1

if !errorlevel! leq 1 (
	echo Bytes files have been copied successfully.
) else (
	powershell -Command "Write-Host 'Copy failed for !param4! to !param5!. Error code: !errorlevel!' -ForegroundColor Red"

	pause
	exit /b 1
)

echo.
powershell -Command "Write-Host 'Finish copy' -ForegroundColor Magenta"
echo.

if not defined SKIP_PAUSE (
	pause
)
