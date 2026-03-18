@echo off
:: ============================================================
:: Name      : PCHealthScore.bat
:: Version   : 1.0.0
:: Author    : Anamicca23
:: Tested    : Windows 10 22H2, Windows 11 23H2
:: Min OS    : Windows 10 1803
:: Risk      : LOW
:: Admin     : Required
:: Reversible: Yes  (read-only audit, no changes made)
:: Desc      : Runs 10 weighted diagnostic checks and outputs
::             a health score out of 100 with a letter grade
::             and specific improvement recommendations.
:: ============================================================
setlocal enabledelayedexpansion
title PC HEALTH SCORE v1.0.0
mode con: cols=70 lines=52
if not "%1"=="RUN" start /MAX cmd /k "%~f0" RUN & exit

net session >nul 2>&1
if %errorlevel% neq 0 (
    color 0C & cls
    echo.
    echo  [ERROR] Must be run as Administrator for full accuracy.
    echo  Right-click ^> Run as administrator.
    echo.
    pause & exit /b 1
)

:MENU
cls
color 0B
echo.
echo  +============================================================+
echo  ^|        P C   H E A L T H   S C O R E   v1.0.0             ^|
echo  ^|     10-point diagnostic check with grade and advice        ^|
echo  +============================================================+
echo  ^|                                                            ^|
echo  ^|   [1]  Run Full Health Check  (all 10 checks)              ^|
echo  ^|   [2]  Quick Check  (5 most important checks)              ^|
echo  ^|   [3]  Export Health Report to Desktop                     ^|
echo  ^|   [0]  Exit                                                ^|
echo  ^|                                                            ^|
echo  +============================================================+
echo.
set /p c=    Enter Option: 
if "%c%"=="1" goto FULLCHECK
if "%c%"=="2" goto QUICKCHECK
if "%c%"=="3" goto EXPORTREPORT
if "%c%"=="0" goto EXIT
goto MENU

:FULLCHECK
cls
color 0B
echo.
echo  +============================================================+
echo  ^|  RUNNING PC HEALTH CHECK...                                ^|
echo  +============================================================+
echo.

set "totalScore=0"
set "maxScore=100"
set "advice="

:: ── CHECK 1: RAM Usage (20 pts) ────────────────────────────────────────
echo  [1/10] Checking RAM usage...
set "rTkb=1" & set "rFkb=0"
for /f "tokens=1* delims==" %%a in ('wmic os get TotalVisibleMemorySize,FreePhysicalMemory /value 2^>nul ^| findstr "="') do (
    if /i "%%a"=="TotalVisibleMemorySize" ( set "rTkb=%%b" & set "rTkb=!rTkb: =!" )
    if /i "%%a"=="FreePhysicalMemory"     ( set "rFkb=%%b" & set "rFkb=!rFkb: =!" )
)
if !rTkb! lss 1 set "rTkb=1"
set /a rTMB=rTkb/1024 & set /a rFMB=rFkb/1024 & set /a rUMB=rTMB-rFMB
set /a rPCT=rUMB*100/rTMB & set /a rFreePCT=100-rPCT
set "ramPts=0"
if !rFreePCT! geq 50 set "ramPts=20"
if !rFreePCT! geq 25 if !rFreePCT! lss 50 set "ramPts=12"
if !rFreePCT! lss 25 set "ramPts=5"
set /a totalScore+=ramPts
if !ramPts! lss 20 set "advice=!advice!  - RAM: !rUMB!MB used (!rPCT!%%). Close unused apps.^|"
echo     RAM Free: !rFreePCT!%% ... !ramPts!/20 pts

