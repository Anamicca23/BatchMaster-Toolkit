@echo off
:: ============================================================
:: Name      : AppInstaller.bat
:: Version   : 1.0.0
:: Author    : Anamicca23
:: Tested    : Windows 10 22H2, Windows 11 23H2
:: Min OS    : Windows 10 1809  (requires winget)
:: Risk      : MEDIUM
:: Admin     : Required
:: Reversible: Yes  (apps can be uninstalled normally)
:: Desc      : Silent bulk installer using winget. Checks if
::             each app is already installed before proceeding.
::             Installs Chrome, VLC, 7-Zip, Notepad++, VS Code,
::             and more. Logs all results to Desktop.
:: ============================================================
setlocal enabledelayedexpansion
title APP INSTALLER v1.0.0
mode con: cols=70 lines=50
if not "%1"=="RUN" start /MAX cmd /k "%~f0" RUN & exit

net session >nul 2>&1
if %errorlevel% neq 0 (
    color 0C & cls
    echo.
    echo  [ERROR] Must be run as Administrator.
    echo  Right-click ^> Run as administrator.
    echo.
    pause & exit /b 1
)

:: Check winget is available
where winget >nul 2>&1
if errorlevel 1 (
    color 0C & cls
    echo.
    echo  [ERROR] winget is not installed on this system.
    echo.
    echo  winget requires Windows 10 version 1809 or later.
    echo  Install it from the Microsoft Store:
    echo  Search for "App Installer" and update it.
    echo.
    pause & exit /b 1
)

:MENU
cls
color 0B
echo.
echo  +============================================================+
echo  ^|         A P P   I N S T A L L E R   v1.0.0                ^|
echo  ^|     Silent one-click app installation via winget           ^|
echo  +============================================================+
echo  ^|                                                            ^|
echo  ^|   [1]  Install Essential Pack  (Chrome/VLC/7-Zip/Notepad++) ^|
echo  ^|   [2]  Install Developer Pack  (VS Code/Git/Python/Node)   ^|
echo  ^|   [3]  Install Full Pack  (All above combined)             ^|
echo  ^|   [4]  Install a Single App  (by winget ID)                ^|
echo  ^|   [5]  Check Which Apps Are Already Installed              ^|
echo  ^|   [6]  View Installation Log                               ^|
echo  ^|   [0]  Exit                                                ^|
echo  ^|                                                            ^|
echo  +============================================================+
echo.
set /p c=    Enter Option: 
if "%c%"=="1" goto ESSENTIALS
if "%c%"=="2" goto DEVPACK
if "%c%"=="3" goto FULLPACK
if "%c%"=="4" goto SINGLEAPP
if "%c%"=="5" goto CHECKINSTALLED
if "%c%"=="6" goto VIEWLOG
if "%c%"=="0" goto EXIT
goto MENU

:SETLOG
set "logFile=%USERPROFILE%\Desktop\AppInstaller_Log.txt"
exit /b

:INSTALLAPP
:: call :INSTALLAPP "Display Name" "winget.ID"
set "_appName=%~1"
set "_appID=%~2"

:: Check if already installed
winget list --id "!_appID!" --exact >nul 2>&1
if not errorlevel 1 (
    echo  [SKIP]  !_appName! is already installed.
    echo  [SKIP]  !_appName! - Already installed >> "!logFile!"
    exit /b 0
)

echo  [....] Installing !_appName!...
winget install --id "!_appID!" --silent --accept-package-agreements --accept-source-agreements >nul 2>&1
if !errorlevel!==0 (
    color 0B
    echo  [ OK ] !_appName! installed successfully.
    color 0A
    echo  [ OK ] !_appName! installed >> "!logFile!"
) else (
    color 0C
    echo  [FAIL] !_appName! installation failed. Check log.
    color 0A
    echo  [FAIL] !_appName! - Error code !errorlevel! >> "!logFile!"
)
exit /b

:ESSENTIALS
call :SETLOG
cls
color 0A
echo.
echo  +============================================================+
echo  ^|  INSTALLING ESSENTIAL PACK                                 ^|
echo  ^|  Google Chrome, VLC, 7-Zip, Notepad++, WinRAR             ^|
echo  +============================================================+
echo.
echo  Installation log will be saved to Desktop.
echo.

(echo === ESSENTIAL PACK - %DATE% %TIME% === ) > "!logFile!"

call :INSTALLAPP "Google Chrome"    "Google.Chrome"
call :INSTALLAPP "VLC Media Player" "VideoLAN.VLC"
call :INSTALLAPP "7-Zip"            "7zip.7zip"
call :INSTALLAPP "Notepad++"        "Notepad++.Notepad++"
call :INSTALLAPP "WinRAR"           "RARLab.WinRAR"

color 0B
echo.
echo  +------------------------------------------------------------+
echo  [DONE] Essential Pack installation complete.
echo  Log saved to Desktop as AppInstaller_Log.txt
echo  +------------------------------------------------------------+
echo.
pause
goto MENU

:DEVPACK
call :SETLOG
cls
color 0A
echo.
echo  +============================================================+
echo  ^|  INSTALLING DEVELOPER PACK                                 ^|
echo  ^|  VS Code, Git, Python 3, Node.js, Windows Terminal        ^|
echo  +============================================================+
echo.
echo  Note: These are larger installs. May take several minutes.
echo.

