@echo off
:: ============================================================
:: Name      : SystemInfo.bat
:: Version   : 4.0.0
:: Author    : Anamicca23
:: Tested    : Windows 10 22H2, Windows 11 23H2
:: Min OS    : Windows 10 1803
:: Risk      : LOW
:: Admin     : Required
:: Reversible: Yes
:: Desc      : Full interactive analytics dashboard — CPU, RAM, GPU,
::             Disk, Battery, Network, Processes, Startup, License,
::             Security — with live ASCII bar charts.
:: ============================================================
setlocal enabledelayedexpansion
title SYSTEM ANALYTICS DASHBOARD v4.0
mode con: cols=120 lines=55
if not "%1"=="RUN" start /MAX cmd /k "%~f0" RUN & exit

net session >nul 2>&1
if %errorlevel% neq 0 (
    color 0C & cls
    echo.
    echo  [WARNING] Not running as Administrator.
    echo  Right-click this file and choose "Run as administrator".
    echo.
    timeout /t 4 >nul
)
color 0A
goto :MENU

:WGet
for /f "tokens=1* delims==" %%K in ('%~1 2^>nul ^| findstr /i "^%~2="') do (
    set "_v=%%L" & set "_v=!_v: =!"
    if not "!_v!"=="" set "%~3=!_v!"
)
exit /b

:WGetFull
for /f "tokens=1* delims==" %%K in ('%~1 2^>nul ^| findstr /i "^%~2="') do (
    set "_vf=%%L"
    if defined _vf ( set "_vf=!_vf:~0,80!" & set "%~3=!_vf!" )
)
exit /b

:Pad
set "_P=%~1                                                                        "
set "_P=!_P:~0,%~2!"
exit /b

:Bar
set /a "_bf=%~1 * %~2 / 100" 2>nul
if not defined _bf set "_bf=0"
if !_bf! lss 0 set "_bf=0"
if !_bf! gtr %~2 set "_bf=%~2"
set "_B="
for /l %%i in (1,1,%~2) do (
    if %%i leq !_bf! (set "_B=!_B!#") else (set "_B=!_B!.")
)
exit /b

:MENU
cls
color 0A
echo.
echo  +==============================================================================+
echo  ^|   SYSTEM ANALYTICS DASHBOARD v4.0                                           ^|
echo  ^|   PC: %COMPUTERNAME%   User: %USERNAME%   %DATE%   %TIME%
echo  +==============================================================================+
echo  ^|                                                                              ^|
echo  ^|   [1]  System Overview       [8]  Running Processes                         ^|
echo  ^|   [2]  CPU Analytics         [9]  Startup Programs                          ^|
echo  ^|   [3]  Memory Analytics     [10]  Windows License                           ^|
echo  ^|   [4]  Storage Analytics    [11]  Security Status                           ^|
echo  ^|   [5]  GPU and Display      [12]  Installed Software                        ^|
echo  ^|   [6]  Network Dashboard    [13]  Environment Variables                     ^|
echo  ^|   [7]  Battery Health       [14]  Full Report to Desktop                    ^|
echo  ^|                             [ 0]  Exit                                      ^|
echo  ^|                                                                              ^|
echo  +==============================================================================+
echo.
set "choice="
set /p choice=    Enter Option: 
if "%choice%"=="1"  goto OVERVIEW
if "%choice%"=="2"  goto CPU
if "%choice%"=="3"  goto RAM
if "%choice%"=="4"  goto DISK
if "%choice%"=="5"  goto GPU
if "%choice%"=="6"  goto NETWORK
if "%choice%"=="7"  goto BATTERY
if "%choice%"=="8"  goto PROCESSES
if "%choice%"=="9"  goto STARTUP
if "%choice%"=="10" goto LICENSE
if "%choice%"=="11" goto SECURITY
if "%choice%"=="12" goto SOFTWARE
if "%choice%"=="13" goto ENVVARS
if "%choice%"=="14" goto FULLREPORT
if "%choice%"=="0"  goto EXIT
timeout /t 1 >nul
goto MENU