:: ── CHECK 2: Disk C: Free Space (20 pts) ──────────────────────────────
echo  [2/10] Checking disk space...
set "cSZb=" & set "cFRb="
for /f "tokens=1* delims==" %%a in ('wmic logicaldisk where "Caption='C:'" get Size,FreeSpace /value 2^>nul ^| findstr "="') do (
    if /i "%%a"=="Size"      ( set "cSZb=%%b" & set "cSZb=!cSZb: =!" )
    if /i "%%a"=="FreeSpace" ( set "cFRb=%%b" & set "cFRb=!cFRb: =!" )
)
set "diskPts=0" & set "diskFreeGB=N/A" & set "diskPCT=0"
if defined cSZb if not "!cSZb!"=="" (
    if "!cSZb:~9,1!"=="" (set "cSZ=0") else (set "cSZ=!cSZb:~0,-9!")
    if "!cFRb:~9,1!"=="" (set "cFR=0") else (set "cFR=!cFRb:~0,-9!")
    if "!cSZ!"=="" set "cSZ=1"
    set /a diskPCT=cFR*100/cSZ
    set "diskFreeGB=!cFR!"
    if !diskPCT! geq 20 set "diskPts=20"
    if !diskPCT! geq 10 if !diskPCT! lss 20 set "diskPts=12"
    if !diskPCT! lss 10 set "diskPts=4"
)
set /a totalScore+=diskPts
if !diskPts! lss 20 set "advice=!advice!  - Disk: only !diskFreeGB!GB free (!diskPCT!%%). Run DeepClean.bat.^|"
echo     Disk C Free: !diskFreeGB! GB (!diskPCT!%%) ... !diskPts!/20 pts

:: ── CHECK 3: CPU Load (15 pts) ─────────────────────────────────────────
echo  [3/10] Checking CPU load...
set "cpuLoad=0"
for /f "tokens=1* delims==" %%a in ('wmic cpu get LoadPercentage /value 2^>nul ^| findstr "="') do (
    set "cpuLoad=%%b" & set "cpuLoad=!cpuLoad: =!"
)
set "cpuPts=0"
if !cpuLoad! lss 50 set "cpuPts=15"
if !cpuLoad! geq 50 if !cpuLoad! lss 80 set "cpuPts=9"
if !cpuLoad! geq 80 set "cpuPts=3"
set /a totalScore+=cpuPts
if !cpuPts! lss 15 set "advice=!advice!  - CPU load is !cpuLoad!%%. Close background processes.^|"
echo     CPU Load: !cpuLoad!%% ... !cpuPts!/15 pts

:: ── CHECK 4: Battery Level (10 pts) ────────────────────────────────────
echo  [4/10] Checking battery...
set "bChg=0" & set "bStat=0"
for /f "tokens=1* delims==" %%a in ('wmic path Win32_Battery get EstimatedChargeRemaining,BatteryStatus /value 2^>nul ^| findstr "="') do (
    if /i "%%a"=="EstimatedChargeRemaining" ( set "bChg=%%b" & set "bChg=!bChg: =!" )
    if /i "%%a"=="BatteryStatus"            ( set "bStat=%%b" & set "bStat=!bStat: =!" )
)
set "batPts=10"
if !bChg! gtr 0 (
    if !bChg! geq 50 set "batPts=10"
    if !bChg! geq 20 if !bChg! lss 50 set "batPts=6"
    if !bChg! lss 20 set "batPts=2"
    if !batPts! lss 10 set "advice=!advice!  - Battery at !bChg!%%. Charge your laptop.^|"
)
set /a totalScore+=batPts
echo     Battery: !bChg!%% (Status:!bStat!) ... !batPts!/10 pts

:: ── CHECK 5: Windows Firewall (10 pts) ─────────────────────────────────
echo  [5/10] Checking firewall...
set "fwPts=0"
netsh advfirewall show allprofiles state 2>nul | findstr "ON" >nul 2>&1
if not errorlevel 1 set "fwPts=10"
set /a totalScore+=fwPts
if !fwPts!==0 set "advice=!advice!  - Firewall appears OFF. Enable via Windows Defender Firewall.^|"
echo     Firewall: [ON=10pts / OFF=0pts] ... !fwPts!/10 pts

:: ── CHECK 6: Windows Defender (10 pts) ─────────────────────────────────
echo  [6/10] Checking Defender...
set "defPts=0"
sc query WinDefend 2>nul | findstr "RUNNING" >nul 2>&1
if not errorlevel 1 set "defPts=10"
set /a totalScore+=defPts
if !defPts!==0 set "advice=!advice!  - Windows Defender is not running. Check Security settings.^|"
echo     Defender: ... !defPts!/10 pts

:: ── CHECK 7: Listening Ports Count (5 pts) ─────────────────────────────
echo  [7/10] Checking open ports...
set "portCount=0"
for /f %%a in ('netstat -an 2^>nul ^| findstr "LISTENING" ^| find /c "LISTENING" 2^>nul') do set "portCount=%%a"
set "portPts=0"
if !portCount! lss 20 set "portPts=5"
if !portCount! geq 20 if !portCount! lss 40 set "portPts=3"
if !portCount! geq 40 set "portPts=1"
set /a totalScore+=portPts
if !portPts! lss 5 set "advice=!advice!  - !portCount! listening ports detected. Review with PortScanner.bat.^|"
echo     Open Ports: !portCount! ... !portPts!/5 pts

