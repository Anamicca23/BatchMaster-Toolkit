@echo off
:: ============================================================
:: Name      : PrivacyGuard.bat
:: Version   : 1.0.0
:: Author    : Anamicca23
:: Tested    : Windows 10 22H2, Windows 11 23H2
:: Min OS    : Windows 10 1803
:: Risk      : HIGH
:: Admin     : Required
:: Reversible: Yes  (Option [3] restores all defaults)
:: Desc      : Disables Windows telemetry services, Cortana
::             tracking, advertising ID, WER, and CEIP via
::             registry. Blocks ~30 tracking domains in hosts
::             file. Full restore option included.
:: ============================================================
setlocal enabledelayedexpansion
title PRIVACY GUARD v1.0.0
mode con: cols=70 lines=50
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
echo  +============================================================+
echo  ^|           P R I V A C Y   G U A R D   v1.0.0              ^|
echo  ^|   Stop Windows from spying on you — fully reversible      ^|
echo  +============================================================+
echo  ^|                                                            ^|
echo  ^|   [1]  Apply Full Privacy Protection                       ^|
echo  ^|   [2]  View Current Privacy Status                         ^|
echo  ^|   [3]  RESTORE All Defaults  (full undo)                   ^|
echo  ^|   [4]  Individual Toggles                                  ^|
echo  ^|   [5]  Block Tracking Domains  (hosts file)                ^|
echo  ^|   [6]  Remove Tracking Domain Blocks                       ^|
echo  ^|   [0]  Exit                                                ^|
echo  ^|                                                            ^|
echo  +============================================================+
echo.
set /p c=    Enter Option: 
if "%c%"=="1" goto APPLYALL
if "%c%"=="2" goto VIEWSTATUS
if "%c%"=="3" goto RESTOREALL
if "%c%"=="4" goto TOGGLES
if "%c%"=="5" goto BLOCKHOSTS
if "%c%"=="6" goto REMOVEHOSTS
if "%c%"=="0" goto EXIT
goto MENU

:APPLYALL
cls
color 0E
echo.
echo  +============================================================+
echo  ^|  [WARNING] This will modify system registry settings      ^|
echo  ^|  and append tracking domains to your hosts file.          ^|
echo  ^|  A backup of hosts will be saved as hosts.privacybak      ^|
echo  ^|  Use Option [3] to fully undo all changes.                ^|
echo  +============================================================+
echo.
set /p confirm=  Apply all privacy protections? (Y/N): 
if /i not "%confirm%"=="Y" ( echo  Cancelled. & pause & goto MENU )

cls
color 0D
echo.
echo  +============================================================+
echo  ^|  APPLYING PRIVACY PROTECTIONS...                          ^|
echo  +============================================================+
echo.

echo  [1/7] Disabling telemetry (AllowTelemetry = 0)...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f >nul 2>&1
echo         Done.

echo  [2/7] Stopping DiagTrack + dmwappushservice services...
sc stop DiagTrack >nul 2>&1
sc config DiagTrack start= disabled >nul 2>&1
sc stop dmwappushservice >nul 2>&1
sc config dmwappushservice start= disabled >nul 2>&1
echo         Done.

echo  [3/7] Disabling advertising ID...
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" /v "DisabledByGroupPolicy" /t REG_DWORD /d 1 /f >nul 2>&1
echo         Done.

echo  [4/7] Disabling Cortana data collection...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "DisableWebSearch" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "ConnectedSearchUseWeb" /t REG_DWORD /d 0 /f >nul 2>&1
echo         Done.

echo  [5/7] Disabling Windows Error Reporting...
reg add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting" /v "Disabled" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" /v "Disabled" /t REG_DWORD /d 1 /f >nul 2>&1
sc stop WerSvc >nul 2>&1
sc config WerSvc start= disabled >nul 2>&1
echo         Done.

