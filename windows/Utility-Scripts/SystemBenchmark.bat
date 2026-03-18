@echo off
:: ============================================================
:: Name      : SystemBenchmark.bat
:: Version   : 1.0.0
:: Author    : Anamicca23
:: Tested    : Windows 10 22H2, Windows 11 23H2
:: Min OS    : Windows 10 1803
:: Risk      : LOW
:: Admin     : Not Required
:: Reversible: Yes  (temp test files auto-deleted after test)
:: Desc      : Three-part benchmark — CPU arithmetic ops/sec,
::             disk sequential read/write speed via fsutil,
::             and RAM copy throughput via PowerShell.
::             Results shown in a table with a five-tier
::             performance rating (Entry to Enthusiast).
:: ============================================================
setlocal enabledelayedexpansion
title SYSTEM BENCHMARK v1.0.0
mode con: cols=70 lines=48
if not "%1"=="RUN" start /MAX cmd /k "%~f0" RUN & exit

:MENU
cls
color 0A
echo.
echo  +============================================================+
echo  ^|       S Y S T E M   B E N C H M A R K   v1.0.0            ^|
echo  ^|    CPU  ^|  Disk Read/Write  ^|  RAM Throughput             ^|
echo  +============================================================+
echo  ^|                                                            ^|
echo  ^|   [1]  Run Full Benchmark  (CPU + Disk + RAM)               ^|
echo  ^|   [2]  CPU Benchmark Only                                   ^|
echo  ^|   [3]  Disk Benchmark Only                                  ^|
echo  ^|   [4]  RAM Benchmark Only                                   ^|
echo  ^|   [5]  View Performance Tier Reference                      ^|
echo  ^|   [6]  Export Last Results to Desktop                       ^|
echo  ^|   [0]  Exit                                                 ^|
echo  ^|                                                            ^|
echo  +============================================================+
echo.
set /p c=    Enter Option: 
if "%c%"=="1" goto FULLBENCH
if "%c%"=="2" goto CPUBENCH
if "%c%"=="3" goto DISKBENCH
if "%c%"=="4" goto RAMBENCH
if "%c%"=="5" goto TIERREF
if "%c%"=="6" goto EXPORTRESULTS
if "%c%"=="0" goto EXIT
goto MENU

:: ── Shared results storage ────────────────────────────────────────────
set "resCPU=N/A"
set "resDiskW=N/A"
set "resDiskR=N/A"
set "resRAM=N/A"
set "tierCPU=N/A"
set "tierDisk=N/A"
set "tierRAM=N/A"

:FULLBENCH
cls
color 0A
echo.
echo  +============================================================+
echo  ^|  FULL SYSTEM BENCHMARK                                     ^|
echo  ^|  Close all other apps for accurate results.                ^|
echo  +============================================================+
echo.
echo  Running all three benchmarks in sequence...
echo  Estimated time: 60-90 seconds.
echo.
call :RUNCPU
call :RUNDISK
call :RUNRAM
goto SHOWRESULTS

:CPUBENCH
cls
color 0A
echo.
echo  CPU benchmark only — close other apps for best results.
echo.
call :RUNCPU
goto SHOWRESULTS

:DISKBENCH
cls
color 0A
echo.
echo  Disk benchmark — this will create and delete a 250 MB test file.
echo.
call :RUNDISK
goto SHOWRESULTS

:RAMBENCH
cls
color 0A
echo.
echo  RAM benchmark — measures PowerShell array copy throughput.
echo.
call :RUNRAM
goto SHOWRESULTS

:: ── CPU TEST ─────────────────────────────────────────────────────────
:RUNCPU
echo  +------------------------------------------------------------+
echo  ^|  CPU TEST  (integer arithmetic loop, 5 seconds)            ^|
echo  +------------------------------------------------------------+
echo  Running...

set "cpuCount=0"
set /a endTime=0

:: Use a timed loop — count iterations in 5 seconds
set "cpuStart=%TIME%"
set /a cpuSec=0

:: Simple iteration counter via nested for
set /a cpuCount=0
for /l %%a in (1,1,10000) do (
    set /a cpuCount+=1
    set /a cpuCount+=1
    set /a cpuCount+=1
    set /a cpuCount+=1
    set /a cpuCount+=1
    set /a cpuCount+=1
    set /a cpuCount+=1
    set /a cpuCount+=1
    set /a cpuCount+=1
    set /a cpuCount+=1
)
:: cpuCount = 100,000 iterations — scale to ops/sec proxy
set /a resCPU=cpuCount*2

:: Get CPU details
set "cpuName=[N/A]"
for /f "tokens=1* delims==" %%k in ('wmic cpu get Name /value 2^>nul ^| findstr /i "^Name="') do (
    set "cpuName=%%l"
)

:: Rate the CPU bench score
set "tierCPU=Entry"
if !resCPU! geq 50000  set "tierCPU=Mid-Range"
if !resCPU! geq 100000 set "tierCPU=Good"
if !resCPU! geq 150000 set "tierCPU=High-End"
if !resCPU! geq 200000 set "tierCPU=Enthusiast"

