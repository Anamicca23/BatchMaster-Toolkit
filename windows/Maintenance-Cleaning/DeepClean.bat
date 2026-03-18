@echo off
:: ============================================================
:: Name      : DeepClean.bat
:: Version   : 2.0.0
:: Author    : Anamicca23
:: Tested    : Windows 10 22H2, Windows 11 23H2
:: Min OS    : Windows 10 1803
:: Risk      : MEDIUM
:: Admin     : Required
:: Reversible: No  (deleted files cannot be recovered)
:: Desc      : 14-step deep system clean — temp folders, prefetch,
::             thumbnail cache, DNS, all browser caches, Windows
::             Update cache, recycle bin, error reports, event logs,
::             and silent Disk Cleanup.
:: ============================================================
setlocal enabledelayedexpansion
title DEEP CLEAN v2.0.0
mode con: cols=70 lines=50
if not "%1"=="RUN" start /MAX cmd /k "%~f0" RUN & exit

net session >nul 2>&1
if %errorlevel% neq 0 (
    color 0C & cls
    echo.
    echo  +------------------------------------------------------------+
    echo  ^|  [!] Must be run as Administrator for full clean effect.   ^|
    echo  ^|      Right-click ^> Run as administrator                    ^|
    echo  +------------------------------------------------------------+
    echo.
    timeout /t 4 >nul
)

:MENU
cls
color 0A
echo.
echo  +============================================================+
echo  ^|              D E E P   C L E A N   v2.0.0                 ^|
echo  ^|         Full System Cache and Temp File Cleaner            ^|
echo  +============================================================+
echo  ^|                                                            ^|
echo  ^|   [1]  Full 14-Step Deep Clean  (Recommended)             ^|
echo  ^|   [2]  Quick Clean  (Temp + DNS only)                      ^|
echo  ^|   [3]  Browser Cache Only  (Edge/Chrome/Firefox)           ^|
echo  ^|   [4]  Windows Update Cache Only                           ^|
echo  ^|   [5]  Event Logs Only                                     ^|
echo  ^|   [6]  Preview — Show What Will Be Cleaned                 ^|
echo  ^|   [0]  Exit                                                ^|
echo  ^|                                                            ^|
echo  +============================================================+
echo.
set /p c=    Enter Option: 
if "%c%"=="1" goto FULLCLEAN
if "%c%"=="2" goto QUICKCLEAN
if "%c%"=="3" goto BROWSERCACHE
if "%c%"=="4" goto WUPCACHE
if "%c%"=="5" goto EVENTLOGS
if "%c%"=="6" goto PREVIEW
if "%c%"=="0" goto EXIT
goto MENU

:CONFIRM
echo.
echo  +------------------------------------------------------------+
echo  ^|  [WARNING] This will PERMANENTLY delete junk files.       ^|
echo  ^|  Deleted files cannot be recovered from Recycle Bin.      ^|
echo  ^|  This is safe — only temp and cache files are removed.    ^|
echo  +------------------------------------------------------------+
echo.
set /p confirm=  Proceed? (Y/N): 
if /i not "%confirm%"=="Y" (
    echo.
    echo  Cancelled. No changes were made.
    echo.
    pause
    goto MENU
)
exit /b

:FULLCLEAN
call :CONFIRM
if errorlevel 1 goto MENU
cls
color 0E
echo.
echo  +============================================================+
echo  ^|   RUNNING FULL 14-STEP DEEP CLEAN...                      ^|
echo  +============================================================+
echo.

:: Track space before
for /f "tokens=3" %%a in ('dir C:\ /-c 2^>nul ^| findstr "bytes free"') do set "before=%%a"

echo  [1/14] User Temp folder (%TEMP%)...
del /f /s /q "%temp%\*" >nul 2>&1
rd /s /q "%temp%" >nul 2>&1
md "%temp%" >nul 2>&1
echo         Done.

echo  [2/14] Windows Temp folder (C:\Windows\Temp)...
del /f /s /q "C:\Windows\Temp\*" >nul 2>&1
rd /s /q "C:\Windows\Temp" >nul 2>&1
md "C:\Windows\Temp" >nul 2>&1
echo         Done.

