@echo off
:: ============================================================
:: Name      : DuplicateFinder.bat
:: Version   : 1.0.0
:: Author    : Anamicca23
:: Tested    : Windows 10 22H2, Windows 11 23H2
:: Min OS    : Windows 10 1803
:: Risk      : LOW  (read only — no files deleted)
:: Admin     : Not Required
:: Reversible: Yes
:: Desc      : Scans a folder for duplicate files by comparing
::             file name and byte size. Lists all duplicate groups
::             with full paths for manual review.
::             Does NOT auto-delete — you decide what to remove.
:: ============================================================
setlocal enabledelayedexpansion
title DUPLICATE FILE FINDER v1.0.0
mode con: cols=80 lines=45
if not "%1"=="RUN" start /MAX cmd /k "%~f0" RUN & exit

:MENU
cls
color 0D
echo.
echo  +================================================================+
echo  ^|        D U P L I C A T E   F I L E   F I N D E R  v1.0.0    ^|
echo  ^|      Find wasted space from duplicate files                   ^|
echo  +================================================================+
echo  ^|                                                                ^|
echo  ^|   [1]  Scan a folder for duplicates                           ^|
echo  ^|   [2]  Scan Downloads folder                                  ^|
echo  ^|   [3]  Scan Desktop                                           ^|
echo  ^|   [4]  Scan Documents folder                                  ^|
echo  ^|   [5]  About — How duplicate detection works                  ^|
echo  ^|   [0]  Exit                                                   ^|
echo  ^|                                                                ^|
echo  +================================================================+
echo.
set /p c=    Enter Option: 
if "%c%"=="1" goto CUSTOMSCAN
if "%c%"=="2" ( set "scanPath=%USERPROFILE%\Downloads" & goto DOSCAN )
if "%c%"=="3" ( set "scanPath=%USERPROFILE%\Desktop"   & goto DOSCAN )
if "%c%"=="4" ( set "scanPath=%USERPROFILE%\Documents" & goto DOSCAN )
if "%c%"=="5" goto ABOUT
if "%c%"=="0" goto EXIT
goto MENU

:CUSTOMSCAN
cls
color 0D
echo.
echo  Enter the full path of the folder to scan.
echo  Example:  C:\Users\%USERNAME%\Pictures
echo            D:\Projects
echo.
set /p scanPath=  Folder path: 
if not exist "!scanPath!" (
    color 0C
    echo.
    echo  [ERROR] Folder not found: !scanPath!
    echo  Please check the path and try again.
    echo.
    pause
    goto MENU
)
goto DOSCAN

:DOSCAN
cls
color 0D
echo.
echo  +================================================================+
echo  ^|  Scanning: !scanPath!
echo  ^|  Method: Name + File Size comparison
echo  ^|  Note: This is read-only. No files will be deleted.           ^|
echo  +================================================================+
echo.
echo  Building file list... this may take a moment.
echo.

:: Build a temp list of all files with size and name
set "tmpList=%TEMP%\duplist_all.txt"
set "tmpDups=%TEMP%\duplist_dups.txt"
set "tmpReport=%TEMP%\duplist_report.txt"

if exist "%tmpList%"   del "%tmpList%"
if exist "%tmpDups%"   del "%tmpDups%"
if exist "%tmpReport%" del "%tmpReport%"

:: Write: SIZE|FILENAME|FULLPATH
for /r "!scanPath!" %%f in (*) do (
    if exist "%%f" (
        echo %%~zf^|%%~nxf^|%%f >> "%tmpList%" 2>nul
    )
)

if not exist "%tmpList%" (
    color 0C
    echo  [ERROR] Could not read folder or folder is empty.
    echo.
    pause
    goto MENU
)

:: Count total files
set "totalFiles=0"
for /f %%x in ('find /c /v "" ^< "%tmpList%" 2^>nul') do set "totalFiles=%%x"
echo  Found !totalFiles! files total. Checking for duplicates...
echo.

:: Find duplicates: any SIZE|NAME combo that appears more than once
set "dupCount=0"
set "lastKey="
set "lastPath="
set "inDup=0"

:: Sort the list so duplicates appear adjacent
sort "%tmpList%" > "%tmpDups%" 2>nul

set "prevKey="
set "prevPath="
set "dupGroupCount=0"