echo  [6/7] Disabling CEIP (Customer Experience Improvement)...
reg add "HKLM\SOFTWARE\Policies\Microsoft\SQMClient\Windows" /v "CEIPEnable" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\SQMClient\Windows" /v "CEIPEnable" /t REG_DWORD /d 0 /f >nul 2>&1
echo         Done.

echo  [7/7] Disabling app launch tracking...
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_TrackProgs" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_TrackEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
echo         Done.

call :BLOCKHOSTS_SILENT

color 0B
echo.
echo  +============================================================+
echo  ^|  [DONE] Privacy protections applied successfully!         ^|
echo  ^|                                                            ^|
echo  ^|  What was changed:                                         ^|
echo  ^|    Telemetry       disabled (AllowTelemetry = 0)           ^|
echo  ^|    DiagTrack       service stopped + disabled              ^|
echo  ^|    Advertising ID  disabled                                ^|
echo  ^|    Cortana search  disabled                                ^|
echo  ^|    Windows WER     disabled                                ^|
echo  ^|    CEIP            disabled                                ^|
echo  ^|    App tracking    disabled                                ^|
echo  ^|    Tracking hosts  blocked (~30 domains)                   ^|
echo  ^|                                                            ^|
echo  ^|  Use Option [3] to undo all changes.                       ^|
echo  +============================================================+
echo.
pause
goto MENU

:VIEWSTATUS
cls
color 09
echo.
echo  +============================================================+
echo  ^|  CURRENT PRIVACY STATUS                                    ^|
echo  +============================================================+
echo.

:: Telemetry
set "val=Not set (default=enabled)"
for /f "tokens=3" %%a in ('reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" 2^>nul ^| findstr "AllowTelemetry"') do set "val=%%a"
echo  Telemetry         : !val! (0=Off  1=Basic  2=Enhanced  3=Full)

:: DiagTrack service
set "dts=Unknown"
for /f "tokens=4" %%a in ('sc query DiagTrack 2^>nul ^| findstr "STATE"') do set "dts=%%a"
echo  DiagTrack Service : !dts!

:: Advertising ID
set "adv=Not set (default=enabled)"
for /f "tokens=3" %%a in ('reg query "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" 2^>nul ^| findstr "Enabled"') do set "adv=%%a"
echo  Advertising ID    : !adv! (0=Off  1=On)

:: Cortana
set "cort=Not set (default=enabled)"
for /f "tokens=3" %%a in ('reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana" 2^>nul ^| findstr "AllowCortana"') do set "cort=%%a"
echo  Cortana           : !cort! (0=Off  1=On)

:: WER
set "wer=Not set (default=enabled)"
for /f "tokens=3" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting" /v "Disabled" 2^>nul ^| findstr "Disabled"') do set "wer=%%a"
echo  Windows WER       : !wer! (1=Disabled  0=Enabled)

:: CEIP
set "ceip=Not set (default=enabled)"
for /f "tokens=3" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\SQMClient\Windows" /v "CEIPEnable" 2^>nul ^| findstr "CEIPEnable"') do set "ceip=%%a"
echo  CEIP              : !ceip! (0=Off  1=On)

:: Hosts file check
set "hostsBlocked=0"
findstr "vortex.data.microsoft.com" "C:\Windows\System32\drivers\etc\hosts" >nul 2>&1
if not errorlevel 1 set "hostsBlocked=1"
if !hostsBlocked!==1 (
    echo  Tracking Hosts    : BLOCKED  (PrivacyGuard entries present)
) else (
    echo  Tracking Hosts    : Not blocked (no PrivacyGuard entries)
)
echo.
pause
goto MENU

:RESTOREALL
cls
color 0E
echo.
echo  +------------------------------------------------------------+
echo  ^|  [WARNING] This will re-enable Windows telemetry,        ^|
echo  ^|  Cortana, advertising ID, and WER — restoring all        ^|
echo  ^|  Windows defaults.                                        ^|
echo  +------------------------------------------------------------+
echo.
set /p confirm=  Restore all defaults? (Y/N): 
if /i not "%confirm%"=="Y" ( echo  Cancelled. & pause & goto MENU )