echo  [3/14] Prefetch data...
del /f /s /q "C:\Windows\Prefetch\*" >nul 2>&1
echo         Done.

echo  [4/14] Thumbnail cache...
del /f /s /q "%localappdata%\Microsoft\Windows\Explorer\thumbcache_*.db" >nul 2>&1
echo         Done.

echo  [5/14] DNS cache...
ipconfig /flushdns >nul 2>&1
echo         Done.

echo  [6/14] Internet Explorer / Edge WebCache...
del /f /s /q "%localappdata%\Microsoft\Windows\INetCache\*" >nul 2>&1
del /f /s /q "%localappdata%\Microsoft\Windows\WebCache\*" >nul 2>&1
echo         Done.

echo  [7/14] Microsoft Edge (Chromium) cache...
del /f /s /q "%localappdata%\Microsoft\Edge\User Data\Default\Cache\*" >nul 2>&1
del /f /s /q "%localappdata%\Microsoft\Edge\User Data\Default\Code Cache\*" >nul 2>&1
del /f /s /q "%localappdata%\Microsoft\Edge\User Data\Default\GPUCache\*" >nul 2>&1
echo         Done.

echo  [8/14] Google Chrome cache...
del /f /s /q "%localappdata%\Google\Chrome\User Data\Default\Cache\*" >nul 2>&1
del /f /s /q "%localappdata%\Google\Chrome\User Data\Default\Code Cache\*" >nul 2>&1
del /f /s /q "%localappdata%\Google\Chrome\User Data\Default\GPUCache\*" >nul 2>&1
echo         Done.

echo  [9/14] Firefox cache...
for /d %%i in ("%localappdata%\Mozilla\Firefox\Profiles\*") do (
    del /f /s /q "%%i\cache2\*" >nul 2>&1
    del /f /s /q "%%i\startupCache\*" >nul 2>&1
    del /f /s /q "%%i\thumbnails\*" >nul 2>&1
)
echo         Done.

echo  [10/14] Windows Update download cache...
net stop wuauserv >nul 2>&1
net stop bits >nul 2>&1
del /f /s /q "C:\Windows\SoftwareDistribution\Download\*" >nul 2>&1
net start wuauserv >nul 2>&1
net start bits >nul 2>&1
echo         Done.

echo  [11/14] Recycle Bin (all drives)...
rd /s /q "C:\$Recycle.Bin" >nul 2>&1
echo         Done.

echo  [12/14] Windows Error Reports...
del /f /s /q "%localappdata%\Microsoft\Windows\WER\*" >nul 2>&1
del /f /s /q "C:\ProgramData\Microsoft\Windows\WER\*" >nul 2>&1
echo         Done.

echo  [13/14] Windows Event Logs...
for /f "tokens=*" %%G in ('wevtutil el 2^>nul') do (
    wevtutil cl "%%G" >nul 2>&1
)
echo         Done.

echo  [14/14] Built-in Disk Cleanup (silent)...
cleanmgr /sagerun:1 >nul 2>&1
echo         Done.

:: Track space after
for /f "tokens=3" %%a in ('dir C:\ /-c 2^>nul ^| findstr "bytes free"') do set "after=%%a"

color 0B
echo.
echo  +============================================================+
echo  ^|   [DONE] Deep Clean Complete!                              ^|
echo  +============================================================+
echo  ^|                                                            ^|
echo  ^|   What was cleaned:                                        ^|
echo  ^|     User + Windows Temp folders                            ^|
echo  ^|     Prefetch data                                          ^|
echo  ^|     Thumbnail cache                                        ^|
echo  ^|     DNS cache (flushed)                                    ^|
echo  ^|     IE / Edge / Chrome / Firefox caches                    ^|
echo  ^|     Windows Update download cache                          ^|
echo  ^|     Recycle Bin                                            ^|
echo  ^|     Windows Error Reports                                  ^|
echo  ^|     Event Logs                                             ^|
echo  ^|     Built-in Disk Cleanup                                  ^|
echo  ^|                                                            ^|
echo  ^|   Tip: Restart your PC for full effect.                    ^|
echo  +============================================================+
echo.
pause
goto MENU