:: ── CHECK 8: Startup Items Count (5 pts) ───────────────────────────────
echo  [8/10] Checking startup bloat...
set "stCount=0"
for /f %%a in ('reg query "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" 2^>nul ^| findstr /v "HKEY\|^$" ^| find /c "REG_"') do set "stCU=%%a"
for /f %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" 2^>nul ^| findstr /v "HKEY\|^$" ^| find /c "REG_"') do set "stLM=%%a"
if not defined stCU set "stCU=0"
if not defined stLM set "stLM=0"
set /a stCount=stCU+stLM
set "startPts=0"
if !stCount! lss 8 set "startPts=5"
if !stCount! geq 8 if !stCount! lss 15 set "startPts=3"
if !stCount! geq 15 set "startPts=1"
set /a totalScore+=startPts
if !startPts! lss 5 set "advice=!advice!  - !stCount! startup items detected. Use StartupManager to trim.^|"
echo     Startup Items: !stCount! ... !startPts!/5 pts

:: ── CHECK 9: Windows Update Pending (3 pts) ────────────────────────────
echo  [9/10] Checking Windows Update...
set "wuPts=3"
sc query wuauserv 2>nul | findstr "RUNNING" >nul 2>&1
if errorlevel 1 set "wuPts=1"
set /a totalScore+=wuPts
echo     Windows Update service ... !wuPts!/3 pts

:: ── CHECK 10: System Uptime (2 pts) ────────────────────────────────────
echo  [10/10] Checking uptime...
set "upPts=2"
set "bootDT="
for /f "tokens=2 delims==" %%a in ('wmic os get LastBootUpTime /value 2^>nul ^| findstr "="') do set "bootDT=%%a"
set "nowDT="
for /f "tokens=2 delims==" %%a in ('wmic os get LocalDateTime /value 2^>nul ^| findstr "="') do set "nowDT=%%a"
if defined bootDT if defined nowDT (
    set "bootDay=!bootDT:~6,2!"
    set "nowDay=!nowDT:~6,2!"
    set /a dayDiff=nowDay-bootDay
    if !dayDiff! lss 0 set /a dayDiff+=30
    if !dayDiff! gtr 7 (
        set "upPts=1"
        set "advice=!advice!  - System uptime is ~!dayDiff! days. Consider restarting weekly.^|"
    )
    if !dayDiff! gtr 14 set "upPts=0"
)
set /a totalScore+=upPts
echo     Uptime ... !upPts!/2 pts

:: ── GRADE CALCULATION ──────────────────────────────────────────────────
set "grade=F"
set "gcolor=0C"
if !totalScore! geq 60 ( set "grade=D" & set "gcolor=0E" )
if !totalScore! geq 70 ( set "grade=C" & set "gcolor=0E" )
if !totalScore! geq 80 ( set "grade=B" & set "gcolor=0B" )
if !totalScore! geq 90 ( set "grade=A" & set "gcolor=0A" )

:: ── DISPLAY RESULTS ────────────────────────────────────────────────────
echo.
color !gcolor!
echo  +============================================================+
echo  ^|                PC HEALTH SCORE RESULTS                     ^|
echo  +============================================================+
echo  ^|                                                            ^|
echo  ^|           Score : !totalScore! / !maxScore!
echo  ^|           Grade : !grade!
echo  ^|                                                            ^|

if "!grade!"=="A" echo  ^|   Excellent! Your PC is in great shape.                    ^|
if "!grade!"=="B" echo  ^|   Good. Minor optimizations possible.                       ^|
if "!grade!"=="C" echo  ^|   Fair. Several areas need attention.                       ^|
if "!grade!"=="D" echo  ^|   Poor. Multiple issues detected.                           ^|
if "!grade!"=="F" echo  ^|   Critical. Immediate attention required.                   ^|

echo  ^|                                                            ^|
echo  +============================================================+
echo.

:: Build bar
set /a barLen=totalScore/5
if !barLen! gtr 20 set "barLen=20"
set "sbar="
for /l %%i in (1,1,20) do (
    if %%i leq !barLen! (set "sbar=!sbar!#") else (set "sbar=!sbar!.")
)
echo  [!sbar!] !totalScore!%%
echo.

