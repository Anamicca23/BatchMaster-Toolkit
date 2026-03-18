@echo off
:: ============================================================
:: Name      : AccountAuditor.bat
:: Version   : 1.0.0
:: Author    : Anamicca23
:: Tested    : Windows 10 22H2, Windows 11 23H2
:: Min OS    : Windows 10 1803
:: Risk      : LOW
:: Admin     : Required
:: Reversible: Yes  (read-only audit, no changes made)
:: Desc      : Lists all local user accounts with last login
::             timestamp, password age, and account status.
::             Flags unused, blank-password, and admin accounts.
:: ============================================================
setlocal enabledelayedexpansion
title ACCOUNT AUDITOR v1.0.0
mode con: cols=78 lines=48
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
echo  +==================================================================+
echo  ^|           A C C O U N T   A U D I T O R   v1.0.0               ^|
echo  ^|       Audit local user accounts for security risks               ^|
echo  +==================================================================+
echo  ^|                                                                  ^|
echo  ^|   [1]  Full Account Audit  (all accounts with flags)             ^|
echo  ^|   [2]  List All Accounts (quick view)                            ^|
echo  ^|   [3]  Show Administrator Group Members                          ^|
echo  ^|   [4]  Show Detailed Info for One Account                        ^|
echo  ^|   [5]  Show Accounts with Password Issues                        ^|
echo  ^|   [6]  Export Full Audit Report to Desktop                       ^|
echo  ^|   [0]  Exit                                                      ^|
echo  ^|                                                                  ^|
echo  +==================================================================+
echo.
set /p c=    Enter Option: 
if "%c%"=="1" goto FULLAUDIT
if "%c%"=="2" goto LISTALL
if "%c%"=="3" goto ADMINGROUP
if "%c%"=="4" goto ONEACCOUNT
if "%c%"=="5" goto PWISSUES
if "%c%"=="6" goto EXPORTREPORT
if "%c%"=="0" goto EXIT
goto MENU

:FULLAUDIT
cls
color 0C
echo.
echo  +==================================================================+
echo  ^|  FULL ACCOUNT AUDIT                                              ^|
echo  +==================================================================+
echo.
echo  Scanning all local user accounts...
echo.

set "flagCount=0"
set "totalCount=0"

for /f "tokens=1" %%u in ('net user 2^>nul ^| findstr /v "command\|User accounts\|---\|The command"') do (
    set "uname=%%u"
    if not "!uname!"=="" if not "!uname!"=="The" (
        set /a totalCount+=1
        set "flags="

        :: Last logon
        set "lastLogon=Never"
        for /f "tokens=3,4,5" %%a in ('net user "!uname!" 2^>nul ^| findstr /i "Last logon"') do (
            if not "%%a"=="Never" set "lastLogon=%%a %%b %%c"
            if "%%a"=="Never" set "lastLogon=NEVER  ^<-- never logged in"
        )

        :: Password required
        set "pwReq=Yes"
        for /f "tokens=4" %%a in ('net user "!uname!" 2^>nul ^| findstr /i "Password required"') do set "pwReq=%%a"

        :: Account active
        set "active=Yes"
        for /f "tokens=3" %%a in ('net user "!uname!" 2^>nul ^| findstr /i "Account active"') do set "active=%%a"

        :: Password expires
        set "pwExp=Unknown"
        for /f "tokens=3,4,5" %%a in ('net user "!uname!" 2^>nul ^| findstr /i "Password expires"') do (
            set "pwExp=%%a %%b %%c"
        )

        :: Build flags
        if /i "!lastLogon!"=="NEVER  ^<-- never logged in" (
            set "flags=!flags! [NEVER-LOGGED-IN]"
            set /a flagCount+=1
        )
        if /i "!pwReq!"=="No" (
            set "flags=!flags! [NO-PASSWORD]"
            set /a flagCount+=1
        )
        if /i "!active!"=="No" (
            set "flags=!flags! [DISABLED]"
        )

        echo  +----------------------------------------------------------------+
        echo  Account   : !uname!
        echo  Active    : !active!
        echo  Last Login: !lastLogon!
        echo  Pw Req    : !pwReq!
        echo  Pw Expires: !pwExp!
        if defined flags (
            color 0C
            echo  FLAGS     :!flags!
            color 0A
        ) else (
            echo  FLAGS     : None  (account looks OK)
        )
        echo.
    )
)

