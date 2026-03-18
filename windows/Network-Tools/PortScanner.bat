@echo off
:: ============================================================
:: Name      : PortScanner.bat
:: Version   : 1.0.0
:: Author    : Anamicca23
:: Tested    : Windows 10 22H2, Windows 11 23H2
:: Min OS    : Windows 10 1803
:: Risk      : LOW
:: Admin     : Not Required
:: Reversible: Yes  (read-only scan, no changes made)
:: Desc      : Scans localhost for open TCP/UDP ports using
::             netstat. Maps each open port to its owning
::             process name and PID. No external tools needed.
:: ============================================================
setlocal enabledelayedexpansion
title PORT SCANNER v1.0.0
mode con: cols=80 lines=48
if not "%1"=="RUN" start /MAX cmd /k "%~f0" RUN & exit

:MENU
cls
color 09
echo.
echo  +================================================================+
echo  ^|            P O R T   S C A N N E R   v1.0.0                  ^|
echo  ^|        See what is listening on your machine                  ^|
echo  +================================================================+
echo  ^|                                                                ^|
echo  ^|   [1]  Show All Listening Ports  (TCP + UDP)                  ^|
echo  ^|   [2]  Show TCP Listening Ports Only                          ^|
echo  ^|   [3]  Show UDP Listening Ports Only                          ^|
echo  ^|   [4]  Show All Established Connections                       ^|
echo  ^|   [5]  Check a Specific Port                                  ^|
echo  ^|   [6]  Show Ports by Process Name                             ^|
echo  ^|   [7]  Export Port Report to Desktop                          ^|
echo  ^|   [8]  Common Ports Reference                                 ^|
echo  ^|   [0]  Exit                                                   ^|
echo  ^|                                                                ^|
echo  +================================================================+
echo.
set /p c=    Enter Option: 
if "%c%"=="1" goto ALLPORTS
if "%c%"=="2" goto TCPPORTS
if "%c%"=="3" goto UDPPORTS
if "%c%"=="4" goto ESTABLISHED
if "%c%"=="5" goto CHECKPORT
if "%c%"=="6" goto BYPROCESS
if "%c%"=="7" goto EXPORTREPORT
if "%c%"=="8" goto REFERENCE
if "%c%"=="0" goto EXIT
goto MENU

:ALLPORTS
cls
color 09
echo.
echo  +================================================================+
echo  ^|  ALL LISTENING PORTS  (TCP + UDP)                             ^|
echo  +================================================================+
echo.
echo  Proto   Local Address           PID     Process Name
echo  ----------------------------------------------------------------
for /f "skip=4 tokens=1,2,5" %%a in ('netstat -ano 2^>nul ^| findstr "LISTENING"') do (
    set "proto=%%a"
    set "addr=%%b"
    set "pid=%%c"
    set "procName=Unknown"
    for /f "tokens=1 delims=," %%p in ('tasklist /fi "PID eq !pid!" /fo csv /nh 2^>nul') do (
        set "procName=%%p"
        set "procName=!procName:"=!"
    )
    call :PAD "!proto!" 8   & set "c1=!_P!"
    call :PAD "!addr!"  22  & set "c2=!_P!"
    call :PAD "!pid!"   8   & set "c3=!_P!"
    echo   !c1!!c2!!c3!!procName!
)
echo.
echo  Tip: Run as Administrator to see process names for all ports.
echo.
pause
goto MENU