echo  ================================================================ >> "%tmpReport%"
echo    DUPLICATE FILE FINDER REPORT >> "%tmpReport%"
echo    Scanned : !scanPath! >> "%tmpReport%"
echo    Date    : %DATE% %TIME% >> "%tmpReport%"
echo  ================================================================ >> "%tmpReport%"
echo. >> "%tmpReport%"

for /f "tokens=1,2,3 delims=|" %%a in (%tmpDups%) do (
    set "curKey=%%a|%%b"
    set "curPath=%%c"
    set "curSize=%%a"
    set "curName=%%b"
    if "!curKey!"=="!prevKey!" (
        if !inDup!==0 (
            set /a dupGroupCount+=1
            set /a dupCount+=1
            echo  --- DUPLICATE GROUP #!dupGroupCount! --- >> "%tmpReport%"
            echo  Name : !curName! >> "%tmpReport%"
            set /a smb=curSize/1048576
            echo  Size : !smb! MB  (!curSize! bytes) >> "%tmpReport%"
            echo    Copy 1: !prevPath! >> "%tmpReport%"
            set "inDup=1"
        )
        set /a dupCount+=1
        echo    Copy !dupCount!: !curPath! >> "%tmpReport%"
    ) else (
        set "inDup=0"
        set "dupCount=0"
    )
    set "prevKey=!curKey!"
    set "prevPath=!curPath!"
)

echo. >> "%tmpReport%"
echo  ================================================================ >> "%tmpReport%"
echo    Total duplicate groups found: !dupGroupCount! >> "%tmpReport%"
echo  ================================================================ >> "%tmpReport%"

:: Display results
if !dupGroupCount!==0 (
    color 0A
    echo  [OK] No duplicate files found in:
    echo  !scanPath!
    echo.
    echo  All !totalFiles! files have unique names and sizes.
) else (
    color 0E
    echo  Found !dupGroupCount! group(s) of duplicate files.
    echo.
    echo  +------------------------------------------------------------+
    type "%tmpReport%"
    echo  +------------------------------------------------------------+
    echo.
    echo  IMPORTANT: Review each group above and manually delete
    echo  the copies you no longer need. This script will never
    echo  auto-delete files.
    echo.
    echo  Save report to Desktop? (Y/N)
    set /p saveOpt=  Choice: 
    if /i "!saveOpt!"=="Y" (
        copy "%tmpReport%" "%USERPROFILE%\Desktop\DuplicateFiles_Report.txt" >nul 2>&1
        echo  [OK] Report saved to Desktop as DuplicateFiles_Report.txt
    )
)
echo.
:: Cleanup temp files
if exist "%tmpList%"   del "%tmpList%" >nul 2>&1
if exist "%tmpDups%"   del "%tmpDups%" >nul 2>&1
if exist "%tmpReport%" del "%tmpReport%" >nul 2>&1
pause
goto MENU

:ABOUT
cls
color 09
echo.
echo  +================================================================+
echo  ^|  HOW DUPLICATE DETECTION WORKS                                ^|
echo  +================================================================+
echo.
echo  This script identifies duplicates by matching:
echo    1. File NAME  (exact match, case-insensitive)
echo    2. File SIZE  (exact byte count must be identical)
echo.
echo  Two files are flagged as duplicates only when BOTH the name
echo  and size are identical. This catches files like:
echo.
echo    photo.jpg  (4,521,234 bytes)  in C:\Downloads\
echo    photo.jpg  (4,521,234 bytes)  in C:\Desktop\
echo.
echo  Limitations:
echo  -------------
echo  - Files with the same content but DIFFERENT names are NOT detected
echo    (for content-based matching, use a dedicated tool like dupeGuru)
echo  - Very small files (under 1 KB) may produce false positives
echo    (e.g., multiple empty .txt files named "notes.txt")
echo.
echo  Recommended free tools for deep duplicate detection:
echo  -----------------------------------------------------
echo    dupeGuru        - https://dupeguru.voltaicideas.net/
echo    AllDup          - https://www.alldup.de/en_alldup.php
echo    WizFile         - Fast file scanner with dupe detection
echo.
pause
goto MENU

:EXIT
:: Clean up any leftover temp files
if exist "%TEMP%\duplist_all.txt"    del "%TEMP%\duplist_all.txt"    >nul 2>&1
if exist "%TEMP%\duplist_dups.txt"   del "%TEMP%\duplist_dups.txt"   >nul 2>&1
if exist "%TEMP%\duplist_report.txt" del "%TEMP%\duplist_report.txt" >nul 2>&1
exit