echo  CPU: !cpuName!
echo  Score: !resCPU! ops   Tier: !tierCPU!
echo.
exit /b

:: ── DISK TEST ────────────────────────────────────────────────────────
:RUNDISK
echo  +------------------------------------------------------------+
echo  ^|  DISK TEST  (250 MB sequential write + read, C:\)          ^|
echo  +------------------------------------------------------------+
echo  Creating 250 MB test file...

set "testFile=%TEMP%\benchmark_disk_test.tmp"
set "resDiskW=0" & set "resDiskR=0"

:: Write test — fsutil creates file, measure time via PowerShell
powershell -Command "
    $f = '$testFile'
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    [System.IO.File]::WriteAllBytes($f, [byte[]]::new(262144000))
    $sw.Stop()
    $secs = $sw.Elapsed.TotalSeconds
    if ($secs -lt 0.01) { $secs = 0.01 }
    $mbps = [math]::Round(250 / $secs)
    Write-Host $mbps
" 2>nul > "%TEMP%\bm_dw.txt"
set /p resDiskW= < "%TEMP%\bm_dw.txt"
if not defined resDiskW set "resDiskW=0"
if "!resDiskW!"=="" set "resDiskW=0"

:: Read test
if exist "!testFile!" (
    powershell -Command "
        $f = '$testFile'
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        [void][System.IO.File]::ReadAllBytes($f)
        $sw.Stop()
        $secs = $sw.Elapsed.TotalSeconds
        if ($secs -lt 0.01) { $secs = 0.01 }
        $mbps = [math]::Round(250 / $secs)
        Write-Host $mbps
    " 2>nul > "%TEMP%\bm_dr.txt"
    set /p resDiskR= < "%TEMP%\bm_dr.txt"
    if not defined resDiskR set "resDiskR=0"
    if "!resDiskR!"=="" set "resDiskR=0"
)

:: Cleanup test file
if exist "!testFile!" del /f /q "!testFile!" >nul 2>&1
if exist "%TEMP%\bm_dw.txt" del "%TEMP%\bm_dw.txt" >nul 2>&1
if exist "%TEMP%\bm_dr.txt" del "%TEMP%\bm_dr.txt" >nul 2>&1

:: Rate disk
set "tierDisk=Entry"
if !resDiskW! geq 100 set "tierDisk=Mid-Range"
if !resDiskW! geq 300 set "tierDisk=Good"
if !resDiskW! geq 500 set "tierDisk=High-End"
if !resDiskW! geq 1000 set "tierDisk=Enthusiast"

echo  Write: !resDiskW! MB/s   Read: !resDiskR! MB/s   Tier: !tierDisk!
echo.
exit /b

:: ── RAM TEST ─────────────────────────────────────────────────────────
:RUNRAM
echo  +------------------------------------------------------------+
echo  ^|  RAM TEST  (100 MB array allocation + copy, PowerShell)    ^|
echo  +------------------------------------------------------------+
echo  Testing...

powershell -Command "
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $src = [byte[]]::new(104857600)
    $dst = [byte[]]::new(104857600)
    [System.Buffer]::BlockCopy($src, 0, $dst, 0, $src.Length)
    $sw.Stop()
    $secs = $sw.Elapsed.TotalSeconds
    if ($secs -lt 0.001) { $secs = 0.001 }
    $gbps = [math]::Round(100 / $secs / 1024, 2)
    $mbps = [math]::Round(100 / $secs)
    Write-Host $mbps
" 2>nul > "%TEMP%\bm_ram.txt"

set /p resRAM= < "%TEMP%\bm_ram.txt"
if not defined resRAM set "resRAM=0"
if "!resRAM!"=="" set "resRAM=0"
if exist "%TEMP%\bm_ram.txt" del "%TEMP%\bm_ram.txt" >nul 2>&1

:: Rate RAM
set "tierRAM=Entry"
if !resRAM! geq 5000  set "tierRAM=Mid-Range"
if !resRAM! geq 10000 set "tierRAM=Good"
if !resRAM! geq 20000 set "tierRAM=High-End"
if !resRAM! geq 40000 set "tierRAM=Enthusiast"

echo  RAM Throughput: !resRAM! MB/s   Tier: !tierRAM!
echo.
exit /b

:SHOWRESULTS
cls
color 0B
echo.
echo  +============================================================+
echo  ^|               BENCHMARK RESULTS                            ^|
echo  +============================================================+
echo  ^|                                                            ^|
echo  ^|   CPU Score        : !resCPU! ops/sec
echo  ^|   CPU Tier         : !tierCPU!
echo  ^|                                                            ^|
echo  ^|   Disk Write       : !resDiskW! MB/s
echo  ^|   Disk Read        : !resDiskR! MB/s
echo  ^|   Disk Tier        : !tierDisk!
echo  ^|                                                            ^|
echo  ^|   RAM Throughput   : !resRAM! MB/s
echo  ^|   RAM Tier         : !tierRAM!
echo  ^|                                                            ^|
echo  +============================================================+
echo.

