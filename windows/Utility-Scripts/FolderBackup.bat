@echo off
:: ============================================================
:: Name      : FolderBackup.bat
:: Version   : 1.0.0
:: Author    : Anamicca23
:: Tested    : Windows 10 22H2, Windows 11 23H2
:: Min OS    : Windows 10 1803
:: Risk      : LOW
:: Admin     : Not Required
:: Reversible: Yes  (backup can be deleted; source untouched)
:: Desc      : Interactive backup script. Prompts for source
::             and destination, creates a BACKUP_YYYYMMDD_HHMMSS
::             subfolder, copies all files recursively via
::             robocopy with retry logic and live progress.
:: ============================================================
setlocal enabledelayedexpansion
title FOLDER BACKUP v1.0.0
mode con: cols=72 lines=45
if not "%1"=="RUN" start /MAX cmd /k "%~f0" RUN & exit

:MENU
cls
color 0B
echo.
echo  +============================================================+
echo  ^|          F O L D E R   B A C K U P   v1.0.0               ^|
echo  ^|     Reliable timestamped folder backup with robocopy       ^|
echo  +============================================================+
echo  ^|                                                            ^|
echo  ^|   [1]  Backup a Folder  (choose source + destination)      ^|
echo  ^|   [2]  Quick Backup Documents to Desktop                   ^|
echo  ^|   [3]  Quick Backup Desktop to Documents                   ^|
echo  ^|   [4]  View Existing Backups on Desktop                    ^|
echo  ^|   [5]  About — How This Backup Works                       ^|
echo  ^|   [0]  Exit                                                ^|
echo  ^|                                                            ^|
echo  +============================================================+
echo.
set /p c=    Enter Option: 
if "%c%"=="1" goto CUSTOMBACKUP
if "%c%"=="2" ( set "src=%USERPROFILE%\Documents" & set "dst=%USERPROFILE%\Desktop" & goto RUNBACKUP )
if "%c%"=="3" ( set "src=%USERPROFILE%\Desktop"   & set "dst=%USERPROFILE%\Documents" & goto RUNBACKUP )
if "%c%"=="4" goto VIEWBACKUPS
if "%c%"=="5" goto ABOUT
if "%c%"=="0" goto EXIT
goto MENU

:CUSTOMBACKUP
cls
color 0B
echo.
echo  SOURCE FOLDER (what you want to back up):
echo  Example: C:\Users\%USERNAME%\Projects
echo.
set /p src=  Source: 
if not exist "!src!" (
    color 0C
    echo.
    echo  [ERROR] Source folder not found: !src!
    pause
    goto MENU
)
echo.
echo  DESTINATION FOLDER (where to store the backup):
echo  Example: D:\Backups    or    E:\
echo.
set /p dst=  Destination: 
if not exist "!dst!" (
    color 0E
    echo.
    echo  Destination does not exist. Create it? (Y/N)
    set /p mkdst=  Choice: 
    if /i not "!mkdst!"=="Y" ( echo  Cancelled. & pause & goto MENU )
    md "!dst!" >nul 2>&1
    if not exist "!dst!" (
        color 0C
        echo  [ERROR] Could not create destination folder.
        pause
        goto MENU
    )
)
goto RUNBACKUP

:RUNBACKUP
cls
color 0B

:: Build timestamp for folder name
for /f "tokens=2 delims==" %%a in ('wmic os get LocalDateTime /value 2^>nul ^| findstr "="') do set "ldt=%%a"
set "ts=!ldt:~0,4!!ldt:~4,2!!ldt:~6,2!_!ldt:~8,2!!ldt:~10,2!!ldt:~12,2!"
if "!ts!"=="" (
    :: Fallback timestamp from DATE/TIME
    set "ts=%DATE:~-4,4%%DATE:~-7,2%%DATE:~-10,2%_%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%"
    set "ts=!ts: =0!"
)

set "backupDir=!dst!\BACKUP_!ts!"
set "logFile=!backupDir!\backup_log.txt"

