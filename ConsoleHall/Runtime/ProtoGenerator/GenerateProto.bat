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

if "%~1"=="" (
	powershell -Command "Write-Host 'Development environment is empty.' -ForegroundColor Red"

	pause
	exit /b 1
)

set "environment=%~1"

call "!COMMON_BAT!" :LoadParameters ProtoGenerator "%environment%" || exit /b 1

echo.
powershell -Command "Write-Host 'Start generation' -ForegroundColor Magenta"
echo.

cd /d "%SCRIPT_ROOT%\KZProtoGenerator"

KZProtoGenerator.exe "!param1!" "!param2!" "%environment%"

if !errorlevel! neq 0 (
	powershell -Command "Write-Host 'Generation is failed. Error code: !errorlevel!' -ForegroundColor Red"

	pause
	exit /b 1
)

echo.
powershell -Command "Write-Host 'Move bytes files' -ForegroundColor Blue"
echo.

if not exist "!param3!" (
	mkdir "!param3!"
)

set "destinationFolder=..\ProtoOutput\Proto\*.bytes"

if exist !destinationFolder! (
	move /Y !destinationFolder! "!param3!" >nul 2>&1

	if !errorlevel! equ 0 (
		echo Bytes files have been moved successfully.
	) else (
		powershell -Command "Write-Host 'Move failed for !destinationFolder!. Error code: !errorlevel!' -ForegroundColor Red"

		pause
		exit /b 1
	)
)

set "targetFolder=%SCRIPT_ROOT%\ProtoOutput"

if exist "%targetFolder%" (
	echo.
	powershell -Command "Write-Host 'Delete Dummy files' -ForegroundColor Blue"
	echo.

	cd /d "%SCRIPT_ROOT%"

	echo Target folder for deletion: "%targetFolder%"

	if defined DELETE_CSV (
		powershell -NoProfile -Command "Remove-Item -LiteralPath '%targetFolder%' -Recurse -Force -ErrorAction SilentlyContinue"
	) else (
		powershell -NoProfile -Command "Get-ChildItem -Path '%targetFolder%' -Force | Where-Object { $_.Name -ne 'Csv' } | ForEach-Object { Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction SilentlyContinue }"
	)

	if !errorlevel! equ 0 (
		echo Dummy files have been deleted successfully.
	) else (
		powershell -Command "Write-Host 'Delete failed for %cd%. Error code: !errorlevel!' -ForegroundColor Red"

		pause
		exit /b 1
	)
)

echo.
powershell -Command "Write-Host 'Finish generation' -ForegroundColor Magenta"
echo.

if not defined SKIP_PAUSE (
	pause
)
