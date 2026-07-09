@echo off

if not defined DONT_CLEAR (
	chcp 437
	cls
)

setlocal enabledelayedexpansion

@rem ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
@rem Set project path
cd /d "%~dp0"
set "scriptRoot=%~dp0"

echo Current path : %cd%

echo.
@rem ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
@rem Start helper generation
powershell -Command "Write-Host 'Start helper generation' -ForegroundColor Magenta"
echo.

echo.
@rem ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
@rem Build helper project
powershell -Command "Write-Host 'Build helper project' -ForegroundColor Blue"
echo.

set "projectRoot=..\..\KoZaeLibrary\Helper"

for /r %projectRoot% %%a in (*.csproj) do (

	set "projectName=%%~na"

	mkdir "KoZaeHelper\!projectName!" >nul 2>&1

	echo Build %%a

	dotnet clean "%%a" -c Release

	dotnet build "%%a" -c Release /p:DebugSymbols=true /p:DebugType=Portable -o "KoZaeHelper" || (
		powershell -Command "Write-Host 'Build failed for %%a' -ForegroundColor Red"
		echo Build failed for %%a. Check the logs for more details.

		pause
		exit /b 1
	)
)

echo.
@rem ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
@rem Load helper config
set "configRoot=%scriptRoot%..\ConfigOffice"
set "PROJECTS_ROOT="
set "HELPER_PROJECT="

for /f "usebackq eol=# tokens=1,* delims==" %%a in ("%configRoot%\Paths.env") do (
	if /i "%%a"=="PROJECTS_ROOT" set "PROJECTS_ROOT=%%b"
	if /i "%%a"=="HELPER_PROJECT" set "HELPER_PROJECT=%%b"
)

if not defined PROJECTS_ROOT (
	powershell -Command "Write-Host 'PROJECTS_ROOT is not set in ConfigOffice\Paths.env' -ForegroundColor Red"

	pause
	exit /b 1
)

if not defined HELPER_PROJECT (
	powershell -Command "Write-Host 'HELPER_PROJECT is not set in ConfigOffice\Paths.env' -ForegroundColor Red"

	pause
	exit /b 1
)

set "PROJECT_REL_PATH="
set "TOOL_SUBPATH="

call :GetProjectPath "!HELPER_PROJECT!"
call :GetToolPath "Helper"

if not defined PROJECT_REL_PATH (
	powershell -Command "Write-Host 'Helper project alias is not defined: !HELPER_PROJECT!' -ForegroundColor Red"

	pause
	exit /b 1
)

if not defined TOOL_SUBPATH (
	powershell -Command "Write-Host 'Tool path is not defined for Helper in ConfigOffice\ToolPaths.map' -ForegroundColor Red"

	pause
	exit /b 1
)

set "destinationFolder=!PROJECTS_ROOT!\!PROJECT_REL_PATH!\!TOOL_SUBPATH!"

echo Projects root : !PROJECTS_ROOT!
echo Helper target : !destinationFolder!

echo.
@rem ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
@rem Move files
powershell -Command "Write-Host 'Move files' -ForegroundColor Blue"
echo.

set "sourceFolder=KoZaeHelper"

if not exist "!destinationFolder!" (
	echo Create path "!destinationFolder!"
	mkdir "!destinationFolder!"
)

for %%m in ("%sourceFolder%\*.dll" "%sourceFolder%\*.pdb") do (
	move /Y "%%m" "!destinationFolder!\" >nul 2>&1

	if !errorlevel! neq 0 (
		powershell -Command "Write-Host 'Move failed for %%m. Error code: !errorlevel!' -ForegroundColor Red"

		pause
		exit /b 1
	) else (
		for %%x in ("!destinationFolder!") do set "absDestinationFolder=%%~fx"
		echo   Move is done. "[%%~fm -> !absDestinationFolder!]"
	)
)

echo.
@rem ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
@rem Delete helper project
powershell -Command "Write-Host 'Delete helper project' -ForegroundColor Blue"
echo.

set "deletePath=%scriptRoot%KoZaeHelper"
echo Delete path !deletePath!

if exist "%deletePath%" (
	powershell -command "$shell = New-Object -ComObject Shell.Application; $folder = $shell.Namespace('%deletePath%'); if ($folder) { $folder.Self.InvokeVerb('delete') }"
)

if %errorlevel% neq 0 (
	powershell -Command "Write-Host 'Delete failed for %deletePath%. Error code: %errorlevel%' -ForegroundColor Red"

	pause
	exit /b 1
)

echo.
@rem ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
@rem Finish helper generation
powershell -Command "Write-Host 'Finish helper generation' -ForegroundColor Magenta"
echo.

if not defined SKIP_PAUSE (
	pause
)

exit /b 0

:GetProjectPath
set "PROJECT_REL_PATH="
for /f "usebackq eol=# tokens=1,* delims==" %%k in ("%configRoot%\Projects.list") do (
	if /i "%%k"=="%~1" set "PROJECT_REL_PATH=%%l"
)
exit /b 0

:GetToolPath
set "TOOL_SUBPATH="
for /f "usebackq eol=# tokens=1,* delims==" %%k in ("%configRoot%\ToolPaths.map") do (
	if /i "%%k"=="%~1" set "TOOL_SUBPATH=%%l"
)
exit /b 0