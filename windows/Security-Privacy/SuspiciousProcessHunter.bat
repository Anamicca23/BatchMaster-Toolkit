@echo off
:: ============================================================
:: Name      : SuspiciousProcessHunter.bat
:: Version   : 1.0.0
:: Author    : Anamicca23
:: Tested    : Windows 10 22H2, Windows 11 23H2
:: Min OS    : Windows 10 1803
:: Risk      : LOW
:: Admin     : Required
:: Reversible: Yes  (kill option requires confirmation)
:: Desc      : Scans all running processes and flags any
::             executing from Temp, AppData, Downloads, Desktop,
::             or other non-standard locations. Also flags
::             processes masquerading as system names from
::             wrong directories.
:: ============================================================
setlocal enabledelayedexpansion
title SUSPICIOUS PROCESS HUNTER v1.0.0
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
echo  ^|    S U S P I C I O U S   P R O C E S S   H U N T E R  v1.0.0 ^|
echo  ^|       Detect malware hiding in unexpected locations            ^|
echo  +================================================================+
echo  ^|                                                                ^|
echo  ^|   [1]  Full Process Scan  (all running processes)              ^|
echo  ^|   [2]  Quick Scan  (flag suspicious only)                      ^|
echo  ^|   [3]  Search for a Specific Process                           ^|
echo  ^|   [4]  Show All Running Processes                              ^|
echo  ^|   [5]  Kill a Process by PID                                   ^|
echo  ^|   [6]  Export Scan Report to Desktop                           ^|
echo  ^|   [7]  About — What is Flagged and Why                         ^|
echo  ^|   [0]  Exit                                                    ^|
echo  ^|                                                                ^|
echo  +================================================================+
echo.
set /p c=    Enter Option: 
if "%c%"=="1" goto FULLSCAN
if "%c%"=="2" goto QUICKSCAN
if "%c%"=="3" goto SEARCHPROC
if "%c%"=="4" goto SHOWALLPROC
if "%c%"=="5" goto KILLPID
if "%c%"=="6" goto EXPORTREPORT
if "%c%"=="7" goto ABOUT
if "%c%"=="0" goto EXIT
goto MENU

:: ── Flag subroutine ──────────────────────────────────────────────────────
:CHECKPROC
:: call :CHECKPROC "ProcessPath"
:: Sets _pflag=1 and _preason if suspicious
set "_pflag=0"
set "_preason="
set "_pp=%~1"
if "!_pp!"=="" exit /b
if "!_pp!"=="N/A" exit /b

:: Suspicious path patterns
echo !_pp! | findstr /i "\\Temp\\" >nul 2>&1
if not errorlevel 1 ( set "_pflag=1" & set "_preason=!_preason! [TEMP]" )

echo !_pp! | findstr /i "\\AppData\\Local\\Temp\\" >nul 2>&1
if not errorlevel 1 ( set "_pflag=1" & set "_preason=!_preason! [APPDATA TEMP]" )

echo !_pp! | findstr /i "\\AppData\\Roaming\\" >nul 2>&1
if not errorlevel 1 ( set "_pflag=1" & set "_preason=!_preason! [APPDATA ROAMING]" )

echo !_pp! | findstr /i "\\Downloads\\" >nul 2>&1
if not errorlevel 1 ( set "_pflag=1" & set "_preason=!_preason! [DOWNLOADS]" )

echo !_pp! | findstr /i "\\Desktop\\" >nul 2>&1
if not errorlevel 1 ( set "_pflag=1" & set "_preason=!_preason! [DESKTOP]" )

echo !_pp! | findstr /i "\\Public\\" >nul 2>&1
if not errorlevel 1 ( set "_pflag=1" & set "_preason=!_preason! [PUBLIC FOLDER]" )

:: Double extension detection
echo !_pp! | findstr /i "\.txt\.exe\|\.pdf\.exe\|\.doc\.exe\|\.jpg\.exe\|\.mp4\.exe" >nul 2>&1
if not errorlevel 1 ( set "_pflag=1" & set "_preason=!_preason! [DOUBLE EXT]" )

:: System impersonators running from wrong path
:: (legit svchost, lsass, etc. should ONLY run from System32)
for %%s in (svchost.exe lsass.exe winlogon.exe csrss.exe smss.exe services.exe) do (
    echo !_pp! | findstr /i "%%s" >nul 2>&1
    if not errorlevel 1 (
        echo !_pp! | findstr /i "System32\|SysWOW64" >nul 2>&1
        if errorlevel 1 (
            set "_pflag=1"
            set "_preason=!_preason! [SYSTEM IMPERSONATOR - wrong dir]"
        )
    )
)