echo  +==================================================================+
echo  Total accounts: !totalCount!   Security flags raised: !flagCount!
echo  +==================================================================+
echo.
if !flagCount! gtr 0 (
    color 0C
    echo  [!] !flagCount! account(s) flagged. Review above for details.
    echo.
    echo  Recommended actions:
    echo    NEVER-LOGGED-IN : Disable or delete the account if unused
    echo    NO-PASSWORD     : Set a strong password immediately
    echo    DISABLED        : Delete if the account is no longer needed
) else (
    color 0B
    echo  [OK] No security issues found with local accounts.
)
echo.
pause
goto MENU

:LISTALL
cls
color 09
echo.
echo  +==================================================================+
echo  ^|  ALL LOCAL USER ACCOUNTS                                         ^|
echo  +==================================================================+
echo.
net user 2>nul
echo.
echo  For detailed info: net user ^<username^>
echo.
pause
goto MENU

:ADMINGROUP
cls
color 0C
echo.
echo  +==================================================================+
echo  ^|  ADMINISTRATOR GROUP MEMBERS                                     ^|
echo  +==================================================================+
echo.
net localgroup administrators 2>nul
echo.
echo  +------------------------------------------------------------------+
echo  Note: Only accounts that genuinely need admin rights should appear
echo  in this group. Review any unexpected entries.
echo.
pause
goto MENU

:ONEACCOUNT
cls
color 09
echo.
echo  Enter the username to inspect:
set /p uTarget=  Username: 

net user "!uTarget!" >nul 2>&1
if errorlevel 1 (
    color 0C
    echo.
    echo  [ERROR] Account "!uTarget!" not found on this machine.
    echo.
    echo  Available accounts:
    net user 2>nul | findstr /v "command\|User accounts\|---\|The command"
    pause
    goto MENU
)

cls
color 09
echo.
echo  +==================================================================+
echo  ^|  ACCOUNT DETAILS: !uTarget!
echo  +==================================================================+
echo.
net user "!uTarget!" 2>nul
echo.
pause
goto MENU

:PWISSUES
cls
color 0C
echo.
echo  +==================================================================+
echo  ^|  ACCOUNTS WITH PASSWORD ISSUES                                   ^|
echo  +==================================================================+
echo.
echo  Checking for accounts with no password requirement...
echo.

set "found=0"
for /f "tokens=1" %%u in ('net user 2^>nul ^| findstr /v "command\|User accounts\|---\|The command"') do (
    set "uname=%%u"
    if not "!uname!"=="" if not "!uname!"=="The" (
        for /f "tokens=4" %%a in ('net user "!uname!" 2^>nul ^| findstr /i "Password required"') do (
            if /i "%%a"=="No" (
                echo  [NO PASSWORD]  !uname!
                set "found=1"
            )
        )
        for /f "tokens=3,4,5" %%a in ('net user "!uname!" 2^>nul ^| findstr /i "Password expires"') do (
            if /i "%%a"=="The" (
                echo  [PASSWORD EXPIRED]  !uname!
                set "found=1"
            )
        )
    )
)

if !found!==0 (
    color 0B
    echo  [OK] No accounts with password issues found.
)

echo.
echo  +------------------------------------------------------------------+
echo  Tip: To set a password for an account, run:
echo    net user ^<username^> ^<newpassword^>
echo  Or use: Control Panel ^> User Accounts
echo.
pause
goto MENU

:EXPORTREPORT
cls
color 09
echo.
echo  Generating account audit report...
set "rpt=%USERPROFILE%\Desktop\AccountAudit_Report.txt"
(
echo ================================================================
echo   ACCOUNT AUDITOR REPORT
echo   Generated : %DATE% %TIME%
echo   Computer  : %COMPUTERNAME%
echo ================================================================
echo.
echo [ALL USER ACCOUNTS]
net user
echo.
echo [ADMINISTRATOR GROUP]
net localgroup administrators
echo.
echo [DETAILED ACCOUNT INFO]
for /f "tokens=1" %%u in ('net user 2^>nul ^| findstr /v "command\|User accounts\|---\|The"') do (
    if not "%%u"=="" (
        echo ---- %%u ----
        net user %%u
        echo.
    )
)
echo.
echo ================================================================
echo   END OF REPORT
echo ================================================================
) > "%rpt%" 2>nul

if exist "%rpt%" (
    color 0B
    echo  [OK] Report saved to Desktop as AccountAudit_Report.txt
) else (
    echo  [ERROR] Could not write report.
)
echo.
pause
goto MENU

:EXIT
exit
