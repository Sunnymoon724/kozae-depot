@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

set "PACKAGE_ROOT=%~dp0"
set "OUTPUT_ROOT=%PACKAGE_ROOT%ProtoOutput"
set "WORK_ROOT=%PACKAGE_ROOT%ProtoProject"

if exist "%PACKAGE_ROOT%KZProtoBuilder.exe" (
  set "BUILDER_EXE=%PACKAGE_ROOT%KZProtoBuilder.exe"
) else if exist "%PACKAGE_ROOT%Publish\KZProtoBuilder.exe" (
  set "BUILDER_EXE=%PACKAGE_ROOT%Publish\KZProtoBuilder.exe"
  set "OUTPUT_ROOT=%PACKAGE_ROOT%Publish\ProtoOutput"
  set "WORK_ROOT=%PACKAGE_ROOT%Publish\ProtoProject"
) else (
  echo KZProtoBuilder.exe not found.
  echo Place it next to this bat, or under Publish\
  if not defined SKIP_PAUSE pause
  exit /b 1
)

if not exist "%PACKAGE_ROOT%Config.env" (
  echo Config.env not found.
  echo Copy Config.env.example to Config.env and set PROTO_FOLDER / LANGUAGE.
  if not defined SKIP_PAUSE pause
  exit /b 1
)

for /f "usebackq eol=# tokens=1,* delims==" %%A in ("%PACKAGE_ROOT%Config.env") do (
  if not "%%A"=="" set "%%A=%%B"
)

if "%PROTO_FOLDER%"=="" (
  echo PROTO_FOLDER is empty. Edit Config.env.
  if not defined SKIP_PAUSE pause
  exit /b 1
)

if "%LANGUAGE%"=="" set "LANGUAGE=csharp"
if "%KEEP_CSV%"=="" set "KEEP_CSV=0"

if "%PLUGIN_OUTPUT%"=="" (
  echo PLUGIN_OUTPUT is empty. Edit Config.env.
  if not defined SKIP_PAUSE pause
  exit /b 1
)

if "%PROTO_OUTPUT%"=="" (
  echo PROTO_OUTPUT is empty. Edit Config.env.
  if not defined SKIP_PAUSE pause
  exit /b 1
)

for %%I in ("%BUILDER_EXE%") do set "BUILDER_DIR=%%~dpI"
if not exist "%BUILDER_DIR%flatc.exe" if not exist "%PACKAGE_ROOT%flatc.exe" (
  echo flatc.exe not found next to KZProtoBuilder.exe
  if not defined SKIP_PAUSE pause
  exit /b 1
)
if not exist "%BUILDER_DIR%flatc.exe" if exist "%PACKAGE_ROOT%flatc.exe" (
  copy /Y "%PACKAGE_ROOT%flatc.exe" "%BUILDER_DIR%flatc.exe" >nul
)

set "ENV=%~1"
if "%ENV%"=="" (
  echo Usage: GenerateProto.bat ENV
  echo Example: GenerateProto.bat DEV
  if not defined SKIP_PAUSE pause
  exit /b 1
)

if /i "%LANGUAGE%"=="cpp" (
  call :EnsureCmake
  if errorlevel 1 (
    if not defined SKIP_PAUSE pause
    exit /b 1
  )
)

if exist "%WORK_ROOT%" (
  echo Clear leftover ProtoProject
  call :ForceRemoveDir "%WORK_ROOT%"
  if exist "%WORK_ROOT%" (
    echo Failed to clear ProtoProject. Close locks and delete:
    echo   %WORK_ROOT%
    if not defined SKIP_PAUSE pause
    exit /b 1
  )
)

echo Generate %ENV% start. language=%LANGUAGE%
"%BUILDER_EXE%" "%PROTO_FOLDER%" "%ENV%" "%LANGUAGE%"
set "ERR=!errorlevel!"

if not "!ERR!"=="0" (
  echo Generation failed. Error code: !ERR!
  if not defined SKIP_PAUSE pause
  exit /b !ERR!
)

echo Generate %ENV% done.

