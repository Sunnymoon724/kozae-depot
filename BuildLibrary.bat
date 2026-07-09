@echo off

chcp 437
cls

setlocal enabledelayedexpansion

@rem ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
@rem Set project path
cd /d "%~dp0"
echo Current path : %cd%

echo.
@rem ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
@rem Start all generation
powershell -Command "Write-Host 'Start all generation' -ForegroundColor DarkMagenta"
echo.

set SKIP_PAUSE=1
set DONT_CLEAR=1

@rem ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
@rem Start helper

cd /d "%~dp0"

set "consolePath=%cd%\HelperShed"

cd /d "%consolePath%"

call BuildHelper.bat

@rem ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
@rem Start console

cd /d "%~dp0"

set "consolePath=%cd%\ConsoleHall"

cd /d "%consolePath%"

call BuildConsole.bat

echo.
@rem ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
@rem Finish all generation
powershell -Command "Write-Host 'Finish all generation' -ForegroundColor DarkMagenta"
echo.

pause