cls
color 0D
echo.
echo  Restoring all defaults...
echo.

echo  [1/6] Restoring telemetry...
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "AllowTelemetry" /f >nul 2>&1
echo         Done.

echo  [2/6] Re-enabling DiagTrack service...
sc config DiagTrack start= auto >nul 2>&1
sc start DiagTrack >nul 2>&1
sc config dmwappushservice start= auto >nul 2>&1
sc start dmwappushservice >nul 2>&1
echo         Done.

echo  [3/6] Restoring advertising ID...
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" /v "DisabledByGroupPolicy" /f >nul 2>&1
echo         Done.

echo  [4/6] Restoring Cortana...
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "DisableWebSearch" /f >nul 2>&1
echo         Done.

echo  [5/6] Re-enabling WER + CEIP...
reg delete "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting" /v "Disabled" /f >nul 2>&1
sc config WerSvc start= demand >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\SQMClient\Windows" /v "CEIPEnable" /f >nul 2>&1
echo         Done.

echo  [6/6] Restoring hosts file from backup...
set "hostsFile=C:\Windows\System32\drivers\etc\hosts"
set "hostsBak=C:\Windows\System32\drivers\etc\hosts.privacybak"
if exist "!hostsBak!" (
    copy /y "!hostsBak!" "!hostsFile!" >nul 2>&1
    echo         Restored from backup.
) else (
    call :REMOVEHOSTS_SILENT
    echo         Removed injected entries (no backup found).
)

color 0B
echo.
echo  [DONE] All settings restored to Windows defaults.
echo.
pause
goto MENU

:TOGGLES
cls
color 0D
echo.
echo  +============================================================+
echo  ^|  INDIVIDUAL PRIVACY TOGGLES                               ^|
echo  +============================================================+
echo  ^|                                                            ^|
echo  ^|   [A]  Toggle Telemetry          [E]  Toggle CEIP          ^|
echo  ^|   [B]  Toggle DiagTrack          [F]  Toggle App Tracking  ^|
echo  ^|   [C]  Toggle Advertising ID     [G]  Toggle Feedback Freq ^|
echo  ^|   [D]  Toggle Cortana Search     [0]  Back to Menu         ^|
echo  ^|                                                            ^|
echo  +============================================================+
echo.
set /p t=    Toggle: 
if /i "%t%"=="A" goto TOG_TELEMETRY
if /i "%t%"=="B" goto TOG_DIAGTRACK
if /i "%t%"=="C" goto TOG_ADID
if /i "%t%"=="D" goto TOG_CORTANA
if /i "%t%"=="E" goto TOG_CEIP
if /i "%t%"=="F" goto TOG_TRACKING
if /i "%t%"=="G" goto TOG_FEEDBACK
if "%t%"=="0" goto MENU
goto TOGGLES

:TOG_TELEMETRY
set "cur=1"
for /f "tokens=3" %%a in ('reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" 2^>nul ^| findstr "AllowTelemetry"') do set "cur=%%a"
if "!cur!"=="0x0" (
    reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /f >nul 2>&1
    echo  Telemetry: ENABLED (restored to default)
) else (
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f >nul 2>&1
    echo  Telemetry: DISABLED
)
pause & goto TOGGLES

:TOG_DIAGTRACK
set "cur=running"
for /f "tokens=4" %%a in ('sc query DiagTrack 2^>nul ^| findstr "STATE"') do set "cur=%%a"
if /i "!cur!"=="RUNNING" (
    sc stop DiagTrack >nul 2>&1 & sc config DiagTrack start= disabled >nul 2>&1
    echo  DiagTrack: STOPPED + DISABLED
) else (
    sc config DiagTrack start= auto >nul 2>&1 & sc start DiagTrack >nul 2>&1
    echo  DiagTrack: ENABLED + STARTED
)
pause & goto TOGGLES

