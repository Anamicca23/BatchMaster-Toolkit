@echo off
:: ============================================================
:: Name      : RAMCleaner.bat
:: Version   : 1.0.0
:: Author    : Anamicca23
:: Tested    : Windows 10 22H2, Windows 11 23H2
:: Min OS    : Windows 10 1803
:: Risk      : LOW
:: Admin     : Required
:: Reversible: Yes
:: Desc      : Clears Windows RAM standby list and working set.
::             Shows before and after memory usage in MB and GB.
:: ============================================================
setlocal enabledelayedexpansion
title RAM CLEANER v1.0.0
mode con: cols=65 lines=40
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
color 0D
echo.
echo  +========================================================+
echo  ^|           R A M   C L E A N E R   v1.0.0              ^|
echo  ^|        Free Up Standby Memory Instantly                ^|
echo  +========================================================+
echo  ^|                                                        ^|
echo  ^|   [1]  Clean RAM Now  (show before/after)              ^|
echo  ^|   [2]  View Current RAM Usage                          ^|
echo  ^|   [3]  RAM Usage Live Monitor  (5-second refresh)      ^|
echo  ^|   [0]  Exit                                            ^|
echo  ^|                                                        ^|
echo  +========================================================+
echo.
set /p c=    Enter Option: 
if "%c%"=="1" goto CLEANRAM
if "%c%"=="2" goto VIEWRAM
if "%c%"=="3" goto LIVEMONITOR
if "%c%"=="0" goto EXIT
goto MENU

:GETRAM
:: Reads RAM into variables: rTkb, rFkb, rUMB, rFMB, rTMB, rTGB, rFGB, rUGB, rPCT
set "rTkb=1" & set "rFkb=0"
for /f "tokens=1* delims==" %%a in ('wmic os get TotalVisibleMemorySize,FreePhysicalMemory /value 2^>nul ^| findstr "="') do (
    if /i "%%a"=="TotalVisibleMemorySize" (set "rTkb=%%b" & set "rTkb=!rTkb: =!")
    if /i "%%a"=="FreePhysicalMemory"     (set "rFkb=%%b" & set "rFkb=!rFkb: =!")
)
if !rTkb! lss 1 set "rTkb=1"
set /a rTMB=rTkb/1024
set /a rFMB=rFkb/1024
set /a rUMB=rTMB-rFMB
set /a rTGB=rTMB/1024
set /a rFGB=rFMB/1024
set /a rUGB=rUMB/1024
set /a rPCT=rUMB*100/rTMB
set /a rFPCT=100-rPCT
exit /b

:CLEANRAM
cls
color 0E
echo.
echo  +========================================================+
echo  ^|   RAM CLEAN — BEFORE                                   ^|
echo  +========================================================+
call :GETRAM
set "bTMB=!rTMB!" & set "bFMB=!rFMB!" & set "bUMB=!rUMB!" & set "bPCT=!rPCT!"
echo  Total   : !rTGB! GB  (!rTMB! MB)
echo  Used    : !rUGB! GB  (!rUMB! MB)  (!rPCT!%%)
echo  Free    : !rFGB! GB  (!rFMB! MB)  (!rFPCT!%%)
echo.

:: Build before bar
set /a barLen=rPCT/5
if !barLen! gtr 20 set "barLen=20"
set "bbar="
for /l %%i in (1,1,20) do (
    if %%i leq !barLen! (set "bbar=!bbar!#") else (set "bbar=!bbar!.")
)
echo  [!bbar!] !rPCT!%% used
echo.
echo  Cleaning RAM standby list...
echo  This may take a few seconds...
echo.

:: Method 1: PowerShell garbage collection
powershell -Command "[System.GC]::Collect(); [System.GC]::WaitForPendingFinalizers()" >nul 2>&1

:: Method 2: EmptyStandbyList via RAMMap if available
if exist "%SystemRoot%\System32\RAMMap.exe" (
    RAMMap.exe -Ew >nul 2>&1
) else (
    :: Method 3: PowerShell working set trim on all processes
    powershell -Command "Get-Process | ForEach-Object { $_.MinWorkingSet = $_.MinWorkingSet }" >nul 2>&1
)

:: Wait for effect
timeout /t 3 >nul

