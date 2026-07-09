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
@rem Start console generation
powershell -Command "Write-Host 'Start console generation' -ForegroundColor Magenta"
echo.

echo.
@rem ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
@rem Build console project
powershell -Command "Write-Host 'Build console project' -ForegroundColor Blue"
echo.

set "projectRoot=..\..\KoZaeLibrary\Console"

@rem Library projects (KZCommon, KZProtoCommon) are referenced only — publish Exe projects only
for /r %projectRoot% %%c in (*.csproj) do (
	findstr /C:"<OutputType>Exe</OutputType>" "%%c" >nul 2>&1

	if !errorlevel! equ 0 (
		set "projectName=%%~nc"

		mkdir "KoZaeConsole\!projectName!" >nul 2>&1

		echo Build %%c

		dotnet publish "%%c" -c Release --self-contained false -o "KoZaeConsole\!projectName!" || (
			powershell -Command "Write-Host 'Build failed for %%c' -ForegroundColor Red"

			pause
			exit /b 1
		)
	) else (
		echo Skip %%c
	)
)

echo.
@rem ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
@rem Load copy config
set "configRoot=%scriptRoot%..\ConfigOffice"
set "runtimeRoot=%scriptRoot%Runtime"
set "PROJECTS_ROOT="

for /f "usebackq eol=# tokens=1,* delims==" %%a in ("%configRoot%\Paths.env") do (
	if /i "%%a"=="PROJECTS_ROOT" set "PROJECTS_ROOT=%%b"
)

if not defined PROJECTS_ROOT (
	powershell -Command "Write-Host 'PROJECTS_ROOT is not set in ConfigOffice\Paths.env' -ForegroundColor Red"

	pause
	exit /b 1
)

echo Projects root : !PROJECTS_ROOT!

echo.
@rem ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
@rem Copy files
powershell -Command "Write-Host 'Copy files' -ForegroundColor Blue"
echo.

if not exist "%configRoot%\ConsoleTargets.list" (
	powershell -Command "Write-Host 'ConfigOffice\ConsoleTargets.list is not exist' -ForegroundColor Red"

	pause
	exit /b 1
)

set "currentTool="
set "WIPED_WRAP_ROOTS=:"
set "WIPED_TOOL_ROOTS=:"

for /f "usebackq eol=# delims=" %%a in ("%configRoot%\ConsoleTargets.list") do (
	set "line=%%a"

	if "!line:~0,1!"=="[" (
		set "currentTool=!line:~1,-1!"
	) else if defined currentTool (
		if "!line:~0,7!"=="@direct" (
			set "alias=!line:~8!"
			echo  [direct] KZ!currentTool! to !alias!
			call :CopyToolToProject "!currentTool!" "!alias!" "direct"
			if !errorlevel! neq 0 exit /b 1
		) else if "!line:~0,7!"=="@common" (
			set "alias=!line:~8!"
			echo  [common] KZ!currentTool! to !alias!
			call :CopyToolToProject "!currentTool!" "!alias!" "common"
			if !errorlevel! neq 0 exit /b 1
		) else if "!line:~0,5!"=="@wrap" (
			set "wrapPath=!line:~6!"
			call :DeployWrappers "!currentTool!" "!wrapPath!"
			if !errorlevel! neq 0 exit /b 1
		)
	)
)

echo.
@rem ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
@rem Delete console project
powershell -Command "Write-Host 'Delete console project' -ForegroundColor Blue"
echo.

set "deletePath=%scriptRoot%KoZaeConsole"
echo Delete path !deletePath!

if exist "%deletePath%" (
	powershell -NoProfile -Command "Remove-Item -LiteralPath '%deletePath%' -Recurse -Force -ErrorAction Stop"
)

if %errorlevel% neq 0 (
	powershell -Command "Write-Host 'Delete failed for %deletePath%. Error code: %errorlevel%' -ForegroundColor Red"

	pause
	exit /b 1
)

echo.
@rem ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
@rem Finish console generation
powershell -Command "Write-Host 'Finish console generation' -ForegroundColor Magenta"
echo.

if not defined SKIP_PAUSE (
	pause
)

exit /b 0

@rem ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
@rem Subroutines

:CopyToolToProject
set "toolName=%~1"
set "projectAlias=%~2"
set "deployType=%~3"
set "consoleName=KZ!toolName!"
set "sourceFolder=KoZaeConsole\!consoleName!"
set "paramFolder=!runtimeRoot!\!toolName!"
set "PROJECT_REL_PATH="
set "TOOL_SUBPATH="