call :DeployFolder "%OUTPUT_ROOT%\Plugin" "%PLUGIN_OUTPUT%" Plugin
if errorlevel 1 (
  if not defined SKIP_PAUSE pause
  exit /b 1
)

call :DeployFolder "%OUTPUT_ROOT%\Proto" "%PROTO_OUTPUT%" Proto
if errorlevel 1 (
  if not defined SKIP_PAUSE pause
  exit /b 1
)

if exist "%WORK_ROOT%" (
  echo Remove ProtoProject
  call :ForceRemoveDir "%WORK_ROOT%"
)

if "%KEEP_CSV%"=="1" (
  echo KEEP_CSV=1 - leave ProtoOutput
  echo Output: %OUTPUT_ROOT%
) else (
  echo KEEP_CSV=0 - remove ProtoOutput
  call :ForceRemoveDir "%OUTPUT_ROOT%"
)

echo Deployed Plugin -^> %PLUGIN_OUTPUT%
echo Deployed Proto  -^> %PROTO_OUTPUT%
if not defined SKIP_PAUSE pause
exit /b 0

:ForceRemoveDir
set "TARGET=%~1"
if not exist "%TARGET%" exit /b 0
attrib -R "%TARGET%\*" /S /D >nul 2>&1
rmdir /s /q "%TARGET%" >nul 2>&1
if exist "%TARGET%" (
  powershell -NoProfile -Command "Remove-Item -LiteralPath '%TARGET%' -Recurse -Force -ErrorAction SilentlyContinue" >nul 2>&1
)
exit /b 0

:EnsureCmake
where cmake >nul 2>&1
if not errorlevel 1 (
  echo cmake found on PATH
  exit /b 0
)

set "CMAKE_BIN="
if exist "%ProgramFiles%\CMake\bin\cmake.exe" set "CMAKE_BIN=%ProgramFiles%\CMake\bin"
if not defined CMAKE_BIN if exist "%ProgramFiles(x86)%\CMake\bin\cmake.exe" set "CMAKE_BIN=%ProgramFiles(x86)%\CMake\bin"
if not defined CMAKE_BIN if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\2022\BuildTools\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe" set "CMAKE_BIN=%ProgramFiles(x86)%\Microsoft Visual Studio\2022\BuildTools\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin"
if not defined CMAKE_BIN if exist "%ProgramFiles%\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe" set "CMAKE_BIN=%ProgramFiles%\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin"
if not defined CMAKE_BIN if exist "%ProgramFiles%\Microsoft Visual Studio\2022\Professional\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe" set "CMAKE_BIN=%ProgramFiles%\Microsoft Visual Studio\2022\Professional\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin"
if not defined CMAKE_BIN if exist "%ProgramFiles%\Microsoft Visual Studio\2022\Enterprise\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe" set "CMAKE_BIN=%ProgramFiles%\Microsoft Visual Studio\2022\Enterprise\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin"

if not defined CMAKE_BIN (
  echo cmake not found. Install CMake or Visual Studio CMake tools, or add cmake to PATH.
  exit /b 1
)

set "PATH=%CMAKE_BIN%;%PATH%"
echo cmake PATH added: %CMAKE_BIN%
where cmake >nul 2>&1
if errorlevel 1 (
  echo cmake still not runnable after PATH update.
  exit /b 1
)
exit /b 0

:DeployFolder
set "SRC=%~1"
set "DST=%~2"
set "LABEL=%~3"

if not exist "%SRC%" (
  echo %LABEL% source not found: %SRC%
  exit /b 1
)

if not exist "%DST%" mkdir "%DST%"
if errorlevel 1 (
  echo Failed to create %LABEL% destination: %DST%
  exit /b 1
)

echo Deploy %LABEL%: %SRC% -^> %DST%
robocopy "%SRC%" "%DST%" /E /IS /IT /NFL /NDL /NJH /NJS /NC /NS >nul
set "RC=!errorlevel!"
if !RC! GEQ 8 (
  echo Failed to deploy %LABEL%. robocopy code: !RC!
  exit /b 1
)
exit /b 0