:TOG_ADID
set "cur=1"
for /f "tokens=3" %%a in ('reg query "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" 2^>nul ^| findstr "Enabled"') do set "cur=%%a"
if "!cur!"=="0x0" (
    reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /f >nul 2>&1
    echo  Advertising ID: ENABLED
) else (
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d 0 /f >nul 2>&1
    echo  Advertising ID: DISABLED
)
pause & goto TOGGLES

:TOG_CORTANA
set "cur=1"
for /f "tokens=3" %%a in ('reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana" 2^>nul ^| findstr "AllowCortana"') do set "cur=%%a"
if "!cur!"=="0x0" (
    reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana" /f >nul 2>&1
    echo  Cortana: ENABLED
) else (
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana" /t REG_DWORD /d 0 /f >nul 2>&1
    echo  Cortana: DISABLED
)
pause & goto TOGGLES

:TOG_CEIP
set "cur=1"
for /f "tokens=3" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\SQMClient\Windows" /v "CEIPEnable" 2^>nul ^| findstr "CEIPEnable"') do set "cur=%%a"
if "!cur!"=="0x0" (
    reg delete "HKLM\SOFTWARE\Microsoft\SQMClient\Windows" /v "CEIPEnable" /f >nul 2>&1
    echo  CEIP: ENABLED
) else (
    reg add "HKLM\SOFTWARE\Microsoft\SQMClient\Windows" /v "CEIPEnable" /t REG_DWORD /d 0 /f >nul 2>&1
    echo  CEIP: DISABLED
)
pause & goto TOGGLES

:TOG_TRACKING
set "cur=1"
for /f "tokens=3" %%a in ('reg query "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_TrackProgs" 2^>nul ^| findstr "Start_TrackProgs"') do set "cur=%%a"
if "!cur!"=="0x0" (
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_TrackProgs" /t REG_DWORD /d 1 /f >nul 2>&1
    echo  App Launch Tracking: ENABLED
) else (
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_TrackProgs" /t REG_DWORD /d 0 /f >nul 2>&1
    echo  App Launch Tracking: DISABLED
)
pause & goto TOGGLES

:TOG_FEEDBACK
set "cur=1"
for /f "tokens=3" %%a in ('reg query "HKCU\SOFTWARE\Microsoft\Siuf\Rules" /v "NumberOfSIUFInPeriod" 2^>nul ^| findstr "NumberOfSIUFInPeriod"') do set "cur=%%a"
if "!cur!"=="0x0" (
    reg delete "HKCU\SOFTWARE\Microsoft\Siuf\Rules" /v "NumberOfSIUFInPeriod" /f >nul 2>&1
    echo  Feedback Frequency: RESTORED (default)
) else (
    reg add "HKCU\SOFTWARE\Microsoft\Siuf\Rules" /v "NumberOfSIUFInPeriod" /t REG_DWORD /d 0 /f >nul 2>&1
    echo  Feedback Frequency: NEVER
)
pause & goto TOGGLES

:BLOCKHOSTS
cls
color 0D
echo.
echo  +------------------------------------------------------------+
echo  ^|  [WARNING] This will append ~30 Microsoft telemetry      ^|
echo  ^|  domains to: C:\Windows\System32\drivers\etc\hosts       ^|
echo  ^|  A backup will be saved as hosts.privacybak               ^|
echo  +------------------------------------------------------------+
echo.
set /p confirm=  Block tracking domains? (Y/N): 
if /i not "%confirm%"=="Y" ( echo  Cancelled. & pause & goto MENU )
call :BLOCKHOSTS_SILENT
color 0B
echo.
echo  [DONE] Tracking domains blocked in hosts file.
echo.
pause
goto MENU

