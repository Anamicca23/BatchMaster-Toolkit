@echo off
:: ============================================================
:: Name      : RecycleBinManager.bat
:: Version   : 1.0.0
:: Author    : Anamicca23
:: Tested    : Windows 10 22H2, Windows 11 23H2
:: Min OS    : Windows 10 1803
:: Risk      : MEDIUM
:: Admin     : Not Required (Admin gives access to all users bins)
:: Reversible: No  (emptied files cannot be recovered)
:: Desc      : Shows recycle bin size per drive in MB and GB.
::             Interactive menu to empty individually or all at once.
::             Confirmation prompt before any deletion.
:: ============================================================
setlocal enabledelayedexpansion
title RECYCLE BIN MANAGER v1.0.0
mode con: cols=70 lines=40
if not "%1"=="RUN" start /MAX cmd /k "%~f0" RUN & exit

:MENU
cls
color 09
echo.
echo  +============================================================+
echo  ^|       R E C Y C L E   B I N   M A N A G E R  v1.0.0      ^|
echo  +============================================================+
echo  ^|                                                            ^|
echo  ^|   [1]  Show All Recycle Bin Sizes                          ^|
echo  ^|   [2]  Empty Recycle Bin for C:\ Drive                     ^|
echo  ^|   [3]  Empty Recycle Bin for D:\ Drive                     ^|
echo  ^|   [4]  Empty ALL Recycle Bins  (all drives)                ^|
echo  ^|   [5]  List Files in Recycle Bin (C: only)                 ^|
echo  ^|   [6]  Restore Note — how to undo                          ^|
echo  ^|   [0]  Exit                                                ^|
echo  ^|                                                            ^|
echo  +============================================================+
echo.
set /p c=    Enter Option: 
if "%c%"=="1" goto SHOWSIZES
if "%c%"=="2" goto EMPTYC
if "%c%"=="3" goto EMPTYD
if "%c%"=="4" goto EMPTYALL
if "%c%"=="5" goto LISTFILES
if "%c%"=="6" goto RESTORENOTE
if "%c%"=="0" goto EXIT
goto MENU

:GETBINSIZE
:: Usage: call :GETBINSIZE "C:" -> sets binMB and binFiles
set "binDrive=%~1"
set "binMB=0"
set "binFiles=0"
set "binPath=!binDrive!\$Recycle.Bin"
if exist "!binPath!" (
    for /f "tokens=3,4" %%a in ('dir "!binPath!" /s /-c 2^>nul ^| findstr "File(s)"') do (
        set "binBytes=%%a"
        set "binFiles=%%b"
    )
    if defined binBytes (
        set "binBytes=!binBytes:,=!"
        set /a binMB=binBytes/1048576
        set /a binGB=binMB/1024
    )
)
exit /b

:SHOWSIZES
cls
color 09
echo.
echo  +============================================================+
echo  ^|   RECYCLE BIN SIZES PER DRIVE                              ^|
echo  +============================================================+
echo.
echo  Calculating sizes... please wait.
echo.

set "totalMB=0"
for /f "tokens=1* delims==" %%a in ('wmic logicaldisk get Caption /value 2^>nul ^| findstr /i "^Caption="') do (
    set "drv=%%b" & set "drv=!drv: =!"
    if defined drv if not "!drv!"=="" (
        set "binMB=0" & set "binFiles=0" & set "binGB=0"
        call :GETBINSIZE "!drv!"
        set /a totalMB+=binMB
        echo  Drive !drv!   Recycle Bin size : !binMB! MB  (!binGB! GB)
    )
)
set /a totalGB=totalMB/1024
echo.
echo  +------------------------------------------------------------+
echo  Total across all drives : !totalMB! MB  (!totalGB! GB)
echo  +------------------------------------------------------------+
echo.
if !totalMB! gtr 500 (
    color 0E
    echo  [TIP] You have over 500 MB in Recycle Bins.
    echo  Consider emptying them to reclaim disk space.
) else (
    color 0A
    echo  [OK] Recycle Bin sizes are reasonable.
)
echo.
pause
goto MENU