echo.
echo  +============================================================+
echo  ^|  BACKUP DETAILS                                            ^|
echo  +============================================================+
echo  ^|                                                            ^|
echo  ^|  Source      : !src!
echo  ^|  Destination : !backupDir!
echo  ^|  Method      : robocopy /e  (full recursive)
echo  ^|  Retries     : 3 per file   Wait: 5 seconds
echo  ^|                                                            ^|
echo  +============================================================+
echo.
set /p confirm=  Start backup? (Y/N): 
if /i not "%confirm%"=="Y" ( echo  Cancelled. & pause & goto MENU )

echo.
echo  Creating backup folder...
md "!backupDir!" >nul 2>&1
if not exist "!backupDir!" (
    color 0C
    echo  [ERROR] Could not create backup folder.
    pause
    goto MENU
)

echo  Starting backup... This may take a while.
echo  (robocopy is running — do not close this window)
echo.

:: Record start time
set "startTime=%TIME%"

:: Run robocopy with full output to log + screen
robocopy "!src!" "!backupDir!" /e /r:3 /w:5 /tee /log:"!logFile!" /np

set "rcErr=%errorlevel%"
set "endTime=%TIME%"

:: robocopy exit codes: 0-7 are success/partial, 8+ are errors
echo.
echo  +============================================================+
if !rcErr! leq 7 (
    color 0B
    echo  ^|  [DONE] Backup completed successfully!                   ^|
) else (
    color 0C
    echo  ^|  [WARNING] Backup completed with errors.                 ^|
    echo  ^|  Check the log file for skipped files.                   ^|
)
echo  +============================================================+
echo.
echo  Source        : !src!
echo  Backup saved  : !backupDir!
echo  Log file      : !logFile!
echo  Start time    : !startTime!
echo  End time      : !endTime!
echo.
echo  Robocopy exit code: !rcErr!
echo    0 = No files copied (already up to date)
echo    1 = Files copied successfully
echo    2 = Extra files or dirs detected
echo    4 = Mismatched files / dirs
echo    8+ = Some files could not be copied (permission/lock)
echo.
pause
goto MENU

:VIEWBACKUPS
cls
color 09
echo.
echo  +============================================================+
echo  ^|  BACKUPS ON DESKTOP                                        ^|
echo  +============================================================+
echo.
set "found=0"
for /d %%d in ("%USERPROFILE%\Desktop\BACKUP_*") do (
    echo  Folder : %%~nxd
    echo  Path   : %%d
    for /f "tokens=3" %%s in ('dir "%%d" /-c /s 2^>nul ^| findstr "File(s)"') do (
        set /a szMB=%%s/1048576
        echo  Size   : ~!szMB! MB
    )
    echo.
    set "found=1"
)
if !found!==0 (
    echo  No BACKUP_ folders found on Desktop.
    echo  Backups appear only when Desktop is chosen as destination.
)
echo.
pause
goto MENU

:ABOUT
cls
color 09
echo.
echo  +============================================================+
echo  ^|  HOW THIS BACKUP WORKS                                     ^|
echo  +============================================================+
echo.
echo  What it does:
echo  --------------
echo  Uses robocopy (built into Windows) to copy ALL files
echo  recursively from your source folder to a new timestamped
echo  subfolder at your destination.
echo.
echo  Folder name format:
echo    BACKUP_YYYYMMDD_HHMMSS
echo    Example: BACKUP_20250318_143022
echo.
echo  robocopy flags used:
echo    /e      Copy all subdirectories (including empty ones)
echo    /r:3    Retry 3 times if a file is locked
echo    /w:5    Wait 5 seconds between retries
echo    /tee    Output to both screen and log file
echo    /np     No progress percentage (cleaner output)
echo    /log    Save full log to backup folder
echo.
echo  What is NOT backed up:
echo    - Files currently locked by another process
echo    - Files you don't have read permission to
echo.
echo  How to restore:
echo    Simply copy files from BACKUP_... back to original location.
echo    No special tool needed.
echo.
pause
goto MENU

:EXIT
exit