:OVERVIEW
cls
color 0B
set "vMaker=[N/A]" & set "vModel=[N/A]" & set "vOS=[N/A]" & set "vBuild=[N/A]"
set "vArch=[N/A]"  & set "vCPU=[N/A]"   & set "vCores=[N/A]" & set "vThr=[N/A]"
set "vMHz=[N/A]"   & set "vLoad=0"      & set "vRAMkb=1"     & set "vRAMfkb=0"
set "vCharge=0"    & set "vBStat=0"

call :WGetFull "wmic computersystem get Manufacturer /value" "Manufacturer" vMaker
call :WGetFull "wmic computersystem get Model /value"        "Model"        vModel
call :WGetFull "wmic os get Caption /value"                  "Caption"      vOS
call :WGet     "wmic os get BuildNumber /value"              "BuildNumber"  vBuild
call :WGet     "wmic os get OSArchitecture /value"           "OSArchitecture" vArch
call :WGetFull "wmic cpu get Name /value"                    "Name"         vCPU
call :WGet     "wmic cpu get NumberOfCores /value"           "NumberOfCores" vCores
call :WGet     "wmic cpu get NumberOfLogicalProcessors /value" "NumberOfLogicalProcessors" vThr
call :WGet     "wmic cpu get MaxClockSpeed /value"           "MaxClockSpeed" vMHz
call :WGet     "wmic cpu get LoadPercentage /value"          "LoadPercentage" vLoad
call :WGet     "wmic os get TotalVisibleMemorySize /value"   "TotalVisibleMemorySize" vRAMkb
call :WGet     "wmic os get FreePhysicalMemory /value"       "FreePhysicalMemory" vRAMfkb
call :WGet     "wmic path Win32_Battery get EstimatedChargeRemaining /value" "EstimatedChargeRemaining" vCharge
call :WGet     "wmic path Win32_Battery get BatteryStatus /value" "BatteryStatus" vBStat

if !vRAMkb! lss 1 set "vRAMkb=1"
set /a rMB=vRAMkb/1024  & set /a rFMB=vRAMfkb/1024 & set /a rUMB=rMB-rFMB
set /a rGB=rMB/1024     & set /a rFGB=rFMB/1024     & set /a rUGB=rUMB/1024
set /a rPCT=rUMB*100/rMB

set "cSZ=N/A" & set "cFR=N/A" & set "cUS=N/A" & set "cPCT=0" & set "cSZb=" & set "cFRb="
call :WGet "wmic logicaldisk where Caption='C:' get Size /value"      "Size"      cSZb
call :WGet "wmic logicaldisk where Caption='C:' get FreeSpace /value" "FreeSpace" cFRb
if defined cSZb if not "!cSZb!"=="" if not "!cSZb!"=="0" (
    if "!cSZb:~9,1!"=="" (set "cSZ=0") else (set "cSZ=!cSZb:~0,-9!")
    if "!cFRb:~9,1!"=="" (set "cFR=0") else (set "cFR=!cFRb:~0,-9!")
    if "!cSZ!"=="" set "cSZ=0"  & if "!cFR!"=="" set "cFR=0"
    set /a cUS=cSZ-cFR
    if !cSZ! gtr 0 (set /a cPCT=cUS*100/cSZ) else (set "cPCT=0")
)

set "vBDesc=Not Detected"
if "!vBStat!"=="1" set "vBDesc=Discharging"
if "!vBStat!"=="2" set "vBDesc=On AC Power"
if "!vBStat!"=="3" set "vBDesc=Fully Charged"
if "!vBStat!"=="6" set "vBDesc=Charging"

call :Bar !vLoad! 20  & set "bCPU=!_B!"
call :Bar !rPCT!  20  & set "bRAM=!_B!"
call :Bar !cPCT!  20  & set "bC=!_B!"
call :Bar !vCharge! 20 & set "bBAT=!_B!"