call :GetProjectPath "!projectAlias!"

if not defined PROJECT_REL_PATH (
	call :FailPause "Project alias is not defined: !projectAlias!"
	exit /b 1
)

call :GetToolPath "!toolName!"

if not defined TOOL_SUBPATH (
	call :FailPause "Tool path is not defined for !toolName! in ConfigOffice\ToolPaths.map"
	exit /b 1
)

set "destPath=!PROJECTS_ROOT!\!PROJECT_REL_PATH!\!TOOL_SUBPATH!\!consoleName!"

@rem Calculate destinationPath and toolRoot
for %%x in ("!destPath!") do set "parentPath=%%~dpx"
set "destinationPath=!parentPath:~0,-1!"
for %%T in ("!destinationPath!\..") do set "toolRoot=%%~fT"

@rem Pre-wipe: on first deploy to this project, wipe the entire Tool folder
echo !WIPED_TOOL_ROOTS! | find /i ":!toolRoot!:" >nul 2>&1
if !errorlevel! neq 0 (
	if exist "!toolRoot!" (
		powershell -NoProfile -Command "Remove-Item -LiteralPath '!toolRoot!' -Recurse -Force -ErrorAction SilentlyContinue"
	)
	set "WIPED_TOOL_ROOTS=!WIPED_TOOL_ROOTS!!toolRoot!:"
	echo   [!projectAlias!] wiped Tool folder: !toolRoot!
)

echo   [!projectAlias!] copy exe...

mkdir "!destPath!" 2>nul

xcopy "!sourceFolder!\*" "!destPath!\" /E /H /C /I /Y /Q >nul 2>&1

if !errorlevel! geq 2 (
	call :FailPause "Copy failed for !destPath!. Error code: !errorlevel!"
	exit /b 1
) else (
	for %%x in ("!sourceFolder!") do set "absSourceFolder=%%~fx"
	echo   Copy is done. [!absSourceFolder! to !destPath!]
)

if exist "!paramFolder!" (

	echo   [!projectAlias!] copy runtime scripts...

	mkdir "!destinationPath!" 2>nul

	@rem Copy files and subdirs
	@rem Exclude: wrappers\ (for @wrap only), direct-only\ (for @direct only)
	if /i "!deployType!"=="direct" (
		powershell -NoProfile -Command "Get-ChildItem -LiteralPath '!paramFolder!' -File | Copy-Item -Destination '!destinationPath!' -Force; Get-ChildItem -LiteralPath '!paramFolder!' -Directory | Where-Object { $_.Name -ne 'wrappers' -and $_.Name -ne 'direct-only' } | ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination '!destinationPath!' -Recurse -Force }"
		if exist "!paramFolder!\direct-only" (
			powershell -NoProfile -Command "Get-ChildItem -LiteralPath '!paramFolder!\direct-only' -File | Copy-Item -Destination '!destinationPath!' -Force"
		)
	) else (
		powershell -NoProfile -Command "Get-ChildItem -LiteralPath '!paramFolder!' -File | Copy-Item -Destination '!destinationPath!' -Force; Get-ChildItem -LiteralPath '!paramFolder!' -Directory | Where-Object { $_.Name -ne 'wrappers' -and $_.Name -ne 'direct-only' } | ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination '!destinationPath!' -Recurse -Force }"
	)

	if !errorlevel! neq 0 (
		call :FailPause "Copy param failed for !destinationPath!. Error code: !errorlevel!"
		exit /b 1
	) else (
		echo   Copy is done. [!paramFolder! to !destinationPath!]
	)

	echo   [!projectAlias!] sync shared runtime at !toolRoot!

	if not exist "!toolRoot!" (
		mkdir "!toolRoot!" 2>nul
	)

	if exist "!runtimeRoot!\Common.bat" (
		copy /Y "!runtimeRoot!\Common.bat" "!toolRoot!\" >nul 2>&1
	)

	if exist "!runtimeRoot!\ResolveParams.ps1" (
		copy /Y "!runtimeRoot!\ResolveParams.ps1" "!toolRoot!\" >nul 2>&1
	)

	if exist "!runtimeRoot!\CallCommon.bat" (
		copy /Y "!runtimeRoot!\CallCommon.bat" "!toolRoot!\" >nul 2>&1
	)

	@rem Site-local Paths.env: seed once at Tool root, never overwrite
	if not exist "!toolRoot!\Paths.env" (
		set "siteEnv=!runtimeRoot!\SitePath\!projectAlias!.env"
		if not exist "!siteEnv!" set "siteEnv=!runtimeRoot!\Paths.env"
		if exist "!siteEnv!" (
			copy /Y "!siteEnv!" "!toolRoot!\Paths.env" >nul 2>&1
			echo   [!projectAlias!] create Paths.env at !toolRoot!
		)
	)

	@rem Parameter templates: clean then copy to remove deleted entries
	if exist "!runtimeRoot!\ParameterPath" (
		if exist "!toolRoot!\ParameterPath" (
			powershell -NoProfile -Command "Remove-Item -LiteralPath '!toolRoot!\ParameterPath' -Recurse -Force -ErrorAction SilentlyContinue"
		)
		mkdir "!toolRoot!\ParameterPath" 2>nul
		xcopy "!runtimeRoot!\ParameterPath\*" "!toolRoot!\ParameterPath\" /E /H /C /I /Y /Q >nul 2>&1
	)
)

