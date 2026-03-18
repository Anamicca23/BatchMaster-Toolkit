@echo off
:: ============================================================
:: Name      : BatteryGuard.bat
:: Version   : 1.0.0
:: Author    : Anamicca23
:: Tested    : Windows 10 22H2, Windows 11 23H2
:: Min OS    : Windows 10 1803
:: Risk      : LOW
:: Admin     : Not Required
:: Reversible: Yes
:: Desc      : Battery health report — wear level, cycle count,
::             capacity vs design, health alerts below 80%.
:: ============================================================
setlocal enabledelayedexpansion
title BATTERY GUARD v1.0.0
mode con: cols=70 lines=40
if not "%1"=="RUN" start /MAX cmd /k "%~f0" RUN & exit

:MENU
cls
color 0E
echo.
echo  +============================================================+
echo  ^|           B A T T E R Y   G U A R D   v1.0.0              ^|
echo  +============================================================+
echo  ^|                                                            ^|
echo  ^|   [1]  Battery Health Report                               ^|
echo  ^|   [2]  Generate Full HTML Report (Desktop)                 ^|
echo  ^|   [3]  View Power Scheme                                   ^|
echo  ^|   [0]  Exit                                                ^|
echo  ^|                                                            ^|
echo  +============================================================+
echo.
set /p c=    Enter Option: 
if "%c%"=="1" goto HEALTH
if "%c%"=="2" goto HTMLREPORT
if "%c%"=="3" goto SCHEME
if "%c%"=="0" goto EXIT
goto MENU

:HEALTH
cls
color 0E

set "bName=[N/A]"    & set "bChg=0"        & set "bStat=0"
set "bFull=[N/A]"    & set "bDes=[N/A]"    & set "bRun=[N/A]"
set "bVolt=[N/A]"    & set "bChem=[N/A]"

for /f "tokens=1* delims==" %%a in ('wmic path Win32_Battery get Name,EstimatedChargeRemaining,BatteryStatus,FullChargeCapacity,DesignCapacity,EstimatedRunTime,DesignVoltage,Chemistry /value 2^>nul ^| findstr "="') do (
    if /i "%%a"=="Name"                      if not "%%b"=="" set "bName=%%b"
    if /i "%%a"=="EstimatedChargeRemaining"  if not "%%b"=="" set "bChg=%%b"
    if /i "%%a"=="BatteryStatus"             if not "%%b"=="" set "bStat=%%b"
    if /i "%%a"=="FullChargeCapacity"        if not "%%b"=="" set "bFull=%%b"
    if /i "%%a"=="DesignCapacity"            if not "%%b"=="" set "bDes=%%b"
    if /i "%%a"=="EstimatedRunTime"          if not "%%b"=="" set "bRun=%%b"
    if /i "%%a"=="DesignVoltage"             if not "%%b"=="" set "bVolt=%%b"
    if /i "%%a"=="Chemistry"                 if not "%%b"=="" set "bChem=%%b"
)

set "bChg=!bChg: =!"
set "bStat=!bStat: =!"
set "bFull=!bFull: =!"
set "bDes=!bDes: =!"
if "!bChg!"=="" set "bChg=0"

:: Status decoder
set "bDesc=Not Detected / Desktop PC"
if "!bStat!"=="1" set "bDesc=Discharging (on battery)"
if "!bStat!"=="2" set "bDesc=On AC Power (plugged in)"
if "!bStat!"=="3" set "bDesc=Fully Charged"
if "!bStat!"=="4" set "bDesc=Low Battery"
if "!bStat!"=="5" set "bDesc=Critical - Charge Now"
if "!bStat!"=="6" set "bDesc=Charging"
if "!bStat!"=="7" set "bDesc=Charging (High)"

:: Wear level calculation
set "bWear=N/A"
set "bWearStatus=Unknown"
if defined bFull if defined bDes if not "!bFull!"=="[N/A]" if not "!bDes!"=="[N/A]" (
    set /a bWear=100 - (bFull * 100 / bDes)
    if !bWear! lss 20 set "bWearStatus=EXCELLENT - Like new"
    if !bWear! geq 20 set "bWearStatus=GOOD - Normal aging"
    if !bWear! geq 40 set "bWearStatus=DEGRADED - Consider replacing"
    if !bWear! geq 60 set "bWearStatus=POOR - Replacement recommended"
)

