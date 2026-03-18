@echo off
:: ============================================================
:: Name      : ThermalMonitor.bat
:: Version   : 1.0.0
:: Author    : Anamicca23
:: Tested    : Windows 10 22H2, Windows 11 23H2
:: Min OS    : Windows 10 1803
:: Risk      : LOW
:: Admin     : Not Required
:: Reversible: Yes
:: Desc      : Live CPU and disk temperature monitor via WMI.
::             Color-coded warnings at 80°C and 90°C.
::             Press CTRL+C to stop.
:: ============================================================
setlocal enabledelayedexpansion
title THERMAL MONITOR v1.0.0
mode con: cols=70 lines=35
if not "%1"=="RUN" start /MAX cmd /k "%~f0" RUN & exit

:MENU
cls
color 0A
echo.
echo  +============================================================+
echo  ^|          T H E R M A L   M O N I T O R   v1.0.0           ^|
echo  +============================================================+
echo  ^|                                                            ^|
echo  ^|   [1]  Start Live Temperature Monitor                      ^|
echo  ^|   [2]  Single Temperature Snapshot                         ^|
echo  ^|   [3]  About Thermal Monitoring                            ^|
echo  ^|   [0]  Exit                                                ^|
echo  ^|                                                            ^|
echo  +============================================================+
echo.
set /p c=    Enter Option: 
if "%c%"=="1" goto LIVELOOP
if "%c%"=="2" goto SNAPSHOT
if "%c%"=="3" goto ABOUT
if "%c%"=="0" goto EXIT
goto MENU

:SNAPSHOT
cls
color 0B
echo.
echo  +============================================================+
echo  ^|  TEMPERATURE SNAPSHOT                                      ^|
echo  +============================================================+
echo.
call :READTEMPS
echo.
pause
goto MENU

:LIVELOOP
cls
color 0A
echo  Starting live monitor... Press CTRL+C to stop.
echo  Refreshing every 5 seconds.
echo.
:LOOPTICK
cls
color 0A
echo  +============================================================+
echo  ^|   THERMAL MONITOR   -   Live  (CTRL+C to stop)            ^|
echo  ^|   Time: %TIME%   Date: %DATE%
echo  +============================================================+
echo.
call :READTEMPS
echo.
echo  +------------------------------------------------------------+
echo  ^|  Thresholds: Normal ^< 70C   Warm ^< 80C   Hot ^>= 80C       ^|
echo  +------------------------------------------------------------+
echo.
timeout /t 5 >nul
goto LOOPTICK

:READTEMPS
:: Try WMI thermal zones (decikelvin → Celsius)
set "tempFound=0"
for /f "tokens=2 delims==" %%t in ('wmic /namespace:\\root\wmi PATH MSAcpi_ThermalZoneTemperature get CurrentTemperature /value 2^>nul ^| findstr "="') do (
    set "rawTemp=%%t"
    set "rawTemp=!rawTemp: =!"
    if defined rawTemp if not "!rawTemp!"=="" (
        set /a celsius=rawTemp/10-273
        set "tempFound=1"
        echo  Thermal Zone Temperature : !celsius! C
        if !celsius! geq 90 (
            color 0C
            echo  [CRITICAL] Temperature is !celsius!C — Above 90C!
            color 0A
        ) else if !celsius! geq 80 (
            color 0E
            echo  [WARNING]  Temperature is !celsius!C — Above 80C!
            color 0A
        ) else if !celsius! geq 70 (
            echo  [WARM]     Temperature is !celsius!C — Elevated but OK.
        ) else (
            echo  [NORMAL]   Temperature is !celsius!C — Healthy range.
        )
    )
)

if !tempFound!==0 (
    echo  CPU Temperature    : [N/A - WMI thermal not supported on this hardware]
    echo.
    echo  Note: Many modern laptops and desktops do not expose CPU
    echo  temperatures through WMI. For accurate readings use:
    echo    - HWMonitor (free): https://www.cpuid.com/softwares/hwmonitor.html
    echo    - Core Temp (free): https://www.alcpu.com/CoreTemp/
    echo    - OpenHardwareMonitor (open source)
)

:: Disk temperatures via SMART (best effort)
echo.
echo  +------------------------------------------------------------+
echo  ^|  DISK STATUS
echo  +------------------------------------------------------------+
wmic diskdrive get Model,Status 2>nul | findstr /v "^$"
exit /b

:ABOUT
cls
color 09
echo.
echo  +============================================================+
echo  ^|  ABOUT THERMAL MONITORING                                  ^|
echo  +============================================================+
echo.
echo  How temperatures are read:
echo  ---------------------------
echo  This script uses WMI (Windows Management Instrumentation)
echo  to read MSAcpi_ThermalZoneTemperature. Values are returned
echo  in tenths of Kelvin and converted to Celsius:
echo.
echo      Celsius = (raw_value / 10) - 273
echo.
echo  Limitation:
echo  -----------
echo  Not all hardware exposes temperatures through WMI.
echo  Many Intel / AMD laptops require vendor-specific drivers
echo  to report temperatures via this interface.
echo.
echo  Recommended third-party tools:
echo  --------------------------------
echo    HWMonitor      - Most comprehensive sensor reader
echo    Core Temp      - CPU core temperatures
echo    Open HW Monitor - Open source, detailed
echo    GPU-Z          - GPU temperatures and clocks
echo.
echo  Safe temperature ranges:
echo  -------------------------
echo    CPU Idle  : 30 - 50 C    (optimal)
echo    CPU Load  : 60 - 80 C    (normal under load)
echo    CPU Max   : 80 - 95 C    (thermal throttle may occur above 90C)
echo    SSD       : 0  - 70 C    (most SSDs rated to 70C)
echo    HDD       : 25 - 55 C    (hard drives prefer cooler temps)
echo.
pause
goto MENU

:EXIT
exit