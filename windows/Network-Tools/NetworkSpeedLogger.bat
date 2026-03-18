@echo off
:: ============================================================
:: Name      : NetworkSpeedLogger.bat
:: Version   : 1.0.0
:: Author    : Anamicca23
:: Tested    : Windows 10 22H2, Windows 11 23H2
:: Min OS    : Windows 10 1803
:: Risk      : LOW
:: Admin     : Not Required
:: Reversible: Yes  (read-only, log saved to Desktop)
:: Desc      : Pings 5 servers every 10 seconds for 5 minutes.
::             Appends timestamped latency results to a log file
::             on the Desktop for trend analysis.
:: ============================================================
setlocal enabledelayedexpansion
title NETWORK SPEED LOGGER v1.0.0
mode con: cols=75 lines=45
if not "%1"=="RUN" start /MAX cmd /k "%~f0" RUN & exit

:MENU
cls
color 0B
echo.
echo  +==============================================================+
echo  ^|      N E T W O R K   S P E E D   L O G G E R  v1.0.0      ^|
echo  ^|       Latency monitoring and trend logging tool             ^|
echo  +==============================================================+
echo  ^|                                                             ^|
echo  ^|   [1]  Start 5-Minute Log  (30 cycles x 5 targets)         ^|
echo  ^|   [2]  Start 1-Minute Quick Log  (6 cycles)                 ^|
echo  ^|   [3]  Single Ping Test  (instant results)                  ^|
echo  ^|   [4]  Custom Duration Log                                  ^|
echo  ^|   [5]  View Last Log File                                   ^|
echo  ^|   [6]  Clear All Logs from Desktop                          ^|
echo  ^|   [0]  Exit                                                 ^|
echo  ^|                                                             ^|
echo  +==============================================================+
echo.
set /p c=    Enter Option: 
if "%c%"=="1" ( set "cycles=30" & set "label=5-Minute" & goto STARTLOG )
if "%c%"=="2" ( set "cycles=6"  & set "label=1-Minute" & goto STARTLOG )
if "%c%"=="3" goto SINGLETEST
if "%c%"=="4" goto CUSTOMLOG
if "%c%"=="5" goto VIEWLOG
if "%c%"=="6" goto CLEARLOGS
if "%c%"=="0" goto EXIT
goto MENU

:STARTLOG
cls
color 0B
set "logFile=%USERPROFILE%\Desktop\NetworkLog_%DATE:~-4,4%%DATE:~-7,2%%DATE:~0,2%_%TIME:~0,2%%TIME:~3,2%.txt"
set "logFile=!logFile: =0!"

echo.
echo  +------------------------------------------------------------+
echo  ^|  Starting !label! Network Log
echo  ^|  Cycles     : !cycles!  (every 10 seconds)
echo  ^|  Targets    : Google, Cloudflare, OpenDNS, Quad9, Amazon
echo  ^|  Log file   : Desktop\NetworkLog_[timestamp].txt
echo  ^|
echo  ^|  Press CTRL+C to stop early.
echo  +------------------------------------------------------------+
echo.

:: Write log header
(
echo ================================================================
echo   NETWORK SPEED LOG  -  !label!
echo   Started  : %DATE% %TIME%
echo   Computer : %COMPUTERNAME%
echo   Targets  : 8.8.8.8  1.1.1.1  208.67.222.222  9.9.9.9  205.251.196.1
echo ================================================================
echo.
) > "!logFile!"

set "cycle=0"
:LOGLOOP
set /a cycle+=1
if !cycle! gtr !cycles! goto LOGDONE

echo  Cycle !cycle! of !cycles! — %TIME%

:: Write cycle header to log
echo [Cycle !cycle!/!cycles!] %DATE% %TIME% >> "!logFile!"

:: Ping each target
for %%t in (8.8.8.8 1.1.1.1 208.67.222.222 9.9.9.9 205.251.196.1) do (
    set "result="
    for /f "tokens=*" %%r in ('ping -n 2 %%t 2^>nul ^| findstr /i "Average\|Request timed"') do (
        set "result=%%r"
    )
    if not defined result set "result=TIMEOUT / No response"
    echo   Target: %%t  ^|  !result!
    echo   Target: %%t  ^|  !result! >> "!logFile!"
)
echo. >> "!logFile!"

echo  Waiting 10 seconds...
timeout /t 10 >nul
goto LOGLOOP

:LOGDONE
(
echo.
echo ================================================================
echo   Log Complete  -  !cycles! cycles recorded
echo   Ended : %DATE% %TIME%
echo ================================================================
) >> "!logFile!"

color 0A
echo.
echo  +------------------------------------------------------------+
echo  [DONE] Log complete. !cycles! cycles recorded.
echo  Saved to: !logFile!
echo.
echo  Open the file in Notepad to review latency trends.
echo  High latency (200ms+) or timeouts indicate network issues.
echo  +------------------------------------------------------------+
echo.
pause
goto MENU

:SINGLETEST
cls
color 09
echo.
echo  +------------------------------------------------------------+
echo  ^|  SINGLE PING TEST  -  5 targets, 4 packets each           ^|
echo  +------------------------------------------------------------+
echo.

for %%t in (8.8.8.8 1.1.1.1 208.67.222.222 9.9.9.9 205.251.196.1) do (
    echo  Target: %%t
    ping -n 4 %%t | findstr /i "Reply ms loss Average"
    echo.
)

echo  Latency guide:
echo    Under 20ms   = Excellent
echo    20 - 50ms    = Good
echo    50 - 100ms   = Acceptable
echo    Over 100ms   = Poor (affects gaming and video calls)
echo    TIMEOUT      = No route / blocked
echo.
pause
goto MENU

:CUSTOMLOG
cls
color 09
echo.
echo  How many cycles to run? (1 cycle = 10 seconds)
echo  Examples: 12 = 2 minutes   30 = 5 minutes   60 = 10 minutes
echo.
set /p cycles=  Cycles: 
set /a checkCycles=cycles
if !checkCycles! lss 1 ( echo  Invalid. & pause & goto MENU )
if !checkCycles! gtr 360 ( echo  Maximum is 360 cycles (1 hour). Setting to 360. & set "cycles=360" )
set "label=Custom (!cycles! cycles)"
goto STARTLOG

:VIEWLOG
cls
color 0B
echo.
echo  Searching for log files on Desktop...
echo.
set "foundLog=0"
for /f "delims=" %%f in ('dir "%USERPROFILE%\Desktop\NetworkLog_*.txt" /b /o:-d 2^>nul') do (
    if !foundLog!==0 (
        set "latestLog=%%f"
        set "foundLog=1"
    )
)
if !foundLog!==0 (
    echo  No log files found on Desktop.
    echo  Run option [1] or [2] to create a log first.
) else (
    echo  Opening most recent log: !latestLog!
    echo.
    type "%USERPROFILE%\Desktop\!latestLog!"
)
echo.
pause
goto MENU

:CLEARLOGS
echo.
echo  +------------------------------------------------------------+
echo  ^|  [WARNING] This will delete ALL NetworkLog_*.txt files    ^|
echo  ^|  from your Desktop.                                        ^|
echo  +------------------------------------------------------------+
echo.
set /p confirm=  Delete all log files? (Y/N): 
if /i not "%confirm%"=="Y" ( echo  Cancelled. & pause & goto MENU )
del /q "%USERPROFILE%\Desktop\NetworkLog_*.txt" >nul 2>&1
color 0B
echo.
echo  [DONE] All network log files removed from Desktop.
echo.
pause
goto MENU

:EXIT
exit