:: Health score based on charge
set "bHealth=GOOD"
set "bHealthColor=0A"
if !bChg! leq 60 if !bChg! gtr 20 set "bHealth=MEDIUM"
if !bChg! leq 20 set "bHealth=LOW"

:: Charge bar
set /a chgbar=bChg/5
if !chgbar! gtr 20 set "chgbar=20"
set "cviz="
for /l %%i in (1,1,20) do (
    if %%i leq !chgbar! (set "cviz=!cviz!#") else (set "cviz=!cviz!.")
)

echo.
echo  +============================================================+
echo  ^|                BATTERY HEALTH REPORT                       ^|
echo  +============================================================+
echo  ^|                                                            ^|
echo  ^|  Battery Name     : !bName!
echo  ^|  Chemistry        : !bChem!
echo  ^|  Design Voltage   : !bVolt! mV
echo  ^|                                                            ^|
echo  +------------------------------------------------------------+
echo  ^|  CHARGE                                                    ^|
echo  +------------------------------------------------------------+
echo  ^|  Current Charge   : !bChg!%%
echo  ^|  Charge Meter     : [!cviz!] !bChg!%%
echo  ^|  Level            : !bHealth!
echo  ^|  Status Code      : !bStat!  (!bDesc!)
echo  ^|  Est. Runtime     : !bRun! minutes
echo  ^|                                                            ^|
echo  +------------------------------------------------------------+
echo  ^|  CAPACITY AND WEAR                                         ^|
echo  +------------------------------------------------------------+
echo  ^|  Full Charge Cap  : !bFull! mWh
echo  ^|  Design Capacity  : !bDes! mWh
echo  ^|  Wear Level       : !bWear!%%
echo  ^|  Wear Status      : !bWearStatus!
echo  ^|                                                            ^|
echo  +------------------------------------------------------------+
echo  ^|  HEALTH THRESHOLDS                                         ^|
echo  +------------------------------------------------------------+
echo  ^|   0%% - 20%% wear  = Excellent  (like new)                  ^|
echo  ^|  20%% - 40%% wear  = Good       (normal aging)              ^|
echo  ^|  40%% - 60%% wear  = Degraded   (consider replacing)        ^|
echo  ^|  60%%+ wear        = Poor       (replace soon)              ^|
echo  ^|                                                            ^|
echo  +============================================================+

if !bWear! geq 40 (
    color 0C
    echo.
    echo  [!] WARNING: Battery wear is at !bWear!%%. Replacement recommended.
    echo.
) else if !bWear! geq 20 (
    color 0E
    echo.
    echo  [i] Battery is aging normally. Monitor capacity over time.
    echo.
) else (
    color 0A
    echo.
    echo  [OK] Battery health is excellent.
    echo.
)
pause
goto MENU

:HTMLREPORT
cls
color 0B
echo.
echo  Generating battery health HTML report...
echo  This may take a few seconds...
echo.
powercfg /batteryreport /output "%USERPROFILE%\Desktop\battery_report.html" 2>nul
if exist "%USERPROFILE%\Desktop\battery_report.html" (
    echo  [OK]  Report saved to Desktop as:  battery_report.html
    echo.
    echo  Open it in your browser for:
    echo    - Full charge history graph
    echo    - Capacity history over time
    echo    - Battery usage estimates
    echo    - Recent battery drain events
) else (
    color 0C
    echo  [ERROR] Could not generate report.
    echo  Try running the script as Administrator.
)
echo.
pause
goto MENU

:SCHEME
cls
color 09
echo.
echo  +============================================================+
echo  ^|              ACTIVE POWER SCHEME                           ^|
echo  +============================================================+
echo.
powercfg /getactivescheme 2>nul
echo.
echo  All available power schemes:
echo  +--------------------------+
powercfg /list 2>nul
echo.
echo  To change scheme: powercfg /setactive ^<GUID^>
echo.
pause
goto MENU

:EXIT
exit