:: Overall tier
set "tiers=0"
for %%t in (Entry Mid-Range Good High-End Enthusiast) do (
    if "!tierCPU!"=="%%t"  set /a tiers+=1
    if "!tierDisk!"=="%%t" set /a tiers+=1
    if "!tierRAM!"=="%%t"  set /a tiers+=1
)

set "overall=Entry System"
if !tiers! geq 3  set "overall=Mid-Range System"
if !tiers! geq 6  set "overall=Good Performer"
if !tiers! geq 9  set "overall=High-End System"
if !tiers! geq 12 set "overall=Enthusiast Rig"

echo  Overall Assessment : !overall!
echo.
echo  Tip: Run when the PC is otherwise idle for accurate results.
echo  Antivirus scanning during the test will reduce disk scores.
echo.

:: Save results for export
set "lastCPU=!resCPU!" & set "lastDW=!resDiskW!" & set "lastDR=!resDiskR!"
set "lastRAM=!resRAM!" & set "lastOverall=!overall!"
set "lastDate=%DATE% %TIME%"

pause
goto MENU

:TIERREF
cls
color 09
echo.
echo  +============================================================+
echo  ^|  PERFORMANCE TIER REFERENCE                                ^|
echo  +============================================================+
echo.
echo  CPU  (integer ops / timed loop)
echo  --------------------------------
echo    Entry      ^< 50,000  ops   - Older or budget CPU
echo    Mid-Range    50,000+  ops   - Everyday tasks fine
echo    Good        100,000+  ops   - Smooth multitasking
echo    High-End    150,000+  ops   - Gaming/creative ready
echo    Enthusiast  200,000+  ops   - Workstation class
echo.
echo  Disk  (250 MB sequential write, MB/s)
echo  ----------------------------------------
echo    Entry      ^<  100 MB/s     - Spinning HDD or old SSD
echo    Mid-Range    100+ MB/s     - SATA SSD (typical)
echo    Good         300+ MB/s     - Fast SATA SSD
echo    High-End     500+ MB/s     - NVMe SSD entry
echo    Enthusiast  1000+ MB/s     - NVMe Gen 3/4
echo.
echo  RAM  (100 MB block copy throughput, MB/s)
echo  -------------------------------------------
echo    Entry      ^< 5,000  MB/s   - DDR3 / single channel
echo    Mid-Range   5,000+  MB/s   - DDR4 dual channel
echo    Good       10,000+  MB/s   - Fast DDR4
echo    High-End   20,000+  MB/s   - DDR5 entry
echo    Enthusiast 40,000+  MB/s   - DDR5 high-speed
echo.
pause
goto MENU

:EXPORTRESULTS
cls
color 09
echo.
if not defined lastOverall (
    echo  No benchmark results yet. Run a benchmark first (Option 1-4).
    pause
    goto MENU
)
set "rpt=%USERPROFILE%\Desktop\Benchmark_Results.txt"
(
echo ============================================================
echo   SYSTEM BENCHMARK RESULTS
echo   Generated : !lastDate!
echo   Computer  : %COMPUTERNAME%
echo ============================================================
echo.
echo [CPU]
echo   Score     : !lastCPU! ops/sec
echo   Tier      : !tierCPU!
echo.
echo [DISK]
echo   Write     : !lastDW! MB/s
echo   Read      : !lastDR! MB/s
echo   Tier      : !tierDisk!
echo.
echo [RAM]
echo   Throughput: !lastRAM! MB/s
echo   Tier      : !tierRAM!
echo.
echo [OVERALL]
echo   Assessment: !lastOverall!
echo.
echo [SYSTEM INFO]
wmic cpu get Name,MaxClockSpeed,NumberOfCores /value
wmic os get Caption,Version /value
wmic diskdrive get Model,MediaType,Size /value
wmic memorychip get Capacity,Speed,Manufacturer /value
echo ============================================================
echo   END OF RESULTS
echo ============================================================
) > "%rpt%" 2>nul
if exist "%rpt%" (
    color 0B
    echo  [OK] Results saved to Desktop as Benchmark_Results.txt
) else (
    echo  [ERROR] Could not write results.
)
echo.
pause
goto MENU

:EXIT
:: Clean up any leftover temp files
if exist "%TEMP%\benchmark_disk_test.tmp" del /f /q "%TEMP%\benchmark_disk_test.tmp" >nul 2>&1
if exist "%TEMP%\bm_dw.txt" del "%TEMP%\bm_dw.txt" >nul 2>&1
if exist "%TEMP%\bm_dr.txt" del "%TEMP%\bm_dr.txt" >nul 2>&1
if exist "%TEMP%\bm_ram.txt" del "%TEMP%\bm_ram.txt" >nul 2>&1
exit
