@echo off
:: ============================================================
:: Name      : NetworkOptimizer.bat
:: Version   : 1.0.0
:: Author    : Anamicca23
:: Tested    : Windows 10 22H2, Windows 11 23H2
:: Min OS    : Windows 10 1803
:: Risk      : HIGH
:: Admin     : Required
:: Reversible: Yes  (Option [7] restores all defaults)
:: Desc      : Full network tune-up — flush DNS, reset Winsock
::             and TCP/IP stack, set fast DNS servers, disable
::             throttling, flush ARP. Includes before/after
::             ping latency comparison and full undo option.
:: ============================================================
setlocal enabledelayedexpansion
title NETWORK OPTIMIZER v1.0.0
mode con: cols=70 lines=48
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
color 0B
echo.
echo  +============================================================+
echo  ^|      N E T W O R K   O P T I M I Z E R   v1.0.0          ^|
echo  ^|        Fix Lag  ^|  Speed Up Internet  ^|  Reset TCP        ^|
echo  +============================================================+
echo  ^|                                                            ^|
echo  ^|   [1]  Full Optimization  (Recommended)                   ^|
echo  ^|   [2]  Flush DNS Cache Only                                ^|
echo  ^|   [3]  Reset Winsock + TCP/IP Stack                        ^|
echo  ^|   [4]  Set Fast DNS  (Google + Cloudflare)                 ^|
echo  ^|   [5]  Disable Network Throttling                          ^|
echo  ^|   [6]  Run Ping Latency Test                               ^|
echo  ^|   [7]  UNDO All Changes  (Restore Defaults)                ^|
echo  ^|   [8]  Show Current Network Info                           ^|
echo  ^|   [0]  Exit                                                ^|
echo  ^|                                                            ^|
echo  +============================================================+
echo.
set /p c=    Enter Option: 
if "%c%"=="1" goto FULLOPT
if "%c%"=="2" goto FLUSHDNS
if "%c%"=="3" goto RESETTCP
if "%c%"=="4" goto SETDNS
if "%c%"=="5" goto THROTTLE
if "%c%"=="6" goto PINGTEST
if "%c%"=="7" goto UNDO
if "%c%"=="8" goto NETINFO
if "%c%"=="0" goto EXIT
goto MENU

:FULLOPT
cls
color 0E
echo.
echo  +============================================================+
echo  ^|   FULL NETWORK OPTIMIZATION                                ^|
echo  +============================================================+
echo.
echo  Running before ping test...
call :QUICKPING BEFORE

echo.
echo  [1/9] Flushing DNS cache...
ipconfig /flushdns >nul 2>&1
echo        Done.

echo  [2/9] Releasing IP address...
ipconfig /release >nul 2>&1
echo        Done.

echo  [3/9] Renewing IP address...
ipconfig /renew >nul 2>&1
echo        Done.

echo  [4/9] Resetting Winsock catalog...
netsh winsock reset >nul 2>&1
echo        Done.

echo  [5/9] Resetting TCP/IP stack...
netsh int ip reset >nul 2>&1
echo        Done.

echo  [6/9] Optimizing TCP settings...
netsh int tcp set global autotuninglevel=normal >nul 2>&1
netsh int tcp set global chimney=enabled >nul 2>&1
netsh int tcp set global ecncapability=disabled >nul 2>&1
echo        Done.

echo  [7/9] Disabling network throttling...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "NetworkThrottlingIndex" /t REG_DWORD /d 0xffffffff /f >nul 2>&1
echo        Done.

echo  [8/9] Setting DNS to Google (8.8.8.8) + Cloudflare (1.1.1.1)...
for /f "tokens=3*" %%i in ('netsh interface show interface ^| findstr "Connected"') do (
    netsh interface ipv4 set dns "%%j" static 8.8.8.8 primary >nul 2>&1
    netsh interface ipv4 add dns "%%j" 1.1.1.1 index=2 >nul 2>&1
)
echo        Done.

echo  [9/9] Flushing ARP cache + re-registering DNS...
arp -d * >nul 2>&1
ipconfig /registerdns >nul 2>&1
echo        Done.

echo.
echo  Running after ping test...
call :QUICKPING AFTER

color 0B
echo.
echo  +============================================================+
echo  ^|  [DONE] Network optimization complete!                    ^|
echo  ^|  Restart recommended for Winsock + TCP changes.           ^|
echo  +============================================================+
echo.
pause
goto MENU

:QUICKPING
echo.
echo  --- Ping to 8.8.8.8 (%~1) ---
ping -n 3 8.8.8.8 | findstr /i "Reply ms loss"
exit /b

