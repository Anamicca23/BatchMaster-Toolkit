@echo off
:: ============================================================
:: Name      : WifiPasswordViewer.bat
:: Version   : 1.0.0
:: Author    : Anamicca23
:: Tested    : Windows 10 22H2, Windows 11 23H2
:: Min OS    : Windows 10 1803
:: Risk      : LOW
:: Admin     : Required
:: Reversible: Yes  (read-only, no changes made)
:: Desc      : Reads all saved WiFi profiles from the Windows
::             credential store and displays each SSID with its
::             stored plaintext password. Local machine only.
:: ============================================================
setlocal enabledelayedexpansion
title WIFI PASSWORD VIEWER v1.0.0
mode con: cols=70 lines=45
if not "%1"=="RUN" start /MAX cmd /k "%~f0" RUN & exit

net session >nul 2>&1
if %errorlevel% neq 0 (
    color 0C & cls
    echo.
    echo  [ERROR] Must be run as Administrator to read all profiles.
    echo  Right-click ^> Run as administrator.
    echo.
    pause & exit /b 1
)

:MENU
cls
color 09
echo.
echo  +============================================================+
echo  ^|      W I F I   P A S S W O R D   V I E W E R  v1.0.0     ^|
echo  +============================================================+
echo  ^|                                                            ^|
echo  ^|   [1]  Show All WiFi Passwords                             ^|
echo  ^|   [2]  Show All Profile Names Only  (no passwords)         ^|
echo  ^|   [3]  Search for a Specific Network                       ^|
echo  ^|   [4]  Export All to Desktop  (passwords.txt)              ^|
echo  ^|   [5]  Show Current WiFi Connection Info                   ^|
echo  ^|   [0]  Exit                                                ^|
echo  ^|                                                            ^|
echo  +============================================================+
echo.
set /p c=    Enter Option: 
if "%c%"=="1" goto SHOWALLPW
if "%c%"=="2" goto SHOWNAMES
if "%c%"=="3" goto SEARCHSSID
if "%c%"=="4" goto EXPORTPW
if "%c%"=="5" goto CURRENTCONN
if "%c%"=="0" goto EXIT
goto MENU

:SHOWALLPW
cls
color 09
echo.
echo  +============================================================+
echo  ^|   ALL SAVED WIFI PROFILES AND PASSWORDS                    ^|
echo  +============================================================+
echo.

set "count=0"
for /f "tokens=2 delims=:" %%a in ('netsh wlan show profiles 2^>nul ^| findstr "All User Profile"') do (
    set "ssid=%%a"
    set "ssid=!ssid:~1!"
    set /a count+=1

    echo  +----------------------------------------------------------+
    echo  ^|  SSID #!count!
    echo  +----------------------------------------------------------+
    echo  Network Name : !ssid!

    for /f "tokens=2 delims=:" %%b in ('netsh wlan show profile name="!ssid!" key=clear 2^>nul ^| findstr "Key Content"') do (
        set "pw=%%b"
        set "pw=!pw:~1!"
        echo  Password     : !pw!
    )

    for /f "tokens=2 delims=:" %%b in ('netsh wlan show profile name="!ssid!" key=clear 2^>nul ^| findstr "Authentication"') do (
        set "auth=%%b"
        set "auth=!auth:~1!"
        echo  Security     : !auth!
    )
    echo.
)

if !count!==0 (
    color 0E
    echo  No saved WiFi profiles found on this machine.
    echo  You must connect to a WiFi network before passwords are saved.
) else (
    color 0B
    echo  +----------------------------------------------------------+
    echo  Total profiles found: !count!
    echo  +----------------------------------------------------------+
)
echo.
pause
goto MENU

:SHOWNAMES
cls
color 09
echo.
echo  +============================================================+
echo  ^|   SAVED WIFI PROFILE NAMES                                 ^|
echo  +============================================================+
echo.
netsh wlan show profiles 2>nul
echo.
pause
goto MENU

