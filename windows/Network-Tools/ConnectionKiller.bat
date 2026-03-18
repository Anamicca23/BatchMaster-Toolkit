@echo off
:: ============================================================
:: Name      : ConnectionKiller.bat
:: Version   : 1.0.0
:: Author    : Anamicca23
:: Tested    : Windows 10 22H2, Windows 11 23H2
:: Min OS    : Windows 10 1803
:: Risk      : HIGH
:: Admin     : Required
:: Reversible: No  (killed connections cannot be auto-restored)
:: Desc      : Lists all established TCP connections with remote
::             IP, port, and process name. Select any connection
::             by number to immediately terminate its process.
::             Requires Y confirmation before kill.
:: ============================================================
setlocal enabledelayedexpansion
title CONNECTION KILLER v1.0.0
mode con: cols=80 lines=48
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
echo  ^|       C O N N E C T I O N   K I L L E R   v1.0.0             ^|
echo  ^|     View and terminate active network connections              ^|
echo  +================================================================+
echo  ^|                                                                ^|
echo  ^|   [1]  Show All Established Connections                        ^|
echo  ^|   [2]  Kill a Connection  (by PID)                             ^|
echo  ^|   [3]  Kill All Connections for a Process Name                 ^|
echo  ^|   [4]  Show Connections by Remote Country/IP                   ^|
echo  ^|   [5]  Block a Remote IP  (add to Windows Firewall)            ^|
echo  ^|   [6]  Refresh and Display Live Connection Count               ^|
echo  ^|   [0]  Exit                                                    ^|
echo  ^|                                                                ^|
echo  ^|  WARNING: Killing a connection terminates its process.         ^|
echo  ^|  Unsaved work in that process will be lost.                    ^|
echo  +================================================================+
echo.
set /p c=    Enter Option: 
if "%c%"=="1" goto SHOWCONN
if "%c%"=="2" goto KILLBYPID
if "%c%"=="3" goto KILLBYNAME
if "%c%"=="4" goto SHOWBYIP
if "%c%"=="5" goto BLOCKIP
if "%c%"=="6" goto LIVECOUNT
if "%c%"=="0" goto EXIT
goto MENU

:SHOWCONN
cls
color 0E
echo.
echo  +================================================================+
echo  ^|  ESTABLISHED TCP CONNECTIONS                                  ^|
echo  +================================================================+
echo.
echo  #    PID      Process              Local Port   Remote Address
echo  ----------------------------------------------------------------

set "idx=0"
for /f "skip=4 tokens=2,3,5" %%a in ('netstat -ano 2^>nul ^| findstr "ESTABLISHED"') do (
    set "local=%%a"
    set "remote=%%b"
    set "pid=%%c"
    set "pid=!pid: =!"

    set "pname=Unknown"
    for /f "tokens=1 delims=," %%p in ('tasklist /fi "PID eq !pid!" /fo csv /nh 2^>nul') do (
        set "pname=%%p" & set "pname=!pname:"=!"
    )

    :: Extract local port
    for /f "tokens=2 delims=:" %%x in ("!local!") do set "lport=%%x"

    set /a idx+=1
    call :PAD "!idx!"    5  & set "n=!_P!"
    call :PAD "!pid!"    9  & set "p=!_P!"
    call :PAD "!pname!"  21 & set "pr=!_P!"
    call :PAD "!lport!"  13 & set "lp=!_P!"
    echo   !n!!p!!pr!!lp!!remote!
)

if !idx!==0 (
    color 0A
    echo  No established connections found.
) else (
    echo.
    echo  Total connections: !idx!
)
echo.
pause
goto MENU

:KILLBYPID
cls
color 0C
echo.
echo  Current established connections:
echo  +------------------------------------------------------------+
set "idx=0"
for /f "skip=4 tokens=2,3,5" %%a in ('netstat -ano 2^>nul ^| findstr "ESTABLISHED"') do (
    set "remote=%%b" & set "pid=%%c" & set "pid=!pid: =!"
    set "pname=Unknown"
    for /f "tokens=1 delims=," %%p in ('tasklist /fi "PID eq !pid!" /fo csv /nh 2^>nul') do (
        set "pname=%%p" & set "pname=!pname:"=!"
    )
    set /a idx+=1
    echo   [!idx!]  PID: !pid!   Process: !pname!   Remote: !remote!
)

if !idx!==0 (
    color 0A
    echo  No connections to kill.
    pause
    goto MENU
)
echo  +------------------------------------------------------------+
echo.
echo  Enter the PID to kill (from the list above):
set /p killPID=  PID: 

:: Verify PID exists
tasklist /fi "PID eq !killPID!" 2>nul | findstr /i "!killPID!" >nul 2>&1
if errorlevel 1 (
    color 0C
    echo.
    echo  [ERROR] PID !killPID! not found in running processes.
    pause
    goto MENU
)

:: Get process name for confirmation
set "killName=Unknown"
for /f "tokens=1 delims=," %%p in ('tasklist /fi "PID eq !killPID!" /fo csv /nh 2^>nul') do (
    set "killName=%%p" & set "killName=!killName:"=!"
)