if defined advice (
    echo  RECOMMENDATIONS:
    echo  ----------------
    for /f "tokens=* delims=|" %%a in ("!advice!") do (
        if not "%%a"=="" echo  %%a
    )
)
echo.
pause
goto MENU

:QUICKCHECK
cls
color 0B
echo.
echo  +============================================================+
echo  ^|  QUICK HEALTH CHECK  (5 key checks)                       ^|
echo  +============================================================+
echo.
set "qs=0"

for /f "tokens=1* delims==" %%a in ('wmic os get FreePhysicalMemory,TotalVisibleMemorySize /value 2^>nul ^| findstr "="') do (
    if /i "%%a"=="FreePhysicalMemory"     ( set "rFkb=%%b" & set "rFkb=!rFkb: =!" )
    if /i "%%a"=="TotalVisibleMemorySize" ( set "rTkb=%%b" & set "rTkb=!rTkb: =!" )
)
if !rTkb! lss 1 set "rTkb=1"
set /a rFPCT=(rFkb*100)/rTkb
if !rFPCT! geq 30 ( set /a qs+=1 & echo  [PASS] RAM: !rFPCT!%% free ) else ( echo  [WARN] RAM only !rFPCT!%% free )

sc query WinDefend 2>nul | findstr "RUNNING" >nul 2>&1
if not errorlevel 1 ( set /a qs+=1 & echo  [PASS] Windows Defender is running ) else ( echo  [FAIL] Windows Defender is NOT running )

netsh advfirewall show allprofiles state 2>nul | findstr "ON" >nul 2>&1
if not errorlevel 1 ( set /a qs+=1 & echo  [PASS] Firewall is enabled ) else ( echo  [FAIL] Firewall is NOT enabled )

for /f "tokens=1* delims==" %%a in ('wmic cpu get LoadPercentage /value 2^>nul ^| findstr "="') do ( set "cl=%%b" & set "cl=!cl: =!" )
if !cl! lss 70 ( set /a qs+=1 & echo  [PASS] CPU load: !cl!%% ) else ( echo  [WARN] CPU load high: !cl!%% )

for /f "tokens=1* delims==" %%a in ('wmic logicaldisk where "Caption='C:'" get Size,FreeSpace /value 2^>nul ^| findstr "="') do (
    if /i "%%a"=="Size"      ( set "cs=%%b" & set "cs=!cs: =!" )
    if /i "%%a"=="FreeSpace" ( set "cf=%%b" & set "cf=!cf: =!" )
)
if defined cs if not "!cs!"=="" (
    if "!cs:~9,1!"=="" (set "csG=0") else (set "csG=!cs:~0,-9!")
    if "!cf:~9,1!"=="" (set "cfG=0") else (set "cfG=!cf:~0,-9!")
    if "!csG!"=="" set "csG=1"
    set /a dp=cfG*100/csG
    if !dp! geq 15 ( set /a qs+=1 & echo  [PASS] Disk C: !dp!%% free ) else ( echo  [WARN] Disk C: only !dp!%% free )
)

echo.
echo  Quick Score: !qs!/5 checks passed.
echo.
pause
goto MENU

:EXPORTREPORT
cls
color 09
echo  Generating health report... please wait.
set "rpt=%USERPROFILE%\Desktop\PCHealth_Report.txt"
:: Run the full check logic and redirect
(
echo PC HEALTH SCORE REPORT
echo Generated: %DATE% %TIME%
echo Computer: %COMPUTERNAME%
echo.
echo [RAM]
wmic os get FreePhysicalMemory,TotalVisibleMemorySize /value
echo [CPU]
wmic cpu get LoadPercentage /value
echo [DISK C:]
wmic logicaldisk where "Caption='C:'" get Size,FreeSpace /value
echo [FIREWALL]
netsh advfirewall show allprofiles state
echo [DEFENDER]
sc query WinDefend
echo [STARTUP COUNT]
reg query "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
echo [UPTIME]
wmic os get LastBootUpTime /value
) > "%rpt%" 2>nul
if exist "%rpt%" (
    color 0B
    echo  [OK] Report saved to Desktop as PCHealth_Report.txt
) else (
    echo  [ERROR] Could not write report.
)
echo.
pause
goto MENU

:EXIT
exit
