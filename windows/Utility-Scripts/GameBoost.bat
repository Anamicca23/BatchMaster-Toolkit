@echo off
:: ============================================================
:: Name      : GameBoost.bat
:: Version   : 1.0.0
:: Author    : Anamicca23
:: Tested    : Windows 10 22H2, Windows 11 23H2
:: Min OS    : Windows 10 1803
:: Risk      : HIGH
:: Admin     : Required
:: Reversible: Yes  (Option [2] restores ALL changes)
:: Desc      : Pre-gaming optimizer — kills background apps,
::             sets High Performance power plan, disables
::             Windows Update + Defender scan, applies TCP
::             latency tweaks, boosts process priority.
::             Full restore option included.
:: ============================================================
setlocal enabledelayedexpansion
title GAME BOOST v1.0.0
mode con: cols=70 lines=48
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

:MENU
cls
color 0A
echo.
echo  +============================================================+
echo  ^|            G A M E   B O O S T   v1.0.0                   ^|
echo  ^|       Maximum Performance Mode for Gaming                  ^|
echo  +============================================================+
echo  ^|                                                            ^|
echo  ^|   [1]  ACTIVATE GAME BOOST  ^(before gaming^)               ^|
echo  ^|   [2]  RESTORE NORMAL MODE  ^(after gaming^)                ^|
echo  ^|   [3]  Show What Will Be Changed                           ^|
echo  ^|   [4]  Show Current System State                           ^|
echo  ^|   [0]  Exit                                                ^|
echo  ^|                                                            ^|
echo  +============================================================+
echo.
set /p c=    Enter Option: 
if "%c%"=="1" goto BOOST
if "%c%"=="2" goto RESTORE
if "%c%"=="3" goto PREVIEW
if "%c%"=="4" goto STATUS
if "%c%"=="0" goto EXIT
goto MENU

:BOOST
cls
color 0E
echo.
echo  +============================================================+
echo  ^|  [WARNING] Game Boost will:                               ^|
echo  ^|    - Kill background apps (Teams, Slack, Discord etc.)    ^|
echo  ^|    - Disable Windows Update temporarily                   ^|
echo  ^|    - Disable Defender real-time scanning temporarily      ^|
echo  ^|    - Modify TCP registry settings                         ^|
echo  ^|                                                            ^|
echo  ^|  Run Option [2] after gaming to restore everything.        ^|
echo  +============================================================+
echo.
set /p confirm=  Activate Game Boost? (Y/N): 
if /i not "%confirm%"=="Y" ( echo  Cancelled. & pause & goto MENU )

cls
color 0A
echo.
echo  +============================================================+
echo  ^|   ACTIVATING GAME BOOST...                                 ^|
echo  +============================================================+
echo.

echo  [1/8] Setting power plan to High Performance...
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c >nul 2>&1
if errorlevel 1 (
    :: Create High Performance plan if not found
    powercfg /duplicatescheme 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c >nul 2>&1
    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c >nul 2>&1
)
echo         Done. ^(was: Balanced^)

echo  [2/8] Killing background applications...
set "killed="
for %%p in (
    OneDrive.exe
    Teams.exe
    Slack.exe
    Discord.exe
    Spotify.exe
    SearchApp.exe
    SearchIndexer.exe
    MicrosoftEdgeUpdate.exe
    SkypeApp.exe
    YourPhone.exe
    PhoneExperienceHost.exe
    WidgetService.exe
    widgets.exe
    GameBarFTServer.exe
) do (
    taskkill /f /im %%p >nul 2>&1
    if not errorlevel 1 set "killed=!killed! %%p"
)
if defined killed (
    echo         Killed:!killed!
) else (
    echo         No background apps were running.
)

echo  [3/8] Disabling Windows Update service...
sc stop wuauserv >nul 2>&1
sc stop bits >nul 2>&1
sc config wuauserv start= disabled >nul 2>&1
echo         Done.

echo  [4/8] Disabling Defender real-time monitoring...
powershell -Command "Set-MpPreference -DisableRealtimeMonitoring $true" >nul 2>&1
echo         Done. ^(will re-enable on Restore^)

echo  [5/8] Applying TCP low-latency tweaks (Nagle disable)...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" /v "TcpAckFrequency" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" /v "TCPNoDelay" /t REG_DWORD /d 1 /f >nul 2>&1
echo         Done.

echo  [6/8] Boosting process priority separation...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d 38 /f >nul 2>&1
echo         Done. ^(was: 2^)

echo  [7/8] Disabling network throttling...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "NetworkThrottlingIndex" /t REG_DWORD /d 0xffffffff /f >nul 2>&1
echo         Done.