:TCPPORTS
cls
color 0B
echo.
echo  +================================================================+
echo  ^|  TCP LISTENING PORTS                                          ^|
echo  +================================================================+
echo.
echo  Port     Local Address              PID     Process
echo  ----------------------------------------------------------------
for /f "skip=4 tokens=1,2,5" %%a in ('netstat -ano 2^>nul ^| findstr "TCP.*LISTENING"') do (
    set "addr=%%b"
    set "pid=%%c"
    :: Extract just the port number from address
    for /f "tokens=2 delims=:" %%p in ("!addr!") do set "port=%%p"
    set "procName=Unknown"
    for /f "tokens=1 delims=," %%p in ('tasklist /fi "PID eq !pid!" /fo csv /nh 2^>nul') do (
        set "procName=%%p" & set "procName=!procName:"=!"
    )
    call :PAD "!port!"  8  & set "c1=!_P!"
    call :PAD "!addr!"  26 & set "c2=!_P!"
    call :PAD "!pid!"   8  & set "c3=!_P!"
    echo   !c1!!c2!!c3!!procName!
)
echo.
pause
goto MENU

:UDPPORTS
cls
color 0D
echo.
echo  +================================================================+
echo  ^|  UDP LISTENING PORTS                                          ^|
echo  +================================================================+
echo.
netstat -ano | findstr "UDP"
echo.
pause
goto MENU

:ESTABLISHED
cls
color 0E
echo.
echo  +================================================================+
echo  ^|  ESTABLISHED TCP CONNECTIONS                                  ^|
echo  +================================================================+
echo.
echo  Proto   Local Address           Remote Address          PID
echo  ----------------------------------------------------------------
for /f "skip=4 tokens=1,2,3,5" %%a in ('netstat -ano 2^>nul ^| findstr "ESTABLISHED"') do (
    set "proto=%%a" & set "local=%%b" & set "remote=%%c" & set "pid=%%d"
    set "procName=Unknown"
    for /f "tokens=1 delims=," %%p in ('tasklist /fi "PID eq !pid!" /fo csv /nh 2^>nul') do (
        set "procName=%%p" & set "procName=!procName:"=!"
    )
    call :PAD "!proto!"  8  & set "c1=!_P!"
    call :PAD "!local!"  22 & set "c2=!_P!"
    call :PAD "!remote!" 24 & set "c3=!_P!"
    echo   !c1!!c2!!c3!!pid!  !procName!
)
echo.
pause
goto MENU

:CHECKPORT
cls
color 09
echo.
echo  Enter port number to check (e.g. 80  443  8080  3389):
set /p portNum=  Port: 
echo.
echo  +------------------------------------------------------------+
echo  Checking port !portNum!...
echo  +------------------------------------------------------------+
echo.

:: Check if it appears in netstat
netstat -ano | findstr ":!portNum! "
if errorlevel 1 (
    echo  Port !portNum! does not appear to be in use on this machine.
) else (
    echo.
    :: Try to identify the process
    for /f "tokens=5" %%p in ('netstat -ano 2^>nul ^| findstr ":!portNum! "') do (
        set "pid=%%p"
        echo  Owned by PID: !pid!
        tasklist /fi "PID eq !pid!" 2>nul | findstr /v "^$" | findstr /v "======" | findstr /v "Image"
    )
)

echo.
echo  Well-known service on port !portNum!:
call :PORTLOOKUP !portNum!
echo.
pause
goto MENU

:PORTLOOKUP
set "knownPort=%~1"
if "%knownPort%"=="21"   echo  FTP (File Transfer Protocol)
if "%knownPort%"=="22"   echo  SSH (Secure Shell)
if "%knownPort%"=="23"   echo  Telnet
if "%knownPort%"=="25"   echo  SMTP (Email sending)
if "%knownPort%"=="53"   echo  DNS (Domain Name System)
if "%knownPort%"=="80"   echo  HTTP (Web traffic)
if "%knownPort%"=="110"  echo  POP3 (Email receiving)
if "%knownPort%"=="135"  echo  Windows RPC
if "%knownPort%"=="139"  echo  NetBIOS
if "%knownPort%"=="143"  echo  IMAP (Email)
if "%knownPort%"=="443"  echo  HTTPS (Secure web traffic)
if "%knownPort%"=="445"  echo  SMB (Windows file sharing)
if "%knownPort%"=="3306" echo  MySQL database
if "%knownPort%"=="3389" echo  RDP (Remote Desktop Protocol)
if "%knownPort%"=="5432" echo  PostgreSQL database
if "%knownPort%"=="5900" echo  VNC (Remote desktop)
if "%knownPort%"=="8080" echo  HTTP alternate / dev server
if "%knownPort%"=="8443" echo  HTTPS alternate
exit /b