exit /b

:FULLSCAN
cls
color 0C
echo.
echo  +================================================================+
echo  ^|  FULL PROCESS SCAN                                            ^|
echo  ^|  Scanning all running processes...                            ^|
echo  +================================================================+
echo.

set "suspCount=0"
set "totalCount=0"
set "tmpProc=%TEMP%\sph_procs.txt"
if exist "%tmpProc%" del "%tmpProc%"

wmic process get Name,ProcessId,ExecutablePath /value 2>nul > "%tmpProc%"

set "curName=" & set "curPID=" & set "curPath="

for /f "tokens=1* delims==" %%a in ('type "%tmpProc%" 2^>nul') do (
    set "k=%%a" & set "v=%%b"
    set "k=!k: =!"
    set "v=!v: =!"

    if /i "!k!"=="Name"           set "curName=!v!"
    if /i "!k!"=="ProcessId"      set "curPID=!v!"
    if /i "!k!"=="ExecutablePath" (
        set "curPath=!v!"
        if defined curName if defined curPID (
            set /a totalCount+=1
            call :CHECKPROC "!curPath!"
            if !_pflag!==1 (
                set /a suspCount+=1
                color 0C
                echo  +--------------------------------------------------------------+
                echo  [SUSPICIOUS] !curName!
                echo    PID    : !curPID!
                echo    Path   : !curPath!
                echo    Reason :!_preason!
                color 0A
                echo.
            )
        )
        set "curName=" & set "curPID=" & set "curPath="
    )
)

if exist "%tmpProc%" del "%tmpProc%" >nul 2>&1

echo  +================================================================+
color 0E
echo  Scan complete.  Total: !totalCount!   Suspicious: !suspCount!
echo.
if !suspCount! gtr 0 (
    color 0C
    echo  [!] !suspCount! suspicious process(es) found.
    echo  Review the flagged entries above.
    echo  Use Option [5] to kill a suspicious process by PID.
    echo.
    echo  IMPORTANT: Verify before killing. Some legitimate software
    echo  may run from AppData (e.g. Spotify, Discord, Slack).
    echo  Only kill processes you do not recognise.
) else (
    color 0B
    echo  [OK] No obviously suspicious processes detected.
)
echo.
pause
goto MENU

:QUICKSCAN
cls
color 0C
echo.
echo  Quick scan — showing ONLY suspicious processes:
echo.
set "suspCount=0"
set "tmpProc=%TEMP%\sph_quick.txt"
if exist "%tmpProc%" del "%tmpProc%"
wmic process get Name,ProcessId,ExecutablePath /value 2>nul > "%tmpProc%"

set "curName=" & set "curPID=" & set "curPath="
for /f "tokens=1* delims==" %%a in ('type "%tmpProc%" 2^>nul') do (
    set "k=%%a" & set "v=%%b"
    set "k=!k: =!" & set "v=!v: =!"
    if /i "!k!"=="Name"           set "curName=!v!"
    if /i "!k!"=="ProcessId"      set "curPID=!v!"
    if /i "!k!"=="ExecutablePath" (
        set "curPath=!v!"
        if defined curName if defined curPID (
            call :CHECKPROC "!curPath!"
            if !_pflag!==1 (
                set /a suspCount+=1
                echo  [!] !curName!  PID:!curPID!  !_preason!
                echo      !curPath!
                echo.
            )
        )
        set "curName=" & set "curPID=" & set "curPath="
    )
)
if exist "%tmpProc%" del "%tmpProc%" >nul 2>&1
if !suspCount!==0 (
    color 0B
    echo  [OK] No suspicious processes found.
) else (
    color 0C
    echo  !suspCount! suspicious process(es) flagged above.
)
echo.
pause
goto MENU

:SEARCHPROC
cls
color 09
echo.
echo  Enter process name to search for (partial match OK):
set /p srch=  Name: 
echo.
echo  +================================================================+
echo  Processes matching "!srch!":
echo  +----------------------------------------------------------------+
wmic process where "Name like '%!srch!%'" get Name,ProcessId,ExecutablePath /value 2>nul | findstr "="
echo.
pause
goto MENU

:SHOWALLPROC
cls
color 09
echo.
echo  +================================================================+
echo  ^|  ALL RUNNING PROCESSES                                        ^|
echo  +================================================================+
echo.
tasklist /fo table /nh 2>nul
echo.
pause
goto MENU