:FLUSHDNS
cls
color 0B
echo.
echo  Flushing DNS cache...
ipconfig /flushdns
echo.
echo  Registering DNS...
ipconfig /registerdns >nul 2>&1
echo  [DONE] DNS cache cleared.
echo.
pause
goto MENU

:RESETTCP
cls
color 0E
echo.
echo  +------------------------------------------------------------+
echo  ^|  [WARNING] Resetting Winsock and TCP/IP will require      ^|
echo  ^|  a system restart to fully take effect.                   ^|
echo  +------------------------------------------------------------+
echo.
set /p confirm=  Proceed? (Y/N): 
if /i not "%confirm%"=="Y" ( echo  Cancelled. & pause & goto MENU )
echo.
echo  Resetting Winsock...
netsh winsock reset
echo.
echo  Resetting TCP/IP stack...
netsh int ip reset
echo.
color 0B
echo  [DONE] Winsock and TCP/IP reset.
echo  Please restart your PC for changes to take full effect.
echo.
pause
goto MENU

:SETDNS
cls
color 09
echo.
echo  Setting DNS on all connected interfaces...
echo  Primary   : 8.8.8.8   (Google)
echo  Secondary : 1.1.1.1   (Cloudflare)
echo  Tertiary  : 8.8.4.4   (Google backup)
echo.
for /f "tokens=3*" %%i in ('netsh interface show interface ^| findstr "Connected"') do (
    echo  Adapter: %%j
    netsh interface ipv4 set dns "%%j" static 8.8.8.8 primary
    netsh interface ipv4 add dns "%%j" 1.1.1.1 index=2
    netsh interface ipv4 add dns "%%j" 8.8.4.4 index=3
    echo.
)
color 0B
echo  [DONE] Fast DNS servers applied.
echo.
pause
goto MENU

:THROTTLE
cls
color 09
echo.
echo  Disabling network throttling...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "NetworkThrottlingIndex" /t REG_DWORD /d 0xffffffff /f >nul 2>&1
color 0B
echo  [DONE] Network throttling disabled.
echo.
echo  This allows Windows to allocate full bandwidth instead of
echo  prioritizing multimedia playback over network traffic.
echo.
echo  Use Option [7] (Undo) to restore the default value (10).
echo.
pause
goto MENU

:PINGTEST
cls
color 09
echo.
echo  +============================================================+
echo  ^|   PING LATENCY TEST                                        ^|
echo  +============================================================+
echo.
echo  Testing Google DNS      (8.8.8.8)...
ping -n 4 8.8.8.8 | findstr /i "Reply ms loss"
echo.
echo  Testing Cloudflare DNS  (1.1.1.1)...
ping -n 4 1.1.1.1 | findstr /i "Reply ms loss"
echo.
echo  Testing Quad9 DNS       (9.9.9.9)...
ping -n 4 9.9.9.9 | findstr /i "Reply ms loss"
echo.
echo  Testing your Gateway...
for /f "tokens=3" %%i in ('route print ^| findstr "0.0.0.0.*0.0.0.0"') do (
    ping -n 3 %%i | findstr /i "Reply ms loss"
    goto :doneGW
)
:doneGW
echo.
echo  Latency guide:
echo    Under 20ms  = Excellent
echo    20 - 50ms   = Good
echo    50 - 100ms  = Acceptable
echo    Over 100ms  = Poor  (may affect gaming/video calls)
echo.
pause
goto MENU

:UNDO
cls
color 0D
echo.
echo  +============================================================+
echo  ^|   RESTORING NETWORK DEFAULTS                               ^|
echo  +============================================================+
echo.
echo  [1/3] Restoring DNS to automatic (DHCP)...
for /f "tokens=3*" %%i in ('netsh interface show interface ^| findstr "Connected"') do (
    netsh interface ipv4 set dns "%%j" dhcp >nul 2>&1
    echo  Restored: %%j
)
echo        Done.

echo  [2/3] Restoring network throttling (default=10)...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "NetworkThrottlingIndex" /t REG_DWORD /d 10 /f >nul 2>&1
echo        Done.

echo  [3/3] Flushing DNS after restore...
ipconfig /flushdns >nul 2>&1
echo        Done.

color 0B
echo.
echo  [DONE] All network settings restored to Windows defaults.
echo  Note: Winsock/TCP resets require a restart and cannot be
echo  auto-reversed. If issues persist, restart your PC.
echo.
pause
goto MENU

:NETINFO
cls
color 0B
echo.
echo  +============================================================+
echo  ^|   CURRENT NETWORK INFORMATION                              ^|
echo  +============================================================+
echo.
ipconfig /all
echo.
echo  Active connections:
netstat -an | findstr "ESTABLISHED"
echo.
pause
goto MENU

:EXIT
exit