:EMPTYC
echo.
echo  +------------------------------------------------------------+
echo  ^|  [WARNING] This will PERMANENTLY delete all files         ^|
echo  ^|  in the C:\ Recycle Bin. This cannot be undone.           ^|
echo  +------------------------------------------------------------+
echo.
set /p confirm=  Empty C:\ Recycle Bin? (Y/N): 
if /i not "%confirm%"=="Y" (
    echo  Cancelled.
    pause
    goto MENU
)
rd /s /q "C:\$Recycle.Bin" >nul 2>&1
color 0B
echo.
echo  [DONE] C:\ Recycle Bin emptied.
echo.
pause
goto MENU

:EMPTYD
echo.
if not exist "D:\$Recycle.Bin" (
    echo  D:\ drive not found or has no Recycle Bin.
    pause
    goto MENU
)
echo  +------------------------------------------------------------+
echo  ^|  [WARNING] This will PERMANENTLY delete all files         ^|
echo  ^|  in the D:\ Recycle Bin. This cannot be undone.           ^|
echo  +------------------------------------------------------------+
echo.
set /p confirm=  Empty D:\ Recycle Bin? (Y/N): 
if /i not "%confirm%"=="Y" (
    echo  Cancelled.
    pause
    goto MENU
)
rd /s /q "D:\$Recycle.Bin" >nul 2>&1
color 0B
echo.
echo  [DONE] D:\ Recycle Bin emptied.
echo.
pause
goto MENU

:EMPTYALL
echo.
echo  +------------------------------------------------------------+
echo  ^|  [WARNING] This will PERMANENTLY delete ALL files in      ^|
echo  ^|  the Recycle Bin across EVERY drive.                      ^|
echo  ^|  This action CANNOT be undone.                            ^|
echo  +------------------------------------------------------------+
echo.
set /p confirm=  Empty ALL Recycle Bins? (Y/N): 
if /i not "%confirm%"=="Y" (
    echo  Cancelled. No files were deleted.
    pause
    goto MENU
)
cls
color 0E
echo.
echo  Emptying all Recycle Bins...
echo.
set "doneCount=0"
for /f "tokens=1* delims==" %%a in ('wmic logicaldisk get Caption /value 2^>nul ^| findstr /i "^Caption="') do (
    set "drv=%%b" & set "drv=!drv: =!"
    if defined drv if not "!drv!"=="" (
        if exist "!drv!\$Recycle.Bin" (
            rd /s /q "!drv!\$Recycle.Bin" >nul 2>&1
            set /a doneCount+=1
            echo  Emptied: !drv!\$Recycle.Bin
        )
    )
)
color 0B
echo.
echo  +------------------------------------------------------------+
echo  [DONE] Emptied !doneCount! Recycle Bin(s) across all drives.
echo  +------------------------------------------------------------+
echo.
pause
goto MENU

:LISTFILES
cls
color 09
echo.
echo  +============================================================+
echo  ^|   FILES IN C:\ RECYCLE BIN                                ^|
echo  +============================================================+
echo.
if not exist "C:\$Recycle.Bin" (
    echo  C:\ Recycle Bin is already empty or inaccessible.
) else (
    dir "C:\$Recycle.Bin" /s /b 2>nul
    if errorlevel 1 echo  No files found or access denied. Run as Administrator for full access.
)
echo.
pause
goto MENU

:RESTORENOTE
cls
color 09
echo.
echo  +============================================================+
echo  ^|   HOW TO RESTORE FILES FROM RECYCLE BIN                   ^|
echo  +============================================================+
echo.
echo  Before emptying — how to restore files:
echo  -----------------------------------------
echo  1. Open File Explorer
echo  2. Click "Recycle Bin" in the left panel
echo  3. Right-click any file ^> Restore
echo     (file goes back to its original location)
echo.
echo  After emptying — files CANNOT be recovered with:
echo  -----------------------------------------
echo  - Windows built-in tools
echo  - Command Prompt
echo  - This script
echo.
echo  After emptying — recovery MAY be possible with:
echo  -----------------------------------------
echo  - Recuva (free): https://www.ccleaner.com/recuva
echo  - Disk Drill   : https://www.cleverfiles.com/
echo  - TestDisk     : https://www.cgsecurity.org/
echo.
echo  Success rate of recovery tools decreases over time
echo  and after new files are written to the same drive.
echo.
pause
goto MENU

:EXIT
exit