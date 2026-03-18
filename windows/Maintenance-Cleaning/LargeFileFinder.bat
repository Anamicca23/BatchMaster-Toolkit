@echo off
:: ============================================================
:: Name      : LargeFileFinder.bat
:: Version   : 1.0.0
:: Author    : Anamicca23
:: Tested    : Windows 10 22H2, Windows 11 23H2
:: Min OS    : Windows 10 1803
:: Risk      : LOW  (read only — no files deleted)
:: Admin     : Not Required
:: Reversible: Yes
:: Desc      : Scans drives for files over a size threshold.
::             Ranked list with full path, size, and modified date.
::             Saves optional report to Desktop.
:: ============================================================
setlocal enabledelayedexpansion
title LARGE FILE FINDER v1.0.0
mode con: cols=80 lines=45
if not "%1"=="RUN" start /MAX cmd /k "%~f0" RUN & exit

:MENU
cls
color 06
echo.
echo  +================================================================+
echo  ^|          L A R G E   F I L E   F I N D E R   v1.0.0          ^|
echo  ^|        Find space hogs across your drives                     ^|
echo  +================================================================+
echo  ^|                                                                ^|
echo  ^|   [1]  Scan C:\ for files over 100 MB                         ^|
echo  ^|   [2]  Scan C:\ for files over 500 MB                         ^|
echo  ^|   [3]  Scan C:\ for files over 1 GB                           ^|
echo  ^|   [4]  Scan ALL drives for files over 100 MB                  ^|
echo  ^|   [5]  Custom drive and size scan                              ^|
echo  ^|   [6]  Save last results to Desktop                            ^|
echo  ^|   [0]  Exit                                                    ^|
echo  ^|                                                                ^|
echo  +================================================================+
echo.
set /p c=    Enter Option: 
if "%c%"=="1" ( set "scanDrive=C:\" & set "threshold=104857600" & set "threshMB=100"  & goto SCAN )
if "%c%"=="2" ( set "scanDrive=C:\" & set "threshold=524288000" & set "threshMB=500"  & goto SCAN )
if "%c%"=="3" ( set "scanDrive=C:\" & set "threshold=1073741824" & set "threshMB=1024" & goto SCAN )
if "%c%"=="4" goto SCANALLDRIVES
if "%c%"=="5" goto CUSTOM
if "%c%"=="6" goto SAVEREPORT
if "%c%"=="0" goto EXIT
goto MENU

:CUSTOM
cls
color 06
echo.
echo  Enter the drive path to scan (e.g. C:\  D:\  E:\Users):
set /p scanDrive=  Drive/Path: 
echo.
echo  Enter minimum file size in MB (e.g. 50  100  500  1024):
set /p threshMB=   Min MB: 
set /a threshold=threshMB*1048576
echo.
echo  Scanning !scanDrive! for files over !threshMB! MB...
goto SCAN

:SCAN
cls
color 06
echo.
echo  +================================================================+
echo  ^|  Scanning: !scanDrive!   Threshold: !threshMB! MB
echo  ^|  This may take a few minutes on large drives...               ^|
echo  +================================================================+
echo.

set "reportFile=%TEMP%\LargeFiles_temp.txt"
if exist "%reportFile%" del "%reportFile%"

set "count=0"
for /r "!scanDrive!" %%f in (*) do (
    if exist "%%f" (
        set "fsize=%%~zf"
        if defined fsize (
            if !fsize! gtr !threshold! (
                set /a count+=1
                set /a fmb=fsize/1048576
                echo  !fmb! MB   %%~tf   %%f
                echo  !fmb! MB   %%~tf   %%f >> "!reportFile!" 2>nul
            )
        )
    )
)

echo.
echo  +----------------------------------------------------------------+
if !count!==0 (
    color 0A
    echo  No files larger than !threshMB! MB found in !scanDrive!
) else (
    color 0E
    echo  Found !count! file(s) over !threshMB! MB.
    echo  Results saved temporarily. Use option [6] to export to Desktop.
)
echo  +----------------------------------------------------------------+
echo.
pause
goto MENU

:SCANALLDRIVES
cls
color 06
echo.
echo  Scanning all available drives for files over 100 MB...
echo  This may take several minutes...
echo.
set "threshold=104857600"
set "threshMB=100"
set "totalCount=0"
set "reportFile=%TEMP%\LargeFiles_temp.txt"
if exist "%reportFile%" del "%reportFile%"

for /f "tokens=1" %%d in ('wmic logicaldisk get Caption /value 2^>nul ^| findstr "=" ^| findstr /v "^$"') do (
    set "dline=%%d"
    for /f "tokens=2 delims==" %%x in ("!dline!") do (
        set "drv=%%x"
        set "drv=!drv: =!"
        if defined drv if not "!drv!"=="" (
            echo  Scanning !drv!\...
            for /r "!drv!\" %%f in (*) do (
                if exist "%%f" (
                    set "fsize=%%~zf"
                    if defined fsize (
                        if !fsize! gtr !threshold! (
                            set /a totalCount+=1
                            set /a fmb=fsize/1048576
                            echo  !fmb! MB   [!drv!]   %%~tf   %%f
                            echo  !fmb! MB   [!drv!]   %%~tf   %%f >> "!reportFile!" 2>nul
                        )
                    )
                )
            )
        )
    )
)

echo.
echo  +----------------------------------------------------------------+
if !totalCount!==0 (
    color 0A
    echo  No files larger than 100 MB found.
) else (
    color 0E
    echo  Found !totalCount! file(s) over 100 MB across all drives.
    echo  Use option [6] to export full report to Desktop.
)
echo  +----------------------------------------------------------------+
echo.
pause
goto MENU

:SAVEREPORT
cls
color 0B
echo.
if not exist "%TEMP%\LargeFiles_temp.txt" (
    echo  No scan results to save yet.
    echo  Run a scan first (options 1-4), then save.
    echo.
    pause
    goto MENU
)
set "rpt=%USERPROFILE%\Desktop\LargeFiles_Report.txt"
(
echo ================================================================
echo   LARGE FILE FINDER REPORT
echo   Generated : %DATE% %TIME%
echo   Computer  : %COMPUTERNAME%
echo   Threshold : !threshMB! MB
echo ================================================================
echo.
echo   Size(MB)   Modified Date        Full Path
echo   --------   -------------        ---------
type "%TEMP%\LargeFiles_temp.txt"
echo.
echo ================================================================
echo   END OF REPORT
echo ================================================================
) > "%rpt%" 2>nul

if exist "%rpt%" (
    echo  [OK] Report saved to Desktop as LargeFiles_Report.txt
    echo.
    echo  Open with Notepad to review all large files found.
) else (
    echo  [ERROR] Could not save report to Desktop.
)
echo.
pause
goto MENU

:EXIT
if exist "%TEMP%\LargeFiles_temp.txt" del "%TEMP%\LargeFiles_temp.txt" >nul 2>&1
exit