:SEARCHSSID
cls
color 09
echo.
echo  Enter the WiFi network name (SSID) to look up:
set /p searchSSID=  Network Name: 
echo.

set "found=0"
for /f "tokens=2 delims=:" %%a in ('netsh wlan show profiles 2^>nul ^| findstr "All User Profile"') do (
    set "ssid=%%a"
    set "ssid=!ssid:~1!"
    if /i "!ssid!"=="!searchSSID!" set "found=1"
)

if !found!==0 (
    color 0C
    echo  [NOT FOUND] No profile named "!searchSSID!" exists on this machine.
    echo.
    echo  Available profiles:
    netsh wlan show profiles 2>nul | findstr "All User Profile"
) else (
    color 09
    echo  +----------------------------------------------------------+
    echo  Network Name : !searchSSID!
    echo  +----------------------------------------------------------+
    for /f "tokens=2 delims=:" %%b in ('netsh wlan show profile name="!searchSSID!" key=clear 2^>nul ^| findstr "Key Content"') do (
        set "pw=%%b" & set "pw=!pw:~1!"
        echo  Password     : !pw!
    )
    for /f "tokens=2 delims=:" %%b in ('netsh wlan show profile name="!searchSSID!" key=clear 2^>nul ^| findstr "Authentication"') do (
        set "auth=%%b" & set "auth=!auth:~1!"
        echo  Security     : !auth!
    )
    for /f "tokens=2 delims=:" %%b in ('netsh wlan show profile name="!searchSSID!" key=clear 2^>nul ^| findstr "SSID name"') do (
        echo  SSID Detail  : %%b
    )
)
echo.
pause
goto MENU

:EXPORTPW
cls
color 0E
echo.
echo  +------------------------------------------------------------+
echo  ^|  [WARNING] This will save all WiFi passwords to a         ^|
echo  ^|  plain text file on your Desktop.                         ^|
echo  ^|  Keep this file secure and delete after use.              ^|
echo  +------------------------------------------------------------+
echo.
set /p confirm=  Export passwords to Desktop? (Y/N): 
if /i not "%confirm%"=="Y" ( echo  Cancelled. & pause & goto MENU )

set "rpt=%USERPROFILE%\Desktop\WiFi_Passwords.txt"
(
echo ============================================================
echo   WIFI PASSWORD EXPORT
echo   Generated : %DATE% %TIME%
echo   Computer  : %COMPUTERNAME%
echo   WARNING   : Keep this file private. Delete after use.
echo ============================================================
echo.
for /f "tokens=2 delims=:" %%a in ('netsh wlan show profiles 2^>nul ^| findstr "All User Profile"') do (
    set "ssid=%%a"
    set "ssid=!ssid:~1!"
    echo  Network : !ssid!
    for /f "tokens=2 delims=:" %%b in ('netsh wlan show profile name="!ssid!" key=clear 2^>nul ^| findstr "Key Content"') do (
        set "pw=%%b" & set "pw=!pw:~1!"
        echo  Password: !pw!
    )
    echo  --
)
echo.
echo ============================================================
echo   END OF EXPORT
echo ============================================================
) > "%rpt%" 2>nul

if exist "%rpt%" (
    color 0B
    echo  [OK] Saved to Desktop as WiFi_Passwords.txt
    echo.
    echo  REMINDER: Delete this file after you have noted the passwords.
    echo  Plain text password files are a security risk if left on Desktop.
) else (
    color 0C
    echo  [ERROR] Could not write file to Desktop.
)
echo.
pause
goto MENU

:CURRENTCONN
cls
color 09
echo.
echo  +============================================================+
echo  ^|   CURRENT WIFI CONNECTION                                  ^|
echo  +============================================================+
echo.
netsh wlan show interfaces 2>nul
echo.
echo  Signal strength guide:
echo    90-100%%  Excellent     50-70%%  Fair
echo    70-90%%   Good          Below 50%%  Poor
echo.
pause
goto MENU

:EXIT
exit
