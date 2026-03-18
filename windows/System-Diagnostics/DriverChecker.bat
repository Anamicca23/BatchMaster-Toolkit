@echo off
:: ============================================================
:: Name      : DriverChecker.bat
:: Version   : 1.0.0
:: Author    : Anamicca23
:: Tested    : Windows 10 22H2, Windows 11 23H2
:: Min OS    : Windows 10 1803
:: Risk      : LOW
:: Admin     : Required
:: Reversible: Yes
:: Desc      : Lists all installed drivers with version and date.
::             Flags drivers older than 12 months and unsigned ones.
:: ============================================================
setlocal enabledelayedexpansion
title DRIVER CHECKER v1.0.0
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
echo  ^|              D R I V E R   C H E C K E R   v1.0.0             ^|
echo  +================================================================+
echo  ^|                                                                ^|
echo  ^|   [1]  Show All Installed Drivers                              ^|
echo  ^|   [2]  Show ONLY Outdated Drivers  (older than 12 months)      ^|
echo  ^|   [3]  Show ONLY Unsigned Drivers                              ^|
echo  ^|   [4]  Export Full Driver Report to Desktop                    ^|
echo  ^|   [0]  Exit                                                    ^|
echo  ^|                                                                ^|
echo  +================================================================+
echo.
set /p c=    Enter Option: 
if "%c%"=="1" goto ALLDRIVERS
if "%c%"=="2" goto OUTDATED
if "%c%"=="3" goto UNSIGNED
if "%c%"=="4" goto EXPORTREPORT
if "%c%"=="0" goto EXIT
goto MENU

:ALLDRIVERS
cls
color 0B
echo.
echo  +================================================================+
echo  ^|  ALL INSTALLED DRIVERS                                         ^|
echo  +================================================================+
echo  ^|  DeviceName                     DriverVersion    DriverDate    ^|
echo  +----------------------------------------------------------------+
echo.
wmic path win32_PnPSignedDriver get DeviceName,DriverVersion,DriverDate,IsSigned /format:list 2>nul | findstr "="
echo.
echo  +----------------------------------------------------------------+
echo  Tip: Dates are in YYYYMMDD format. IsSigned=TRUE means verified.
echo.
pause
goto MENU

:OUTDATED
cls
color 0E
echo.
echo  +================================================================+
echo  ^|  OUTDATED DRIVERS  (12+ months old)                           ^|
echo  +================================================================+
echo.
echo  Scanning drivers... this may take 30-60 seconds.
echo.

:: Get current year and month for comparison
for /f "tokens=1-3 delims=/" %%a in ("%DATE%") do (
    set "mm=%%a" & set "dd=%%b" & set "yyyy=%%c"
)
:: Reformat depending on locale — use wmic for reliable date
for /f "tokens=2 delims==" %%a in ('wmic os get LocalDateTime /value 2^>nul ^| findstr "="') do (
    set "nowDT=%%a"
)
set "nowYear=!nowDT:~0,4!"
set "nowMon=!nowDT:~4,2!"
set /a cutoffYear=nowYear
set /a cutoffMon=nowMon-12
if !cutoffMon! leq 0 (
    set /a cutoffYear=nowYear-1
    set /a cutoffMon=cutoffMon+12
)
if !cutoffMon! lss 10 set "cutoffMon=0!cutoffMon!"

echo  Checking for drivers with date before !cutoffYear!/!cutoffMon!...
echo.

set "foundCount=0"
for /f "tokens=1* delims==" %%k in ('wmic path win32_PnPSignedDriver get DeviceName,DriverDate,DriverVersion /value 2^>nul ^| findstr "="') do (
    if /i "%%k"=="DriverDate" (
        set "dDate=%%l"
        set "dDate=!dDate: =!"
        if defined dDate if not "!dDate!"=="" (
            set "dYear=!dDate:~0,4!"
            set "dMon=!dDate:~4,2!"
            if "!dYear!" lss "!cutoffYear!" (
                set /a foundCount+=1
            ) else if "!dYear!"=="!cutoffYear!" (
                if "!dMon!" lss "!cutoffMon!" set /a foundCount+=1
            )
        )
    )
)

if !foundCount!==0 (
    color 0A
    echo  [OK] No drivers older than 12 months found.
) else (
    color 0E
    echo  Found !foundCount! potentially outdated driver(s).
    echo  Run Windows Update or visit your hardware manufacturer's site
    echo  to download updated drivers.
    echo.
    echo  Full driver date listing (for manual review):
    echo  +---------------------------------------------------------+
    wmic path win32_PnPSignedDriver get DeviceName,DriverDate,DriverVersion /format:list 2>nul | findstr "="
)
echo.
pause
goto MENU

:UNSIGNED
cls
color 0C
echo.
echo  +================================================================+
echo  ^|  UNSIGNED DRIVERS                                              ^|
echo  +================================================================+
echo.
echo  Scanning for unsigned/unverified drivers...
echo.
set "unsignedCount=0"
for /f "tokens=1* delims==" %%k in ('wmic path win32_PnPSignedDriver get DeviceName,IsSigned,DriverVersion /value 2^>nul ^| findstr "="') do (
    if /i "%%k"=="IsSigned" (
        set "sig=%%l" & set "sig=!sig: =!"
        if /i "!sig!"=="FALSE" set /a unsignedCount+=1
    )
)
if !unsignedCount!==0 (
    color 0A
    echo  [OK] All drivers appear to be signed.
) else (
    color 0C
    echo  [!] Found !unsignedCount! unsigned driver(s).
    echo.
    echo  Unsigned drivers are not verified by Microsoft.
    echo  They may be outdated, from unofficial sources, or potentially unsafe.
    echo.
    echo  Full IsSigned listing:
    echo  +---------------------------------------------------------+
    wmic path win32_PnPSignedDriver get DeviceName,IsSigned,DriverVersion /format:list 2>nul | findstr "IsSigned=FALSE"
)
echo.
echo  Tip: Run "sigverif" in Run dialog for the built-in Windows tool.
echo.
pause
goto MENU

:EXPORTREPORT
cls
color 0B
echo.
echo  Exporting driver report to Desktop...
echo.
set "rpt=%USERPROFILE%\Desktop\DriverReport.txt"
(
echo ============================================================
echo   DRIVER REPORT
echo   Generated: %DATE% %TIME%
echo   Computer : %COMPUTERNAME%
echo ============================================================
echo.
echo [ALL DRIVERS]
wmic path win32_PnPSignedDriver get DeviceName,DriverVersion,DriverDate,IsSigned /format:list
echo.
echo [UNSIGNED DRIVERS]
wmic path win32_PnPSignedDriver where "IsSigned='FALSE'" get DeviceName,DriverVersion,DriverDate /format:list
echo.
echo ============================================================
echo   END OF REPORT
echo ============================================================
) > "%rpt%" 2>nul
if exist "%rpt%" (
    echo  [OK] Report saved to Desktop as DriverReport.txt
) else (
    echo  [ERROR] Could not write report.
)
echo.
pause
goto MENU

:EXIT
exit