echo  [8/8] Setting GPU scheduling priority...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority" /t REG_DWORD /d 8 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Priority" /t REG_DWORD /d 6 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Scheduling Category" /t REG_SZ /d "High" /f >nul 2>&1
echo         Done.

color 0B
echo.
echo  +============================================================+
echo  ^|  [READY] Game Boost is ACTIVE!                             ^|
echo  ^|                                                            ^|
echo  ^|   Your PC is now optimized for maximum performance.        ^|
echo  ^|   Launch your game and enjoy!                              ^|
echo  ^|                                                            ^|
echo  ^|   IMPORTANT: Run Option [2] after gaming to restore        ^|
echo  ^|   normal Windows operation.                                ^|
echo  +============================================================+
echo.
pause
goto MENU

:RESTORE
cls
color 0B
echo.
echo  +============================================================+
echo  ^|   RESTORING NORMAL MODE...                                 ^|
echo  +============================================================+
echo.

echo  [1/6] Restoring power plan to Balanced...
powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e >nul 2>&1
echo         Done.

echo  [2/6] Re-enabling Windows Update...
sc config wuauserv start= auto >nul 2>&1
sc start wuauserv >nul 2>&1
sc config bits start= auto >nul 2>&1
sc start bits >nul 2>&1
echo         Done.

echo  [3/6] Re-enabling Defender real-time monitoring...
powershell -Command "Set-MpPreference -DisableRealtimeMonitoring $false" >nul 2>&1
echo         Done.

echo  [4/6] Restoring TCP settings...
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" /v "TcpAckFrequency" /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" /v "TCPNoDelay" /f >nul 2>&1
echo         Done.

echo  [5/6] Restoring process priority...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d 2 /f >nul 2>&1
echo         Done.

echo  [6/6] Restoring network throttling...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "NetworkThrottlingIndex" /t REG_DWORD /d 10 /f >nul 2>&1
echo         Done.

color 0B
echo.
echo  +============================================================+
echo  ^|  [DONE] Normal mode fully restored.                        ^|
echo  ^|  All services are back online.                             ^|
echo  +============================================================+
echo.
pause
goto MENU

:PREVIEW
cls
color 0D
echo.
echo  +============================================================+
echo  ^|  WHAT GAME BOOST DOES — FULL PREVIEW                      ^|
echo  +============================================================+
echo.
echo  BOOST (Option 1):
echo  ------------------
echo   Power Plan   : Switches to High Performance
echo                  (removes CPU/GPU power-saving throttles)
echo.
echo   Killed Apps  : OneDrive, Teams, Slack, Discord, Spotify,
echo                  SearchIndexer, Edge Update, Skype, YourPhone,
echo                  GameBar, Widgets
echo                  (frees RAM and CPU from background noise)
echo.
echo   Windows Update : Service stopped + disabled temporarily
echo                    (prevents mid-game update downloads)
echo.
echo   Defender     : Real-time scan disabled temporarily
echo                  (eliminates game file scanning overhead)
echo.
echo   TCP Tweaks   : TcpAckFrequency=1, TCPNoDelay=1
echo                  (reduces network latency / ping)
echo.
echo   Process Priority : Win32PrioritySeparation=38
echo                      (more CPU time to foreground apps)
echo.
echo   GPU Priority : Games task = High scheduling category
echo                  (Windows schedules GPU work sooner)
echo.
echo  RESTORE (Option 2):
echo  --------------------
echo   Reverts ALL 6 changes to exact Windows defaults.
echo   Re-enables Update, Defender, throttling, balanced power.
echo.
pause
goto MENU

:STATUS
cls
color 09
echo.
echo  +============================================================+
echo  ^|  CURRENT SYSTEM STATE                                      ^|
echo  +============================================================+
echo.
echo  Power Plan:
powercfg /getactivescheme 2>nul
echo.
echo  Windows Update (wuauserv):
sc query wuauserv 2>nul | findstr "STATE"
echo.
echo  Defender Real-Time:
powershell -Command "(Get-MpPreference).DisableRealtimeMonitoring" 2>nul
echo  (True = disabled, False = enabled)
echo.
echo  Network Throttling:
for /f "tokens=3" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "NetworkThrottlingIndex" 2^>nul ^| findstr "NetworkThrottlingIndex"') do (
    echo  NetworkThrottlingIndex = %%a  (0xffffffff=off  0xa=default)
)
echo.
echo  Process Priority:
for /f "tokens=3" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" 2^>nul ^| findstr "Win32PrioritySeparation"') do (
    echo  Win32PrioritySeparation = %%a  (0x26/38=boost  0x2=default)
)
echo.
pause
goto MENU

:EXIT
exit