:KILLPID
cls
color 0C
echo.
echo  Enter the PID of the process to kill:
set /p kpid=  PID: 

set "kname=Unknown"
for /f "tokens=1 delims=," %%p in ('tasklist /fi "PID eq !kpid!" /fo csv /nh 2^>nul') do (
    set "kname=%%p" & set "kname=!kname:"=!"
)

echo.
echo  +------------------------------------------------------------+
echo  ^|  [WARNING] You are about to kill:                         ^|
echo  ^|  PID     : !kpid!
echo  ^|  Process : !kname!
echo  ^|  Unsaved work in this process will be lost.               ^|
echo  +------------------------------------------------------------+
echo.
set /p confirm=  Kill process !kpid! (!kname!)? (Y/N): 
if /i not "%confirm%"=="Y" ( echo  Cancelled. & pause & goto MENU )

taskkill /f /pid !kpid! >nul 2>&1
if !errorlevel!==0 (
    color 0B
    echo.
    echo  [DONE] Process !kpid! (!kname!) terminated.
) else (
    color 0C
    echo.
    echo  [ERROR] Could not kill PID !kpid!.
    echo  It may be a protected system process.
)
echo.
pause
goto MENU

:EXPORTREPORT
cls
color 09
echo.
echo  Generating process scan report...
set "rpt=%USERPROFILE%\Desktop\ProcessScan_Report.txt"
(
echo ================================================================
echo   SUSPICIOUS PROCESS HUNTER REPORT
echo   Generated : %DATE% %TIME%
echo   Computer  : %COMPUTERNAME%
echo ================================================================
echo.
echo [ALL PROCESSES WITH PATHS]
wmic process get Name,ProcessId,ExecutablePath /value
echo.
echo [PROCESSES FROM SUSPICIOUS LOCATIONS]
wmic process get Name,ProcessId,ExecutablePath /value | findstr /i "Temp\|Downloads\|Desktop\|AppData\\Roaming\|Public"
echo.
echo [TASKLIST SUMMARY]
tasklist /fo table
echo.
echo ================================================================
echo   END OF REPORT
echo ================================================================
) > "%rpt%" 2>nul
if exist "%rpt%" (
    color 0B
    echo  [OK] Report saved to Desktop as ProcessScan_Report.txt
) else (
    echo  [ERROR] Could not write report.
)
echo.
pause
goto MENU

:ABOUT
cls
color 09
echo.
echo  +================================================================+
echo  ^|  ABOUT — WHAT GETS FLAGGED AND WHY                           ^|
echo  +================================================================+
echo.
echo  This scanner flags processes running from locations that
echo  are NOT expected for legitimate software:
echo.
echo  [TEMP]            - %TEMP% and C:\Windows\Temp
echo    Malware often unpacks itself to Temp folders to avoid
echo    detection and auto-deletes after infection.
echo.
echo  [APPDATA TEMP]    - %LocalAppData%\Temp\
echo    Another common drop zone for malware loaders.
echo.
echo  [APPDATA ROAMING] - %AppData%\Roaming\
echo    Some malware installs itself here to persist between
echo    logins without admin rights.
echo.
echo  [DOWNLOADS]       - Any path containing \Downloads\
echo    Executables running from Downloads are unusual in
echo    normal operation and may indicate a user ran a dropper.
echo.
echo  [DESKTOP]         - Any process running from \Desktop\
echo    Typically only used briefly. Persistent processes
echo    running from here are suspicious.
echo.
echo  [DOUBLE EXT]      - Files like document.pdf.exe
echo    Classic social engineering trick. The file appears
echo    to be a PDF but is actually an executable.
echo.
echo  [SYSTEM IMPERSONATOR]
echo    Processes named svchost.exe, lsass.exe, winlogon.exe
echo    etc. that are NOT running from System32 or SysWOW64.
echo    Malware commonly uses these names to hide.
echo.
echo  IMPORTANT:
echo  ----------
echo  Some legitimate software DOES run from AppData\Roaming:
echo    Spotify, Discord, Slack, Teams, VS Code (user install)
echo  Always verify before killing flagged processes.
echo  Use Google or VirusTotal to look up unfamiliar process names.
echo.
pause
goto MENU

:EXIT
if exist "%TEMP%\sph_procs.txt" del "%TEMP%\sph_procs.txt" >nul 2>&1
if exist "%TEMP%\sph_quick.txt" del "%TEMP%\sph_quick.txt" >nul 2>&1
exit
