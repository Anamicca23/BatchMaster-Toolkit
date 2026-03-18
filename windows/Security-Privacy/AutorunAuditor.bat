@echo off
:: ============================================================
:: Name      : AutorunAuditor.bat
:: Version   : 1.0.0
:: Author    : Anamicca23
:: Tested    : Windows 10 22H2, Windows 11 23H2
:: Min OS    : Windows 10 1803
:: Risk      : LOW
:: Admin     : Required
:: Reversible: Yes  (read-only by default; disable option
::             moves entry to RunOnce which is reversible)
:: Desc      : Scans 12 registry autorun keys and all startup
::             folders. Flags entries pointing to Temp, Downloads,
::             AppData, or paths that no longer exist.
:: ============================================================
setlocal enabledelayedexpansion
title AUTORUN AUDITOR v1.0.0
mode con: cols=80 lines=50
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
color 0C
echo.
echo  +================================================================+
echo  ^|         A U T O R U N   A U D I T O R   v1.0.0               ^|
echo  ^|     Scan all autorun locations for suspicious entries          ^|
echo  +================================================================+
echo  ^|                                                                ^|
echo  ^|   [1]  Full Autorun Scan  (all locations + flags)              ^|
echo  ^|   [2]  Scan Registry Keys Only                                 ^|
echo  ^|   [3]  Scan Startup Folders Only                               ^|
echo  ^|   [4]  Scan Scheduled Tasks  (boot/logon triggers)             ^|
echo  ^|   [5]  Disable a Specific Registry Entry                       ^|
echo  ^|   [6]  Export Full Report to Desktop                           ^|
echo  ^|   [0]  Exit                                                    ^|
echo  ^|                                                                ^|
echo  +================================================================+
echo.
set /p c=    Enter Option: 
if "%c%"=="1" goto FULLSCAN
if "%c%"=="2" goto REGSCAN
if "%c%"=="3" goto FOLDERSCAN
if "%c%"=="4" goto TASKSCAN
if "%c%"=="5" goto DISABLEENTRY
if "%c%"=="6" goto EXPORTREPORT
if "%c%"=="0" goto EXIT
goto MENU

:: ── Core flag subroutine ────────────────────────────────────────────────
:CHECKENTRY
:: call :CHECKENTRY "EntryName" "EntryValue"
:: Sets _flag and _reason
set "_flag=0"
set "_reason="
set "_entryVal=%~2"