echo.
echo  +------------------------------------------------------------+
echo  ^|  [WARNING] You are about to kill:                         ^|
echo  ^|  PID     : !killPID!
echo  ^|  Process : !killName!
echo  ^|
echo  ^|  This will close the process AND all its connections.     ^|
echo  ^|  Any unsaved work in that process will be LOST.           ^|
echo  +------------------------------------------------------------+
echo.
set /p confirm=  Kill process !killPID! (!killName!)? (Y/N): 
if /i not "%confirm%"=="Y" ( echo  Cancelled. & pause & goto MENU )

taskkill /f /pid !killPID! >nul 2>&1
if !errorlevel!==0 (
    color 0B
    echo.
    echo  [DONE] Process !killPID! (!killName!) has been terminated.
) else (
    color 0C
    echo.
    echo  [ERROR] Could not kill PID !killPID!. It may require SYSTEM privileges.
)
echo.
pause
goto MENU

:KILLBYNAME
cls
color 0C
echo.
echo  Enter process name to kill all its connections:
echo  Examples: chrome   firefox   python   java
echo.
set /p killName=  Process name: 

:: Check if process is running
tasklist 2>nul | findstr /i "!killName!" >nul 2>&1
if errorlevel 1 (
    echo.
    echo  [NOT FOUND] No running process named "!killName!" found.
    pause
    goto MENU
)

echo.
echo  +------------------------------------------------------------+
echo  ^|  [WARNING] All instances of "!killName!" will be killed.  ^|
echo  ^|  Any unsaved work will be LOST.                           ^|
echo  +------------------------------------------------------------+
echo.
set /p confirm=  Kill all "!killName!" processes? (Y/N): 
if /i not "%confirm%"=="Y" ( echo  Cancelled. & pause & goto MENU )

taskkill /f /im "!killName!.exe" >nul 2>&1
if !errorlevel!==0 (
    color 0B
    echo.
    echo  [DONE] All "!killName!" processes terminated.
) else (
    color 0C
    echo.
    echo  [ERROR] Could not terminate "!killName!". Try running as SYSTEM.
)
echo.
pause
goto MENU

:SHOWBYIP
cls
color 09
echo.
echo  +================================================================+
echo  ^|  CONNECTIONS BY REMOTE IP                                    ^|
echo  +================================================================+
echo.
echo  Remote IP               Count   Process
echo  ----------------------------------------------------------------
set "tmpIP=%TEMP%\ck_ips.txt"
if exist "%tmpIP%" del "%tmpIP%"

for /f "skip=4 tokens=3,5" %%a in ('netstat -ano 2^>nul ^| findstr "ESTABLISHED"') do (
    set "remote=%%a"
    set "pid=%%b" & set "pid=!pid: =!"
    :: Extract just the IP (strip port)
    for /f "tokens=1 delims=:" %%i in ("!remote!") do (
        echo %%i >> "%tmpIP%"
    )
)

:: Count occurrences per IP
if exist "%tmpIP%" (
    for /f "tokens=1*" %%a in ('sort "%tmpIP%" ^| uniq -c 2^>nul') do (
        echo  %%b   Count: %%a
    )
    del "%tmpIP%" >nul 2>&1
)

echo.
echo  Note: High connection counts to a single IP may indicate
echo  streaming, download, or suspicious background traffic.
echo.
pause
goto MENU

:BLOCKIP
cls
color 0C
echo.
echo  Enter the remote IP address to block in Windows Firewall:
set /p blockIP=  IP Address: 

:: Basic IP format validation
echo !blockIP! | findstr /r "[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*" >nul 2>&1
if errorlevel 1 (
    echo.
    echo  [ERROR] Invalid IP address format. Example: 123.45.67.89
    pause
    goto MENU
)

echo.
echo  +------------------------------------------------------------+
echo  ^|  [WARNING] This will add a Windows Firewall rule to       ^|
echo  ^|  BLOCK all traffic to/from: !blockIP!
echo  ^|
echo  ^|  To undo: Open Windows Firewall ^> Outbound Rules          ^|
echo  ^|  and delete the rule named "Block_!blockIP!"               ^|
echo  +------------------------------------------------------------+
echo.
set /p confirm=  Block IP !blockIP!? (Y/N): 
if /i not "%confirm%"=="Y" ( echo  Cancelled. & pause & goto MENU )

netsh advfirewall firewall add rule name="Block_!blockIP!" dir=out action=block remoteip=!blockIP! >nul 2>&1
netsh advfirewall firewall add rule name="Block_!blockIP!" dir=in  action=block remoteip=!blockIP! >nul 2>&1

color 0B
echo.
echo  [DONE] Firewall rules added to block !blockIP!
echo.
echo  To remove the block later, run:
echo  netsh advfirewall firewall delete rule name="Block_!blockIP!"
echo.
pause
goto MENU

:LIVECOUNT
cls
color 09
:LIVELOOP
cls
color 09
echo  +================================================================+
echo  ^|   LIVE CONNECTION COUNT  (CTRL+C to stop)
echo  ^|   Time: %TIME%
echo  +================================================================+
echo.
set "cnt=0"
for /f "skip=4" %%a in ('netstat -ano 2^>nul ^| findstr "ESTABLISHED"') do set /a cnt+=1
echo  Established connections : !cnt!
echo.
netstat -ano | findstr "ESTABLISHED"
timeout /t 5 >nul
goto LIVELOOP

:PAD
set "_P=%~1                                        "
set "_P=!_P:~0,%~2!"
exit /b

:EXIT
exit