call :Pad "Make  : !vMaker!"                  36 & set "A1=!_P!"
call :Pad "Model : !vModel!"                  36 & set "A2=!_P!"
call :Pad "OS    : !vOS!"                     36 & set "A3=!_P!"
call :Pad "Build : !vBuild! (!vArch!)"        36 & set "A4=!_P!"
call :Pad "CPU   : !vCPU!"                    36 & set "B1=!_P!"
call :Pad "Cores : !vCores!  Threads:!vThr!"  36 & set "B2=!_P!"
call :Pad "Speed : !vMHz! MHz"                36 & set "B3=!_P!"
call :Pad "Load  : [!bCPU!] !vLoad!%%"        36 & set "B4=!_P!"
call :Pad "Total : !rGB! GB  (!rMB! MB)"      36 & set "C1=!_P!"
call :Pad "Used  : !rUGB! GB  (!rUMB! MB)"    36 & set "C2=!_P!"
call :Pad "Free  : !rFGB! GB  (!rFMB! MB)"    36 & set "C3=!_P!"
call :Pad "[!bRAM!] !rPCT!%% used"           36 & set "C4=!_P!"
call :Pad "C: Total : !cSZ! GB"               36 & set "D1=!_P!"
call :Pad "C: Used  : !cUS! GB (!cPCT!%%)"    36 & set "D2=!_P!"
call :Pad "C: Free  : !cFR! GB"               36 & set "D3=!_P!"
call :Pad "[!bC!] !cPCT!%% used"             36 & set "D4=!_P!"
call :Pad "Charge  : !vCharge!%%"             36 & set "E1=!_P!"
call :Pad "[!bBAT!] !vCharge!%%"             36 & set "E2=!_P!"
call :Pad "Status  : !vBDesc!"                36 & set "E3=!_P!"
call :Pad ""                                  36 & set "E4=!_P!"

echo.
echo  +======================================+======================================+======================================+
echo  ^| MACHINE                              ^| PROCESSOR                            ^| MEMORY                               ^|
echo  +--------------------------------------+--------------------------------------+--------------------------------------+
echo  ^| !A1! ^| !B1! ^| !C1! ^|
echo  ^| !A2! ^| !B2! ^| !C2! ^|
echo  ^| !A3! ^| !B3! ^| !C3! ^|
echo  ^| !A4! ^| !B4! ^| !C4! ^|
echo  +======================================+======================================+======================================+
echo  ^| DISK  C:                             ^| BATTERY                              ^|                                      ^|
echo  +--------------------------------------+--------------------------------------+--------------------------------------+
echo  ^| !D1! ^| !E1! ^|                                      ^|
echo  ^| !D2! ^| !E2! ^|                                      ^|
echo  ^| !D3! ^| !E3! ^|                                      ^|
echo  ^| !D4! ^| !E4! ^|                                      ^|
echo  +======================================+======================================+======================================+
echo.
echo  Uptime:
net stats workstation 2>nul ^| findstr "Statistics since"
echo.
pause
goto MENU

:CPU
cls
color 0E
set "cName=[N/A]" & set "cMake=[N/A]" & set "cCores=[N/A]" & set "cThr=[N/A]"
set "cMaxMHz=[N/A]" & set "cCurMHz=[N/A]" & set "cLoad=0" & set "cL2=[N/A]" & set "cL3=[N/A]"
call :WGetFull "wmic cpu get Name /value"                       "Name"                      cName
call :WGet     "wmic cpu get Manufacturer /value"               "Manufacturer"              cMake
call :WGet     "wmic cpu get NumberOfCores /value"              "NumberOfCores"             cCores
call :WGet     "wmic cpu get NumberOfLogicalProcessors /value"  "NumberOfLogicalProcessors" cThr
call :WGet     "wmic cpu get MaxClockSpeed /value"              "MaxClockSpeed"             cMaxMHz
call :WGet     "wmic cpu get CurrentClockSpeed /value"          "CurrentClockSpeed"         cCurMHz
call :WGet     "wmic cpu get LoadPercentage /value"             "LoadPercentage"            cLoad
call :WGet     "wmic cpu get L2CacheSize /value"                "L2CacheSize"               cL2
call :WGet     "wmic cpu get L3CacheSize /value"                "L3CacheSize"               cL3
call :Bar !cLoad! 30 & set "loadBar=!_B!"
set "cStat=[ LOW    ]  Mostly idle"
if !cLoad! geq 30 set "cStat=[ MEDIUM ]  Normal workload"
if !cLoad! geq 70 set "cStat=[ HIGH   ]  Heavy load"
if !cLoad! geq 90 set "cStat=[ CRIT   ]  Near maximum"
set "cmap=" & set "tmap="
set /a cshow=cCores & if !cshow! gtr 16 set "cshow=16" & if !cshow! lss 0 set "cshow=0"
set /a tshow=cThr   & if !tshow! gtr 16 set "tshow=16" & if !tshow! lss 0 set "tshow=0"
for /l %%i in (1,1,!cshow!) do set "cmap=!cmap![C]"
for /l %%i in (1,1,!tshow!) do set "tmap=!tmap![T]"
echo.
echo  +==================================================================================+
echo  ^|                     CPU  ANALYTICS                                               ^|
echo  +==================================================================================+
echo  ^|  Name       : !cName!
echo  ^|  Maker      : !cMake!
echo  ^|  Max Speed  : !cMaxMHz! MHz      Current : !cCurMHz! MHz
echo  ^|  Cores      : !cCores!           Threads : !cThr!
echo  ^|  L2 Cache   : !cL2! KB           L3 Cache: !cL3! KB
echo  +----------------------------------------------------------------------------------+
echo  ^|  LOAD METER
echo  +----------------------------------------------------------------------------------+
echo  ^|  [!loadBar!] !cLoad!%%
echo  ^|  State : !cStat!
echo  +----------------------------------------------------------------------------------+
echo  ^|  CORE MAP  (C=Core  T=Thread)
echo  +----------------------------------------------------------------------------------+
echo  ^|  Cores  : !cmap!
echo  ^|  Threads: !tmap!
echo  +==================================================================================+
echo.
pause
goto MENU