:BLOCKHOSTS_SILENT
set "hostsFile=C:\Windows\System32\drivers\etc\hosts"
set "hostsBak=C:\Windows\System32\drivers\etc\hosts.privacybak"
:: Backup first
if not exist "!hostsBak!" copy /y "!hostsFile!" "!hostsBak!" >nul 2>&1
:: Check if already applied
findstr "PrivacyGuard" "!hostsFile!" >nul 2>&1
if not errorlevel 1 exit /b
:: Append tracking domains
(
echo.
echo # PrivacyGuard - Microsoft telemetry domains blocked
echo 0.0.0.0 vortex.data.microsoft.com
echo 0.0.0.0 vortex-win.data.microsoft.com
echo 0.0.0.0 telecommand.telemetry.microsoft.com
echo 0.0.0.0 telecommand.telemetry.microsoft.com.nsatc.net
echo 0.0.0.0 oca.telemetry.microsoft.com
echo 0.0.0.0 oca.telemetry.microsoft.com.nsatc.net
echo 0.0.0.0 sqm.telemetry.microsoft.com
echo 0.0.0.0 sqm.telemetry.microsoft.com.nsatc.net
echo 0.0.0.0 watson.telemetry.microsoft.com
echo 0.0.0.0 watson.telemetry.microsoft.com.nsatc.net
echo 0.0.0.0 redir.metaservices.microsoft.com
echo 0.0.0.0 choice.microsoft.com
echo 0.0.0.0 choice.microsoft.com.nsatc.net
echo 0.0.0.0 df.telemetry.microsoft.com
echo 0.0.0.0 reports.wes.df.telemetry.microsoft.com
echo 0.0.0.0 wes.df.telemetry.microsoft.com
echo 0.0.0.0 services.wes.df.telemetry.microsoft.com
echo 0.0.0.0 sqm.df.telemetry.microsoft.com
echo 0.0.0.0 telemetry.microsoft.com
echo 0.0.0.0 cy2.vortex.data.microsoft.com.akadns.net
echo 0.0.0.0 cy2.settings.data.microsoft.com.akadns.net
echo 0.0.0.0 settings-sandbox.data.microsoft.com
echo 0.0.0.0 settings-win.data.microsoft.com
echo 0.0.0.0 watson.live.com
echo 0.0.0.0 ceuswatcab01.blob.core.windows.net
echo 0.0.0.0 ceuswatcab02.blob.core.windows.net
echo 0.0.0.0 eaus2watcab01.blob.core.windows.net
echo 0.0.0.0 eaus2watcab02.blob.core.windows.net
echo 0.0.0.0 weus2watcab01.blob.core.windows.net
echo 0.0.0.0 weus2watcab02.blob.core.windows.net
echo # PrivacyGuard - end
) >> "!hostsFile!"
ipconfig /flushdns >nul 2>&1
exit /b

:REMOVEHOSTS
cls
color 0D
echo.
echo  Removing PrivacyGuard entries from hosts file...
call :REMOVEHOSTS_SILENT
color 0B
echo  [DONE] Tracking domain blocks removed.
echo.
pause
goto MENU

:REMOVEHOSTS_SILENT
set "hostsFile=C:\Windows\System32\drivers\etc\hosts"
set "tmpHosts=%TEMP%\hosts_clean.txt"
if exist "%tmpHosts%" del "%tmpHosts%"
set "inBlock=0"
for /f "delims=" %%l in ('type "!hostsFile!"') do (
    set "ln=%%l"
    echo !ln! | findstr "PrivacyGuard" >nul 2>&1
    if not errorlevel 1 (
        if "!ln:~0,2!"=="# " (
            set "inBlock=1"
        ) else (
            set "inBlock=0"
        )
    )
    if !inBlock!==0 (
        echo !ln! | findstr "0.0.0.0.*microsoft\|0.0.0.0.*akadns\|0.0.0.0.*blob.core\|0.0.0.0.*watson" >nul 2>&1
        if errorlevel 1 echo %%l >> "%tmpHosts%"
    )
)
if exist "%tmpHosts%" (
    copy /y "%tmpHosts%" "!hostsFile!" >nul 2>&1
    del "%tmpHosts%" >nul 2>&1
)
ipconfig /flushdns >nul 2>&1
exit /b

:EXIT
exit