:BYPROCESS
cls
color 09
echo.
echo  Enter process name to find its ports (e.g. chrome  svchost  python):
set /p procSearch=  Process: 
echo.
echo  +------------------------------------------------------------+
echo  Ports used by processes matching: !procSearch!
echo  +------------------------------------------------------------+
echo.

set "foundAny=0"
for /f "skip=4 tokens=1,2,5" %%a in ('netstat -ano 2^>nul') do (
    set "proto=%%a" & set "addr=%%b" & set "pid=%%c"
    for /f "tokens=1 delims=," %%p in ('tasklist /fi "PID eq !pid!" /fo csv /nh 2^>nul') do (
        set "pname=%%p" & set "pname=!pname:"=!"
        echo !pname! | findstr /i "!procSearch!" >nul 2>&1
        if !errorlevel!==0 (
            echo  PID !pid!  !proto!  !addr!  [!pname!]
            set "foundAny=1"
        )
    )
)
if !foundAny!==0 echo  No ports found for process "!procSearch!".
echo.
pause
goto MENU

:EXPORTREPORT
cls
color 0B
echo.
echo  Exporting port report to Desktop...
set "rpt=%USERPROFILE%\Desktop\PortScan_Report.txt"
(
echo ================================================================
echo   PORT SCANNER REPORT
echo   Generated : %DATE% %TIME%
echo   Computer  : %COMPUTERNAME%
echo ================================================================
echo.
echo [ALL LISTENING PORTS]
netstat -ano | findstr "LISTENING"
echo.
echo [ESTABLISHED CONNECTIONS]
netstat -ano | findstr "ESTABLISHED"
echo.
echo [FULL NETSTAT OUTPUT]
netstat -ano
echo.
echo ================================================================
echo   END OF REPORT
echo ================================================================
) > "%rpt%" 2>nul
if exist "%rpt%" (
    echo  [OK] Report saved to Desktop as PortScan_Report.txt
) else (
    echo  [ERROR] Could not write report.
)
echo.
pause
goto MENU

:REFERENCE
cls
color 09
echo.
echo  +================================================================+
echo  ^|  COMMON PORTS QUICK REFERENCE                                ^|
echo  +================================================================+
echo.
echo   PORT    PROTOCOL    SERVICE
echo   -----------------------------------------------
echo    20/21   TCP         FTP  (File Transfer)
echo    22      TCP         SSH  (Secure Shell)
echo    23      TCP         Telnet (insecure, avoid)
echo    25      TCP         SMTP (Send email)
echo    53      TCP/UDP     DNS  (Domain Name System)
echo    67/68   UDP         DHCP (IP addressing)
echo    80      TCP         HTTP (Web)
echo    110     TCP         POP3 (Receive email)
echo    135     TCP         Windows RPC
echo    139/445 TCP         SMB  (File sharing)
echo    143     TCP         IMAP (Email)
echo    443     TCP         HTTPS (Secure web)
echo    3306    TCP         MySQL
echo    3389    TCP         RDP  (Remote Desktop)
echo    5432    TCP         PostgreSQL
echo    5900    TCP         VNC  (Remote desktop)
echo    8080    TCP         HTTP alternate / dev
echo    8443    TCP         HTTPS alternate
echo    27017   TCP         MongoDB
echo.
echo  Ports below 1024 are well-known (system) ports.
echo  Ports 1024-49151 are registered application ports.
echo  Ports 49152-65535 are dynamic/ephemeral ports.
echo.
pause
goto MENU

:PAD
set "_P=%~1                                        "
set "_P=!_P:~0,%~2!"
exit /b

:EXIT
exit