:RAM
cls
color 0D
set "rTkb=1" & set "rFkb=0" & set "rVTkb=0" & set "rVFkb=0"
call :WGet "wmic os get TotalVisibleMemorySize /value"  "TotalVisibleMemorySize" rTkb
call :WGet "wmic os get FreePhysicalMemory /value"      "FreePhysicalMemory"     rFkb
call :WGet "wmic os get TotalVirtualMemorySize /value"  "TotalVirtualMemorySize" rVTkb
call :WGet "wmic os get FreeVirtualMemory /value"       "FreeVirtualMemory"      rVFkb
if !rTkb! lss 1 set "rTkb=1"
set /a rTMB=rTkb/1024   & set /a rFMB=rFkb/1024   & set /a rUMB=rTMB-rFMB
set /a rTGB=rTMB/1024   & set /a rFGB=rFMB/1024   & set /a rUGB=rUMB/1024
set /a rPCT=rUMB*100/rTMB & set /a rFPCT=100-rPCT
call :Bar !rPCT! 30 & set "rBar=!_B!"
set "rStat=[ HEALTHY  ]  Plenty available"
if !rPCT! geq 50 set "rStat=[ MODERATE ]  Usage moderate"
if !rPCT! geq 80 set "rStat=[ HIGH     ]  Usage high"
if !rPCT! geq 95 set "rStat=[ CRITICAL ]  Nearly full"
echo.
echo  +==================================================================================+
echo  ^|                     MEMORY  ANALYTICS                                            ^|
echo  +==================================================================================+
echo  ^|  Physical RAM
echo  +----------------------------------------------------------------------------------+
echo  ^|  Total  : !rTGB! GB  (!rTMB! MB)
echo  ^|  Used   : !rUGB! GB  (!rUMB! MB)
echo  ^|  Free   : !rFGB! GB  (!rFMB! MB)
echo  +----------------------------------------------------------------------------------+
echo  ^|  USAGE METER
echo  +----------------------------------------------------------------------------------+
echo  ^|  [!rBar!] !rPCT!%% used  /  !rFPCT!%% free
echo  ^|  State : !rStat!
echo  +----------------------------------------------------------------------------------+
echo  ^|  INSTALLED MODULES
echo  +----------------------------------------------------------------------------------+
wmic memorychip get BankLabel,Capacity,Speed,Manufacturer 2>nul
echo  +==================================================================================+
echo.
pause
goto MENU