(echo === DEVELOPER PACK - %DATE% %TIME% === ) >> "!logFile!"

call :INSTALLAPP "Visual Studio Code" "Microsoft.VisualStudioCode"
call :INSTALLAPP "Git"                "Git.Git"
call :INSTALLAPP "Python 3"           "Python.Python.3"
call :INSTALLAPP "Node.js LTS"        "OpenJS.NodeJS.LTS"
call :INSTALLAPP "Windows Terminal"   "Microsoft.WindowsTerminal"

color 0B
echo.
echo  +------------------------------------------------------------+
echo  [DONE] Developer Pack installation complete.
echo  Log saved to Desktop as AppInstaller_Log.txt
echo  +------------------------------------------------------------+
echo.
pause
goto MENU

:FULLPACK
call :SETLOG
cls
color 0A
echo.
echo  +============================================================+
echo  ^|  INSTALLING FULL PACK  (Essential + Developer)            ^|
echo  ^|  This will install all 10 apps.                           ^|
echo  ^|  Estimated time: 5-15 minutes depending on your internet. ^|
echo  +============================================================+
echo.
set /p confirm=  Install all apps? (Y/N): 
if /i not "%confirm%"=="Y" ( echo  Cancelled. & pause & goto MENU )

(echo === FULL PACK - %DATE% %TIME% === ) > "!logFile!"

echo.
echo  --- Essential Apps ---
call :INSTALLAPP "Google Chrome"    "Google.Chrome"
call :INSTALLAPP "VLC Media Player" "VideoLAN.VLC"
call :INSTALLAPP "7-Zip"            "7zip.7zip"
call :INSTALLAPP "Notepad++"        "Notepad++.Notepad++"
call :INSTALLAPP "WinRAR"           "RARLab.WinRAR"

echo.
echo  --- Developer Apps ---
call :INSTALLAPP "Visual Studio Code" "Microsoft.VisualStudioCode"
call :INSTALLAPP "Git"                "Git.Git"
call :INSTALLAPP "Python 3"           "Python.Python.3"
call :INSTALLAPP "Node.js LTS"        "OpenJS.NodeJS.LTS"
call :INSTALLAPP "Windows Terminal"   "Microsoft.WindowsTerminal"

color 0B
echo.
echo  +------------------------------------------------------------+
echo  [DONE] Full Pack installation complete.
echo  Log saved to Desktop as AppInstaller_Log.txt
echo  +------------------------------------------------------------+
echo.
pause
goto MENU

:SINGLEAPP
cls
color 09
echo.
echo  Enter the winget package ID to install.
echo  Find IDs at: https://winget.run  or  winget search ^<name^>
echo.
echo  Examples:
echo    Google.Chrome              Microsoft.PowerShell
echo    VideoLAN.VLC               Spotify.Spotify
echo    7zip.7zip                  Valve.Steam
echo    Notepad++.Notepad++        Discord.Discord
echo    Git.Git                    OBSProject.OBSStudio
echo.
set /p appID=  Package ID: 
if "!appID!"=="" ( echo  Cancelled. & pause & goto MENU )

echo.
echo  Searching for !appID!...
winget show "!appID!" 2>nul | findstr /i "Found\|Name\|Version\|Publisher"
echo.
set /p confirm=  Install this app? (Y/N): 
if /i not "%confirm%"=="Y" ( echo  Cancelled. & pause & goto MENU )

echo.
echo  Installing !appID!...
winget install --id "!appID!" --silent --accept-package-agreements --accept-source-agreements
echo.
if !errorlevel!==0 (
    color 0B
    echo  [OK] Installation complete.
) else (
    color 0C
    echo  [ERROR] Installation failed. Exit code: !errorlevel!
    echo  Try: winget install !appID!  (without --silent for verbose output)
)
echo.
pause
goto MENU

:CHECKINSTALLED
cls
color 09
echo.
echo  +============================================================+
echo  ^|  CHECKING WHICH APPS ARE ALREADY INSTALLED                ^|
echo  +============================================================+
echo.
for %%a in (
    "Google Chrome|Google.Chrome"
    "VLC Media Player|VideoLAN.VLC"
    "7-Zip|7zip.7zip"
    "Notepad++|Notepad++.Notepad++"
    "WinRAR|RARLab.WinRAR"
    "VS Code|Microsoft.VisualStudioCode"
    "Git|Git.Git"
    "Python 3|Python.Python.3"
    "Node.js|OpenJS.NodeJS.LTS"
    "Windows Terminal|Microsoft.WindowsTerminal"
) do (
    for /f "tokens=1,2 delims=|" %%x in ("%%~a") do (
        winget list --id "%%y" --exact >nul 2>&1
        if not errorlevel 1 (
            echo  [INSTALLED]     %%x
        ) else (
            echo  [NOT INSTALLED] %%x
        )
    )
)
echo.
pause
goto MENU

:VIEWLOG
cls
color 09
call :SETLOG
echo.
if exist "!logFile!" (
    echo  +============================================================+
    echo  ^|  INSTALLATION LOG                                          ^|
    echo  +============================================================+
    echo.
    type "!logFile!"
) else (
    echo  No log file found. Run an installation first.
)
echo.
pause
goto MENU

:EXIT
exit