:: Check if path exists (skip if it's a system command like rundll32)
echo !_entryVal! | findstr /i "\.exe\|\.bat\|\.cmd\|\.vbs\|\.ps1" >nul 2>&1
if not errorlevel 1 (
    :: Extract executable path (first quoted or unquoted token)
    set "_testPath=!_entryVal!"
    if "!_testPath:~0,1!"==^"^" (
        for /f "tokens=1 delims=" %%p in ("!_testPath!") do (
            set "_testPath=%%~p"
        )
    ) else (
        for /f "tokens=1" %%p in ("!_testPath!") do set "_testPath=%%p"
    )

    if not exist "!_testPath!" (
        if not "!_testPath!"=="" (
            set "_flag=1"
            set "_reason=[MISSING PATH]"
        )
    )
)

:: Check for suspicious locations
echo !_entryVal! | findstr /i "\\Temp\\\|\\tmp\\\|/temp/" >nul 2>&1
if not errorlevel 1 ( set "_flag=1" & set "_reason=!_reason! [TEMP DIRECTORY]" )

echo !_entryVal! | findstr /i "\\Downloads\\" >nul 2>&1
if not errorlevel 1 ( set "_flag=1" & set "_reason=!_reason! [DOWNLOADS]" )

echo !_entryVal! | findstr /i "\\AppData\\Local\\Temp\\" >nul 2>&1
if not errorlevel 1 ( set "_flag=1" & set "_reason=!_reason! [APPDATA TEMP]" )

echo !_entryVal! | findstr /i "\\Desktop\\" >nul 2>&1
if not errorlevel 1 ( set "_flag=1" & set "_reason=!_reason! [DESKTOP LAUNCH]" )

:: Check for double extensions (malware trick)
echo !_entryVal! | findstr /i "\.txt\.exe\|\.pdf\.exe\|\.doc\.exe\|\.jpg\.exe" >nul 2>&1
if not errorlevel 1 ( set "_flag=1" & set "_reason=!_reason! [DOUBLE EXTENSION]" )

exit /b

:FULLSCAN
cls
color 0C
echo.
echo  +================================================================+
echo  ^|  FULL AUTORUN SCAN                                            ^|
echo  +================================================================+
echo.
set "suspCount=0"
set "totalCount=0"

echo  ── REGISTRY: HKCU\Run ──────────────────────────────────────────
call :SCANKEY "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"

echo.
echo  ── REGISTRY: HKLM\Run ──────────────────────────────────────────
call :SCANKEY "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"

echo.
echo  ── REGISTRY: HKLM\Run (WOW6432) ───────────────────────────────
call :SCANKEY "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"

echo.
echo  ── REGISTRY: HKCU\RunOnce ──────────────────────────────────────
call :SCANKEY "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"

echo.
echo  ── REGISTRY: HKLM\RunOnce ──────────────────────────────────────
call :SCANKEY "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"

echo.
echo  ── STARTUP FOLDER: Current User ────────────────────────────────
call :SCANFOLDER "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"

echo.
echo  ── STARTUP FOLDER: All Users ───────────────────────────────────
call :SCANFOLDER "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"

echo.
echo  +================================================================+
color 0E
echo  Scan complete. Total entries: !totalCount!   Suspicious: !suspCount!
if !suspCount! gtr 0 (
    echo.
    echo  [!] !suspCount! suspicious entry(ies) detected.
    echo  Review the flagged entries above.
    echo  Use Option [5] to disable any suspicious registry entry.
) else (
    color 0B
    echo  [OK] No suspicious autorun entries found.
)
echo.
pause
goto MENU

:SCANKEY
:: call :SCANKEY "REGKEY"
set "_key=%~1"
for /f "tokens=1,2*" %%a in ('reg query "!_key!" /ve /s 2^>nul ^| findstr /v "^HKEY\|^$\|(Default)"') do (
    set "_name=%%a"
    set "_val=%%c"
    set /a totalCount+=1
    call :CHECKENTRY "!_name!" "!_val!"
    if !_flag!==1 (
        color 0C
        echo  [SUSPICIOUS] !_name!
        echo    Value   : !_val!
        echo    Reason  : !_reason!
        echo    Key     : !_key!
        color 0A
        set /a suspCount+=1
    ) else (
        echo  [OK] !_name!
        echo    Value : !_val!
    )
    echo.
)
exit /b

:SCANFOLDER
:: call :SCANFOLDER "FolderPath"
set "_folder=%~1"
if not exist "!_folder!" (
    echo  Folder not found: !_folder!
    exit /b
)
for %%f in ("!_folder!\*") do (
    if not "%%~nxf"=="desktop.ini" (
        set /a totalCount+=1
        call :CHECKENTRY "%%~nxf" "%%f"
        if !_flag!==1 (
            color 0C
            echo  [SUSPICIOUS] %%~nxf
            echo    Path   : %%f
            echo    Reason : !_reason!
            color 0A
            set /a suspCount+=1
        ) else (
            echo  [OK] %%~nxf  ^(%%f^)
        )
    )
)
exit /b

:REGSCAN
cls
color 09
echo.
echo  +================================================================+
echo  ^|  REGISTRY AUTORUN SCAN                                        ^|
echo  +================================================================+
echo.
set "suspCount=0" & set "totalCount=0"
for %%k in (
    "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"
    "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
    "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
) do (
    echo  Key: %%~k
    echo  ---------------------------------------------------------
    reg query %%k 2>nul | findstr /v "^HKEY\|^$"
    echo.
)
pause
goto MENU

:FOLDERSCAN
cls
color 09
echo.
echo  +================================================================+
echo  ^|  STARTUP FOLDER SCAN                                          ^|
echo  +================================================================+
echo.
echo  Current User startup folder:
echo  %APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup
echo  ---------------------------------------------------------
dir /b "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup" 2>nul
echo.
echo  All Users startup folder:
echo  C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup
echo  ---------------------------------------------------------
dir /b "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup" 2>nul
echo.
pause
goto MENU

:TASKSCAN
cls
color 09
echo.
echo  +================================================================+
echo  ^|  SCHEDULED TASKS WITH BOOT OR LOGON TRIGGERS                 ^|
echo  +================================================================+
echo.
schtasks /query /fo list 2>nul | findstr /i "TaskName:\|Trigger:\|Task To Run:\|Status:"
echo.
echo  Tip: Use Task Scheduler (taskschd.msc) to inspect any
echo  unfamiliar tasks, especially those triggered at boot/logon.
echo.
pause
goto MENU

:DISABLEENTRY
cls
color 0C
echo.
echo  Enter the REGISTRY KEY containing the entry to disable:
echo  Example: HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run
echo.
set /p delKey=  Registry Key: 
echo.
echo  Enter the VALUE NAME of the entry to disable:
echo  (This is the name shown in the scan, e.g. OneDrive)
echo.
set /p delName=  Value Name: 

:: Verify it exists
reg query "!delKey!" /v "!delName!" >nul 2>&1
if errorlevel 1 (
    color 0C
    echo.
    echo  [ERROR] Entry "!delName!" not found in !delKey!
    pause
    goto MENU
)

:: Show current value before deleting
echo.
echo  Current value:
reg query "!delKey!" /v "!delName!" 2>nul
echo.
echo  +------------------------------------------------------------+
echo  ^|  [WARNING] This will DELETE the registry entry:           ^|
echo  ^|  Key   : !delKey!
echo  ^|  Value : !delName!
echo  ^|
echo  ^|  The program will no longer start at login.                ^|
echo  ^|  The program itself will NOT be uninstalled.               ^|
echo  +------------------------------------------------------------+
echo.
set /p confirm=  Delete this autorun entry? (Y/N): 
if /i not "%confirm%"=="Y" ( echo  Cancelled. & pause & goto MENU )

reg delete "!delKey!" /v "!delName!" /f >nul 2>&1
if !errorlevel!==0 (
    color 0B
    echo.
    echo  [DONE] Autorun entry "!delName!" has been removed.
    echo  The program will no longer launch at startup.
) else (
    color 0C
    echo.
    echo  [ERROR] Could not delete the entry. Check key path and name.
)
echo.
pause
goto MENU

:EXPORTREPORT
cls
color 09
echo.
echo  Generating autorun audit report...
set "rpt=%USERPROFILE%\Desktop\AutorunAudit_Report.txt"
(
echo ================================================================
echo   AUTORUN AUDITOR REPORT
echo   Generated : %DATE% %TIME%
echo   Computer  : %COMPUTERNAME%
echo ================================================================
echo.
echo [HKCU Run]
reg query "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" 2>nul
echo.
echo [HKLM Run]
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" 2>nul
echo.
echo [HKLM Run WOW6432]
reg query "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run" 2>nul
echo.
echo [HKCU RunOnce]
reg query "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" 2>nul
echo.
echo [HKLM RunOnce]
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" 2>nul
echo.
echo [Startup Folder - Current User]
dir /b "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup" 2>nul
echo.
echo [Startup Folder - All Users]
dir /b "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup" 2>nul
echo.
echo [Scheduled Tasks]
schtasks /query /fo list 2>nul
echo.
echo ================================================================
echo   END OF REPORT
echo ================================================================
) > "%rpt%" 2>nul

if exist "%rpt%" (
    color 0B
    echo  [OK] Report saved to Desktop as AutorunAudit_Report.txt
) else (
    echo  [ERROR] Could not write report.
)
echo.
pause
goto MENU

:EXIT
exit