:DISK
cls
color 06
echo.
echo  +==================================================================================+
echo  ^|                     STORAGE  ANALYTICS                                           ^|
echo  +==================================================================================+
echo  ^|  PHYSICAL DRIVES
echo  +----------------------------------------------------------------------------------+
wmic diskdrive get Model,MediaType,Size,Status 2>nul
echo  +----------------------------------------------------------------------------------+
echo  ^|  DRIVE TABLE  (GB = bytes / 10^9)
echo  +----------------------------------------------------------------------------------+
echo  ^|   Drive    Total GB    Free GB     Used GB    Used%%   Health
echo  +----------------------------------------------------------------------------------+
for /f "tokens=1* delims==" %%a in ('wmic logicaldisk get Caption /value 2^>nul ^| findstr /i "^Caption="') do (
    set "drv=%%b" & set "drv=!drv: =!"
    if defined drv if not "!drv!"=="" (
        set "dSZb=" & set "dFRb="
        for /f "tokens=1* delims==" %%x in ('wmic logicaldisk where "Caption='!drv!'" get Size,FreeSpace /value 2^>nul ^| findstr "="') do (
            if /i "%%x"=="Size"      set "dSZb=%%y"
            if /i "%%x"=="FreeSpace" set "dFRb=%%y"
        )
        set "dSZb=!dSZb: =!" & set "dFRb=!dFRb: =!"
        set "dSZ=N/A" & set "dFR=N/A" & set "dUS=N/A" & set "dPCT=0" & set "dHlth=N/A"
        if defined dSZb if not "!dSZb!"=="" if not "!dSZb!"=="0" (
            if "!dSZb:~9,1!"=="" (set "dSZ=0") else (set "dSZ=!dSZb:~0,-9!")
            if "!dFRb:~9,1!"=="" (set "dFR=0") else (set "dFR=!dFRb:~0,-9!")
            if "!dSZ!"=="" set "dSZ=0" & if "!dFR!"=="" set "dFR=0"
            set /a dUS=dSZ-dFR
            if !dSZ! gtr 0 (set /a dPCT=dUS*100/dSZ) else (set "dPCT=0")
            set "dHlth=OK"
            if !dPCT! geq 80 set "dHlth=WARN"
            if !dPCT! geq 95 set "dHlth=CRIT"
            echo  ^|   !drv!       !dSZ!           !dFR!          !dUS!         !dPCT!%%      !dHlth!
        )
    )
)
echo  +----------------------------------------------------------------------------------+
echo  ^|  VISUAL BARS  (# = used   . = free)
echo  +----------------------------------------------------------------------------------+
for /f "tokens=1* delims==" %%a in ('wmic logicaldisk get Caption /value 2^>nul ^| findstr /i "^Caption="') do (
    set "drv=%%b" & set "drv=!drv: =!"
    if defined drv if not "!drv!"=="" (
        set "dSZb=" & set "dFRb="
        for /f "tokens=1* delims==" %%x in ('wmic logicaldisk where "Caption='!drv!'" get Size,FreeSpace /value 2^>nul ^| findstr "="') do (
            if /i "%%x"=="Size"      set "dSZb=%%y"
            if /i "%%x"=="FreeSpace" set "dFRb=%%y"
        )
        set "dSZb=!dSZb: =!" & set "dFRb=!dFRb: =!"
        if defined dSZb if not "!dSZb!"=="" if not "!dSZb!"=="0" (
            if "!dSZb:~9,1!"=="" (set "dSZ=0") else (set "dSZ=!dSZb:~0,-9!")
            if "!dFRb:~9,1!"=="" (set "dFR=0") else (set "dFR=!dFRb:~0,-9!")
            if "!dSZ!"=="" set "dSZ=0" & if "!dFR!"=="" set "dFR=0"
            set /a dUS=dSZ-dFR
            if !dSZ! gtr 0 (set /a dPCT=dUS*100/dSZ) else (set "dPCT=0")
            call :Bar !dPCT! 30
            echo  ^|  !drv!  [!_B!] !dPCT!%%   Used:!dUS!GB  Free:!dFR!GB  Total:!dSZ!GB
        )
    )
)
echo  +==================================================================================+
echo.
pause
goto MENU

:GPU
cls
color 09
set "gName=[N/A]" & set "gRAMb=0" & set "gDrv=[N/A]" & set "gRW=[N/A]" & set "gRH=[N/A]" & set "gHz=[N/A]" & set "gBPP=[N/A]"
call :WGetFull "wmic path win32_VideoController get Name /value"                        "Name"                        gName
call :WGet     "wmic path win32_VideoController get AdapterRAM /value"                  "AdapterRAM"                  gRAMb
call :WGetFull "wmic path win32_VideoController get DriverVersion /value"               "DriverVersion"               gDrv
call :WGet     "wmic path win32_VideoController get CurrentHorizontalResolution /value" "CurrentHorizontalResolution" gRW
call :WGet     "wmic path win32_VideoController get CurrentVerticalResolution /value"   "CurrentVerticalResolution"   gRH
call :WGet     "wmic path win32_VideoController get CurrentRefreshRate /value"          "CurrentRefreshRate"          gHz
call :WGet     "wmic path win32_VideoController get CurrentBitsPerPixel /value"         "CurrentBitsPerPixel"         gBPP
set "gVRAMGB=N/A" & set "gVRAMMB=N/A"
if defined gRAMb if not "!gRAMb!"=="0" if not "!gRAMb!"=="[N/A]" (
    if "!gRAMb:~9,1!"=="" (set "gVRAMGB=0") else (set "gVRAMGB=!gRAMb:~0,-9!")
    if "!gVRAMGB!"=="" set "gVRAMGB=0"
    set /a gVRAMMB=gVRAMGB*1024
)
echo.
echo  +==================================================================================+
echo  ^|                     GPU  AND  DISPLAY                                            ^|
echo  +==================================================================================+
echo  ^|  Name       : !gName!
echo  ^|  VRAM       : !gVRAMGB! GB  (!gVRAMMB! MB)
echo  ^|  Driver     : !gDrv!
echo  +----------------------------------------------------------------------------------+
echo  ^|  Resolution : !gRW! x !gRH!   Refresh : !gHz! Hz   Bit Depth : !gBPP! bpp
echo  +----------------------------------------------------------------------------------+
echo  ^|  All GPU adapters:
wmic path win32_VideoController get Name,AdapterRAM,DriverVersion 2>nul
echo  +==================================================================================+
echo.
pause
goto MENU

:NETWORK
cls
color 0B
echo.
echo  +==================================================================================+
echo  ^|                     NETWORK  DASHBOARD                                           ^|
echo  +==================================================================================+
echo  ^|  IP ADDRESSES
echo  +----------------------------------------------------------------------------------+
ipconfig ^| findstr /i "Adapter Wireless Ethernet IPv4 IPv6 Subnet Gateway"
echo  +----------------------------------------------------------------------------------+
echo  ^|  DNS SERVERS
echo  +----------------------------------------------------------------------------------+
ipconfig /all ^| findstr /i "DNS Servers"
echo  +----------------------------------------------------------------------------------+
echo  ^|  ESTABLISHED CONNECTIONS
echo  +----------------------------------------------------------------------------------+
netstat -an ^| findstr "ESTABLISHED"
echo  +----------------------------------------------------------------------------------+
echo  ^|  SAVED WIFI PROFILES
echo  +----------------------------------------------------------------------------------+
netsh wlan show profiles 2>nul ^| findstr "Profile"
echo  +----------------------------------------------------------------------------------+
echo  ^|  PING TEST  (Google 8.8.8.8)
echo  +----------------------------------------------------------------------------------+
ping -n 3 8.8.8.8 ^| findstr /i "Reply time ms loss"
echo  +==================================================================================+
echo.
pause
goto MENU

:BATTERY
cls
color 0E
set "bChg=0" & set "bStat=0" & set "bFull=[N/A]" & set "bDes=[N/A]" & set "bRun=[N/A]"
call :WGet "wmic path Win32_Battery get EstimatedChargeRemaining /value" "EstimatedChargeRemaining" bChg
call :WGet "wmic path Win32_Battery get BatteryStatus /value"            "BatteryStatus"            bStat
call :WGet "wmic path Win32_Battery get FullChargeCapacity /value"       "FullChargeCapacity"       bFull
call :WGet "wmic path Win32_Battery get DesignCapacity /value"           "DesignCapacity"           bDes
call :WGet "wmic path Win32_Battery get EstimatedRunTime /value"         "EstimatedRunTime"         bRun
set "bDesc=Not Detected"
if "!bStat!"=="1" set "bDesc=Discharging (on battery)"
if "!bStat!"=="2" set "bDesc=On AC Power (plugged in)"
if "!bStat!"=="3" set "bDesc=Fully Charged"
if "!bStat!"=="6" set "bDesc=Charging"
set "bHlth=Not Detected"
if !bChg! gtr 0 (
    set "bHlth=GOOD"
    if !bChg! leq 60 set "bHlth=MEDIUM - charge soon"
    if !bChg! leq 20 set "bHlth=LOW - plug in now"
)
call :Bar !bChg! 30 & set "bBar=!_B!"
echo.
echo  +==================================================================================+
echo  ^|                     BATTERY  HEALTH  DASHBOARD                                   ^|
echo  +==================================================================================+
echo  ^|  Charge Remaining  : !bChg!%%
echo  ^|  Status            : !bStat!   (!bDesc!)
echo  ^|  Est. Runtime      : !bRun! minutes
echo  ^|  Full Charge Cap   : !bFull! mWh
echo  ^|  Design Capacity   : !bDes! mWh
echo  +----------------------------------------------------------------------------------+
echo  ^|  [!bBar!] !bChg!%%
echo  ^|  Health : !bHlth!
echo  +==================================================================================+
echo.
powercfg /batteryreport /output "%USERPROFILE%\Desktop\battery_report.html" >nul 2>&1
if exist "%USERPROFILE%\Desktop\battery_report.html" echo  [OK] Battery report saved to Desktop as battery_report.html
powercfg /getactivescheme 2>nul
echo.
pause
goto MENU

:PROCESSES
cls
color 0C
echo.
echo  +==================================================================================+
echo  ^|                     RUNNING  PROCESSES                                           ^|
echo  +==================================================================================+
tasklist /fo table
echo.
echo  +==================================================================================+
echo  ^|                     ACTIVE  SERVICES                                             ^|
echo  +==================================================================================+
net start
echo.
pause
goto MENU

:STARTUP
cls
color 0D
echo.
echo  +==================================================================================+
echo  ^|                     STARTUP  PROGRAMS                                            ^|
echo  +==================================================================================+
echo  ^|  CURRENT USER (HKCU)
echo  +----------------------------------------------------------------------------------+
reg query "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" 2>nul
echo.
echo  +----------------------------------------------------------------------------------+
echo  ^|  ALL USERS (HKLM)
echo  +----------------------------------------------------------------------------------+
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" 2>nul
echo.
echo  +----------------------------------------------------------------------------------+
echo  ^|  SCHEDULED TASKS
echo  +----------------------------------------------------------------------------------+
schtasks /query /fo list 2>nul ^| findstr "TaskName:"
echo  +==================================================================================+
echo.
pause
goto MENU

:LICENSE
cls
color 0F
set "lOS=[N/A]" & set "lVer=[N/A]" & set "lBuild=[N/A]" & set "lSerial=[N/A]" & set "lDate=[N/A]"
call :WGetFull "wmic os get Caption /value"       "Caption"      lOS
call :WGet     "wmic os get Version /value"       "Version"      lVer
call :WGet     "wmic os get BuildNumber /value"   "BuildNumber"  lBuild
call :WGet     "wmic os get SerialNumber /value"  "SerialNumber" lSerial
call :WGet     "wmic os get InstallDate /value"   "InstallDate"  lDate
echo.
echo  +==================================================================================+
echo  ^|                     WINDOWS  LICENSE                                             ^|
echo  +==================================================================================+
echo  ^|  OS           : !lOS!
echo  ^|  Version      : !lVer!
echo  ^|  Build        : !lBuild!
echo  ^|  Serial       : !lSerial!
echo  ^|  Install Date : !lDate!
echo  +----------------------------------------------------------------------------------+
slmgr /xpr
echo  +----------------------------------------------------------------------------------+
wmic path softwarelicensingservice get OA3xOriginalProductKey 2>nul
echo  +==================================================================================+
echo.
pause
goto MENU

:SECURITY
cls
color 0C
echo.
echo  +==================================================================================+
echo  ^|                     SECURITY  STATUS                                             ^|
echo  +==================================================================================+
echo  ^|  FIREWALL
echo  +----------------------------------------------------------------------------------+
netsh advfirewall show allprofiles state 2>nul
echo  +----------------------------------------------------------------------------------+
echo  ^|  WINDOWS DEFENDER
echo  +----------------------------------------------------------------------------------+
sc query WinDefend 2>nul ^| findstr "STATE"
wmic /namespace:\\root\SecurityCenter2 path AntiVirusProduct get displayName,productState 2>nul
echo  +----------------------------------------------------------------------------------+
echo  ^|  USER ACCOUNTS
echo  +----------------------------------------------------------------------------------+
net user 2>nul
echo  +----------------------------------------------------------------------------------+
echo  ^|  LISTENING PORTS
echo  +----------------------------------------------------------------------------------+
netstat -an ^| findstr "LISTENING"
echo  +==================================================================================+
echo.
pause
goto MENU

:SOFTWARE
cls
color 0B
echo.
echo  +==================================================================================+
echo  ^|                     INSTALLED  SOFTWARE                                          ^|
echo  +==================================================================================+
echo  Please wait...
echo.
echo  64-BIT APPLICATIONS:
echo  +----------------------------------------------------------------------------------+
for /f "tokens=2* skip=2" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s /v "DisplayName" 2^>nul') do (
    if not "%%b"=="" echo    %%b
)
echo.
echo  32-BIT APPLICATIONS:
echo  +----------------------------------------------------------------------------------+
for /f "tokens=2* skip=2" %%a in ('reg query "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" /s /v "DisplayName" 2^>nul') do (
    if not "%%b"=="" echo    %%b
)
echo  +==================================================================================+
echo.
pause
goto MENU

