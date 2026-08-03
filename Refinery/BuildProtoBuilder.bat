@echo off
setlocal enabledelayedexpansion

if not defined DONT_CLEAR (
	chcp 437
	cls
)

cd /d "%~dp0"
set "SCRIPT_ROOT=%~dp0"
set "PROTO_ROOT=%SCRIPT_ROOT%..\..\KoZaeRefinery\Proto"
for %%I in ("%PROTO_ROOT%") do set "PROTO_ROOT=%%~fI"
set "PACKAGE_ROOT=%SCRIPT_ROOT%ProtoBuilder"

echo Current path : %CD%
echo Proto root : %PROTO_ROOT%

if not exist "%PROTO_ROOT%\pyproject.toml" (
	powershell -Command "Write-Host 'KoZaeRefinery Proto not found at %PROTO_ROOT%' -ForegroundColor Red"
	pause
	exit /b 1
)

echo.
powershell -Command "Write-Host 'Start ProtoBuilder publish build' -ForegroundColor Magenta"
echo.

cd /d "%PROTO_ROOT%"

if not exist ".venv\Scripts\python.exe" (
	echo Creating venv...
	python -m venv .venv
)

set "PY=%PROTO_ROOT%\.venv\Scripts\python.exe"
"%PY%" -m pip install -e . -q
"%PY%" -m pip install pyinstaller -q

if exist "build" rmdir /s /q "build"
if exist "dist" rmdir /s /q "dist"

echo.
powershell -Command "Write-Host 'Build KZProtoBuilder.exe' -ForegroundColor Blue"
echo.

"%PY%" -m PyInstaller --noconfirm --clean --onefile --name KZProtoBuilder --paths Source --hidden-import openpyxl --hidden-import flatbuffers --collect-submodules KZProtoBuilder --collect-all openpyxl kz_proto_builder_cli.py
if errorlevel 1 (
	powershell -Command "Write-Host 'PyInstaller failed.' -ForegroundColor Red"
	pause
	exit /b 1
)

if not exist "%PACKAGE_ROOT%" mkdir "%PACKAGE_ROOT%"

copy /Y "%PROTO_ROOT%\dist\KZProtoBuilder.exe" "%PACKAGE_ROOT%\KZProtoBuilder.exe" >nul

if exist "%PROTO_ROOT%\flatc.exe" (
	copy /Y "%PROTO_ROOT%\flatc.exe" "%PACKAGE_ROOT%\flatc.exe" >nul
) else if exist "%PROTO_ROOT%\Tools\flatc\flatc.exe" (
	copy /Y "%PROTO_ROOT%\Tools\flatc\flatc.exe" "%PACKAGE_ROOT%\flatc.exe" >nul
) else (
	powershell -Command "Write-Host 'WARNING: flatc.exe not found under Proto. Copy flatc.exe next to KZProtoBuilder.exe manually.' -ForegroundColor Yellow"
)

if not exist "%PACKAGE_ROOT%\Config.env" (
	if exist "%PACKAGE_ROOT%\Config.env.example" (
		copy /Y "%PACKAGE_ROOT%\Config.env.example" "%PACKAGE_ROOT%\Config.env" >nul
	)
)

echo.
powershell -Command "Write-Host 'ProtoBuilder package ready' -ForegroundColor Magenta"
echo   %PACKAGE_ROOT%\KZProtoBuilder.exe
echo Edit ProtoBuilder\Config.env then run GenerateProto_DEV.bat

if not defined SKIP_PAUSE (
	pause
)

endlocal
exit /b 0