echo.
exit /b 0

:DeployWrappers
set "toolName=%~1"
set "wrapRelPath=%~2"
set "TOOL_SUBPATH="

call :GetToolPath "!toolName!"

if not defined TOOL_SUBPATH (
	call :FailPause "Tool path is not defined for !toolName! in ConfigOffice\ToolPaths.map"
	exit /b 1
)

@rem Extract last segment of TOOL_SUBPATH as the folder name (e.g. Tool\GenerateProto → GenerateProto)
for %%I in ("!TOOL_SUBPATH!") do set "toolFolderName=%%~nxI"

set "wrapperSrc=!runtimeRoot!\!toolName!\wrappers"
set "wrapToolRoot=!PROJECTS_ROOT!\!wrapRelPath!"
set "wrapToolPath=!wrapToolRoot!\!toolFolderName!"

@rem Pre-wipe: on first @wrap deploy to this wrapToolRoot, remove ALL subfolders
@rem Cleans stale folders (old GenerateCipher\, ManageProto\ etc.)
@rem Root-level files (Project.env, CallCommon.bat …) are preserved — files only, not dirs
echo !WIPED_WRAP_ROOTS! | find /i ":!wrapToolRoot!:" >nul 2>&1
if !errorlevel! neq 0 (
	if exist "!wrapToolRoot!" (
		powershell -NoProfile -Command "Remove-Item -LiteralPath '!wrapToolRoot!' -Recurse -Force -ErrorAction SilentlyContinue"
	)
	set "WIPED_WRAP_ROOTS=!WIPED_WRAP_ROOTS!!wrapToolRoot!:"
	echo   [wrap] pre-wiped subfolders in !wrapToolRoot!
)

if not exist "!wrapperSrc!" (
	echo   [wrap] No wrappers for !toolName!, skip.
	exit /b 0
)

echo   [wrap] !wrapRelPath!\!toolFolderName!

@rem Create and populate wrapper folder (already wiped by pre-wipe above)
mkdir "!wrapToolPath!" 2>nul

xcopy "!wrapperSrc!\*" "!wrapToolPath!\" /E /H /C /I /Y /Q >nul 2>&1
if !errorlevel! geq 2 (
	call :FailPause "Wrapper copy failed for !wrapToolPath!. Error code: !errorlevel!"
	exit /b 1
)

@rem Deploy shared scripts to tool root (overwrite OK — same content across all derived projects)
if not exist "!wrapToolRoot!" mkdir "!wrapToolRoot!" 2>nul

if exist "!runtimeRoot!\CallCommon.bat" (
	copy /Y "!runtimeRoot!\CallCommon.bat" "!wrapToolRoot!\" >nul 2>&1
)
if exist "!runtimeRoot!\Common.bat" (
	copy /Y "!runtimeRoot!\Common.bat" "!wrapToolRoot!\" >nul 2>&1
)
if exist "!runtimeRoot!\ResolveParams.ps1" (
	copy /Y "!runtimeRoot!\ResolveParams.ps1" "!wrapToolRoot!\" >nul 2>&1
)

echo   done.
echo.
exit /b 0

:FailPause
powershell -Command "Write-Host '%~1' -ForegroundColor Red"

if not defined SKIP_PAUSE (
	pause
)

exit /b 1

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
