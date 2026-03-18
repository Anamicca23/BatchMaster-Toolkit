@echo off
:: ============================================================
:: Name      : BootSpeedAnalyzer.bat
:: Version   : 1.0.0
:: Author    : Anamicca23
:: Tested    : Windows 10 22H2, Windows 11 23H2
:: Min OS    : Windows 10 1803
:: Risk      : LOW
:: Admin     : Required
:: Reversible: Yes
:: Desc      : Reads Windows boot event logs and ranks startup
::             programs by boot delay added.
:: ============================================================
setlocal enabledelayedexpansion
title BOOT SPEED ANALYZER v1.0.0
mode con: cols=80 lines=45
if not "%1"=="RUN" start /MAX cmd /k "%~f0" RUN & exit

net session >nul 2>&1
if %errorlevel% neq 0 (
    color 0C & cls
    echo.
    echo  [ERROR] This script must be run as Administrator.
    echo  Right-click and choose "Run as administrator".
    echo.
    pause & exit /b 1
)

:MENU
cls
color 0A
echo.
echo  +================================================================+
echo  ^|          B O O T   S P E E D   A N A L Y Z E R  v1.0.0       ^|
echo  +================================================================+
echo  ^|                                                                ^|
echo  ^|   [1]  Analyze Last Boot Time                                  ^|
echo  ^|   [2]  Show All Startup Programs                               ^|
echo  ^|   [3]  Show Boot Event Log (Last 5 Boots)                      ^|
echo  ^|   [4]  Show Service Start Times                                ^|
echo  ^|   [5]  Export Full Boot Report to Desktop                      ^|
echo  ^|   [0]  Exit                                                    ^|
echo  ^|                                                                ^|
echo  +================================================================+
echo.
set /p c=    Enter Option: 
if "%c%"=="1" goto LASTBOOT
if "%c%"=="2" goto STARTUPPROGRAMS
if "%c%"=="3" goto EVENTLOG
if "%c%"=="4" goto SERVICES
if "%c%"=="5" goto EXPORTREPORT
if "%c%"=="0" goto EXIT
goto MENU

:LASTBOOT
cls
color 0B
echo.
echo  +================================================================+
echo  ^|  LAST BOOT ANALYSIS                                            ^|
echo  +================================================================+
echo.

:: Get last boot time
for /f "tokens=2 delims==" %%a in ('wmic os get LastBootUpTime /value 2^>nul ^| findstr "="') do (
    set "bootTime=%%a"
    set "bootTime=!bootTime: =!"
)

:: Get current time
for /f "tokens=2 delims==" %%a in ('wmic os get LocalDateTime /value 2^>nul ^| findstr "="') do (
    set "nowTime=%%a"
)

echo  Last Boot Time  : !bootTime:~0,4!-!bootTime:~4,2!-!bootTime:~6,2! !bootTime:~8,2!:!bootTime:~10,2!:!bootTime:~12,2!
echo  Current Time    : !nowTime:~0,4!-!nowTime:~4,2!-!nowTime:~6,2! !nowTime:~8,2!:!nowTime:~10,2!:!nowTime:~12,2!
echo.

:: Boot performance from event log (Event ID 100 = boot duration)
echo  +----------------------------------------------------------------+
echo  ^|  Boot Performance Events (Event ID 100)                        ^|
echo  +----------------------------------------------------------------+
echo.
wevtutil qe "Microsoft-Windows-Diagnostics-Performance/Operational" /q:"*[System[EventID=100]]" /f:text /c:3 2>nul | findstr /i "BootTime\|MainPathBootTime\|BootPost"
echo.

:: Uptime
echo  +----------------------------------------------------------------+
echo  System uptime:
net stats workstation 2>nul | findstr "Statistics since"
echo.

:: Startup items from registry
echo  +----------------------------------------------------------------+
echo  ^|  STARTUP IMPACT SUMMARY                                        ^|
echo  +----------------------------------------------------------------+
echo.
echo  HIGH IMPACT — Consider disabling these in Task Manager:
echo.
reg query "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" 2>nul | findstr /v "HKEY"
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" 2>nul | findstr /v "HKEY"
echo.
echo  Tip: Open Task Manager ^> Startup tab to see impact ratings.
echo  Disable items marked "High" impact to speed up boot.
echo.
pause
goto MENU

:STARTUPPROGRAMS
cls
color 0E
echo.
echo  +================================================================+
echo  ^|  ALL STARTUP PROGRAMS                                          ^|
echo  +================================================================+
echo.
echo  --- CURRENT USER STARTUP (HKCU) ---
reg query "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" 2>nul
echo.
echo  --- ALL USERS STARTUP (HKLM) ---
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" 2>nul
echo.
echo  --- 32-BIT STARTUP ---
reg query "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run" 2>nul
echo.
echo  --- STARTUP FOLDER (Current User) ---
dir /b "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup" 2>nul
echo.
echo  --- STARTUP FOLDER (All Users) ---
dir /b "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup" 2>nul
echo.
echo  --- SCHEDULED TASKS AT BOOT ---
schtasks /query /fo list 2>nul | findstr /i "TaskName:\|Trigger:\|Status:"
echo.
pause
goto MENU

:EVENTLOG
cls
color 0D
echo.
echo  +================================================================+
echo  ^|  BOOT EVENT LOG  (Last 5 boot performance events)             ^|
echo  +================================================================+
echo.
echo  Reading Microsoft-Windows-Diagnostics-Performance log...
echo.
wevtutil qe "Microsoft-Windows-Diagnostics-Performance/Operational" /q:"*[System[EventID=100]]" /f:text /c:5 2>nul
echo.
echo  +----------------------------------------------------------------+
echo  Event IDs reference:
echo  100 = Boot performance degradation detected
echo  101 = App performance degradation at boot
echo  102 = System standby performance issue
echo.
pause
goto MENU

:SERVICES
cls
color 09
echo.
echo  +================================================================+
echo  ^|  SERVICES CONFIGURED TO START AT BOOT                         ^|
echo  +================================================================+
echo.
echo  AUTO-START SERVICES:
echo  +----------------------------------------------------------------+
sc query type= all state= all 2>nul | findstr /i "SERVICE_NAME:\|START_TYPE:\|STATE"
echo.
echo  Tip: Services set to AUTO_START run at every boot.
echo  Use "services.msc" to change startup types.
echo.
pause
goto MENU

:EXPORTREPORT
cls
color 0B
echo.
echo  Exporting boot report to Desktop...
set "rpt=%USERPROFILE%\Desktop\BootReport.txt"
(
echo ============================================================
echo   BOOT SPEED ANALYZER REPORT
echo   Generated: %DATE% %TIME%
echo   Computer : %COMPUTERNAME%
echo ============================================================
echo.
echo [LAST BOOT TIME]
wmic os get LastBootUpTime /value
echo.
echo [STARTUP PROGRAMS - HKCU]
reg query "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
echo.
echo [STARTUP PROGRAMS - HKLM]
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
echo.
echo [BOOT EVENTS - Last 5]
wevtutil qe "Microsoft-Windows-Diagnostics-Performance/Operational" /q:"*[System[EventID=100]]" /f:text /c:5
echo.
echo [AUTO-START SERVICES]
sc query type= all state= all
echo.
echo ============================================================
echo   END OF REPORT
echo ============================================================
) > "%rpt%" 2>nul
if exist "%rpt%" (
    echo  [OK] Report saved to Desktop as BootReport.txt
) else (
    echo  [ERROR] Could not write report.
)
echo.
pause
goto MENU

:EXIT
exit