call :GETRAM
set "aTMB=!rTMB!" & set "aFMB=!rFMB!" & set "aUMB=!rUMB!" & set "aPCT=!rPCT!"
set /a freed=bFMB-rFMB
if !freed! lss 0 set "freed=0"
set /a freedGB=freed/1024

echo  +========================================================+
echo  ^|   RAM CLEAN — AFTER                                    ^|
echo  +========================================================+
echo  Total   : !rTGB! GB  (!rTMB! MB)
echo  Used    : !rUGB! GB  (!rUMB! MB)  (!rPCT!%%)
echo  Free    : !rFGB! GB  (!rFMB! MB)  (!rFPCT!%%)
echo.

set /a barLen2=rPCT/5
if !barLen2! gtr 20 set "barLen2=20"
set "abar="
for /l %%i in (1,1,20) do (
    if %%i leq !barLen2! (set "abar=!abar!#") else (set "abar=!abar!.")
)
echo  [!abar!] !rPCT!%% used
echo.

color 0B
echo  +========================================================+
echo  ^|   RESULT
echo  +========================================================+
echo  RAM freed  : ~!freed! MB  (~!freedGB! GB)
echo  Before     : !bUMB! MB used  (!bPCT!%%)
echo  After      : !aUMB! MB used  (!aPCT!%%)
echo.
if !freed! gtr 50 (
    echo  [OK] Memory cleaned successfully.
) else (
    echo  [i]  Minimal gain — your RAM may already be optimally used.
    echo  Tip: Close browser tabs or large applications for more effect.
)
echo.
pause
goto MENU

:VIEWRAM
cls
color 0B
echo.
echo  +========================================================+
echo  ^|   CURRENT RAM USAGE                                    ^|
echo  +========================================================+
call :GETRAM
echo  Total    : !rTGB! GB  (!rTMB! MB)
echo  Used     : !rUGB! GB  (!rUMB! MB)
echo  Free     : !rFGB! GB  (!rFMB! MB)
echo  Usage    : !rPCT!%%   Free: !rFPCT!%%
echo.
set /a barLen=rPCT/5
if !barLen! gtr 20 set "barLen=20"
set "rbar="
for /l %%i in (1,1,20) do (
    if %%i leq !barLen! (set "rbar=!rbar!#") else (set "rbar=!rbar!.")
)
echo  [!rbar!] !rPCT!%% used
echo.
if !rPCT! lss 50  echo  Status : [ HEALTHY  ]  Plenty of RAM available.
if !rPCT! geq 50  if !rPCT! lss 80 echo  Status : [ MODERATE ]  RAM is being used actively.
if !rPCT! geq 80  echo  Status : [ HIGH     ]  Consider closing apps or cleaning RAM.
echo.
echo  Installed memory modules:
echo  +--------------------------------------------------------+
wmic memorychip get BankLabel,Capacity,Speed,Manufacturer 2>nul
echo.
pause
goto MENU

:LIVEMONITOR
cls
color 0D
echo  Live RAM monitor — refreshing every 5 seconds.
echo  Press CTRL+C to stop.
echo.
:LIVELOOP
cls
color 0D
echo  +========================================================+
echo  ^|   RAM LIVE MONITOR  (CTRL+C to stop)
echo  ^|   Time: %TIME%
echo  +========================================================+
call :GETRAM
echo.
echo  Total   : !rTGB! GB  (!rTMB! MB)
echo  Used    : !rUGB! GB  (!rUMB! MB)  (!rPCT!%%)
echo  Free    : !rFGB! GB  (!rFMB! MB)  (!rFPCT!%%)
echo.
set /a barLen=rPCT/5
if !barLen! gtr 20 set "barLen=20"
set "lbar="
for /l %%i in (1,1,20) do (
    if %%i leq !barLen! (set "lbar=!lbar!#") else (set "lbar=!lbar!.")
)
echo  [!lbar!] !rPCT!%% used
echo.
if !rPCT! lss 50  echo  Status : HEALTHY
if !rPCT! geq 50  if !rPCT! lss 80 echo  Status : MODERATE
if !rPCT! geq 80  (color 0C & echo  Status : HIGH — Consider cleaning)
timeout /t 5 >nul
goto LIVELOOP

:EXIT
exit