:ENVVARS
cls
color 07
echo.
echo  +==================================================================================+
echo  ^|                     ENVIRONMENT  VARIABLES                                       ^|
echo  +==================================================================================+
echo  ^|  USERNAME     = %USERNAME%
echo  ^|  COMPUTERNAME = %COMPUTERNAME%
echo  ^|  USERPROFILE  = %USERPROFILE%
echo  ^|  SystemRoot   = %SystemRoot%
echo  ^|  TEMP         = %TEMP%
echo  ^|  OS           = %OS%
echo  ^|  PROCESSOR    = %PROCESSOR_ARCHITECTURE%
echo  ^|  CPU COUNT    = %NUMBER_OF_PROCESSORS%
echo  +----------------------------------------------------------------------------------+
cmd /c set
echo  +==================================================================================+
echo.
pause
goto MENU

:FULLREPORT
cls
color 0A
echo.
echo  Generating full report - please wait...
set "rpt=%USERPROFILE%\Desktop\SystemReport.txt"
(
echo SYSTEM ANALYTICS FULL REPORT
echo Date: %DATE%   Time: %TIME%
echo User: %USERNAME%   PC: %COMPUTERNAME%
echo.
echo [OS]
wmic os get Caption,Version,BuildNumber,OSArchitecture /value
echo [CPU]
wmic cpu get Name,NumberOfCores,NumberOfLogicalProcessors,MaxClockSpeed,LoadPercentage /value
echo [MEMORY]
wmic os get TotalVisibleMemorySize,FreePhysicalMemory /value
echo [DISK]
wmic logicaldisk get Caption,FileSystem,Size,FreeSpace /value
echo [GPU]
wmic path win32_VideoController get Name,AdapterRAM,DriverVersion /value
echo [NETWORK]
ipconfig /all
echo [BATTERY]
wmic path Win32_Battery get EstimatedChargeRemaining,BatteryStatus,FullChargeCapacity /value
echo [PROCESSES]
tasklist
) > "%rpt%" 2>nul
if exist "%rpt%" (
    color 0B
    echo  [DONE] Report saved to Desktop as SystemReport.txt
) else (
    echo  [ERROR] Could not write. Run as Administrator.
)
echo.
pause
goto MENU

:EXIT
cls
color 0A
echo.
echo  Thank you for using System Analytics Dashboard!
echo.
timeout /t 2 >nul
exit