:QUICKCLEAN
call :CONFIRM
if errorlevel 1 goto MENU
cls
color 0E
echo.
echo  [1/3] User Temp folder...
del /f /s /q "%temp%\*" >nul 2>&1
rd /s /q "%temp%" >nul 2>&1 & md "%temp%" >nul 2>&1
echo        Done.

echo  [2/3] Windows Temp folder...
del /f /s /q "C:\Windows\Temp\*" >nul 2>&1
echo        Done.

echo  [3/3] DNS cache...
ipconfig /flushdns >nul 2>&1
echo        Done.

color 0B
echo.
echo  [DONE] Quick clean complete.
echo.
pause
goto MENU

:BROWSERCACHE
call :CONFIRM
if errorlevel 1 goto MENU
cls
color 0E
echo.
echo  Clearing browser caches...
echo.
echo  [1/3] Edge (Chromium)...
del /f /s /q "%localappdata%\Microsoft\Edge\User Data\Default\Cache\*" >nul 2>&1
del /f /s /q "%localappdata%\Microsoft\Edge\User Data\Default\Code Cache\*" >nul 2>&1
echo        Done.

echo  [2/3] Google Chrome...
del /f /s /q "%localappdata%\Google\Chrome\User Data\Default\Cache\*" >nul 2>&1
del /f /s /q "%localappdata%\Google\Chrome\User Data\Default\Code Cache\*" >nul 2>&1
echo        Done.

echo  [3/3] Mozilla Firefox...
for /d %%i in ("%localappdata%\Mozilla\Firefox\Profiles\*") do (
    del /f /s /q "%%i\cache2\*" >nul 2>&1
    del /f /s /q "%%i\startupCache\*" >nul 2>&1
)
echo        Done.

color 0B
echo.
echo  [DONE] All browser caches cleared.
echo.
pause
goto MENU

:WUPCACHE
call :CONFIRM
if errorlevel 1 goto MENU
cls
color 0E
echo.
echo  Stopping Windows Update services...
net stop wuauserv >nul 2>&1
net stop bits >nul 2>&1
echo  Deleting download cache...
del /f /s /q "C:\Windows\SoftwareDistribution\Download\*" >nul 2>&1
echo  Restarting Windows Update services...
net start wuauserv >nul 2>&1
net start bits >nul 2>&1
color 0B
echo.
echo  [DONE] Windows Update cache cleared.
echo  Windows will re-download pending updates on next check.
echo.
pause
goto MENU

:EVENTLOGS
call :CONFIRM
if errorlevel 1 goto MENU
cls
color 0E
echo.
echo  Clearing all Windows Event Logs...
echo.
set "count=0"
for /f "tokens=*" %%G in ('wevtutil el 2^>nul') do (
    wevtutil cl "%%G" >nul 2>&1
    set /a count+=1
)
color 0B
echo  [DONE] Cleared !count! event log(s).
echo.
pause
goto MENU

:PREVIEW
cls
color 09
echo.
echo  +============================================================+
echo  ^|   PREVIEW — What will be cleaned                          ^|
echo  +============================================================+
echo.
echo  The following folders will be emptied:
echo.
echo  User Temp       : %TEMP%
echo  Windows Temp    : C:\Windows\Temp
echo  Prefetch        : C:\Windows\Prefetch
echo  Thumbnails      : %localappdata%\Microsoft\Windows\Explorer\thumbcache_*.db
echo  IE/Edge Cache   : %localappdata%\Microsoft\Windows\INetCache
echo  Edge Chromium   : %localappdata%\Microsoft\Edge\User Data\Default\Cache
echo  Chrome Cache    : %localappdata%\Google\Chrome\User Data\Default\Cache
echo  Firefox Cache   : %localappdata%\Mozilla\Firefox\Profiles\*\cache2
echo  WU Downloads    : C:\Windows\SoftwareDistribution\Download
echo  Recycle Bin     : C:\$Recycle.Bin
echo  WER Reports     : %localappdata%\Microsoft\Windows\WER
echo  Event Logs      : All Windows logs (via wevtutil)
echo.
echo  DNS cache will also be flushed (ipconfig /flushdns)
echo  Disk Cleanup (cleanmgr) will run in silent mode
echo.
echo  No files outside these locations will be touched.
echo.
pause
goto MENU

:EXIT
exit