@echo off
:: ============================================================
:: Name      : FileOrganizer.bat
:: Version   : 1.0.0
:: Author    : Anamicca23
:: Tested    : Windows 10 22H2, Windows 11 23H2
:: Min OS    : Windows 10 1803
:: Risk      : MEDIUM
:: Admin     : Not Required
:: Reversible: No  (files are moved, not copied)
:: Desc      : Sorts all files in a chosen folder into typed
::             subfolders: Images, Documents, Videos, Music,
::             Archives, Code, and Others — by file extension.
::             Preview mode shows what will move before acting.
:: ============================================================
setlocal enabledelayedexpansion
title FILE ORGANIZER v1.0.0
mode con: cols=70 lines=48
if not "%1"=="RUN" start /MAX cmd /k "%~f0" RUN & exit

:MENU
cls
color 06
echo.
echo  +============================================================+
echo  ^|          F I L E   O R G A N I Z E R   v1.0.0             ^|
echo  ^|      Auto-sort files into folders by type                  ^|
echo  +============================================================+
echo  ^|                                                            ^|
echo  ^|   [1]  Organize Downloads Folder                           ^|
echo  ^|   [2]  Organize Desktop                                    ^|
echo  ^|   [3]  Organize Documents Folder                           ^|
echo  ^|   [4]  Organize a Custom Folder                            ^|
echo  ^|   [5]  Preview Mode  (see what will move, no changes)      ^|
echo  ^|   [6]  Show File Type Mappings                             ^|
echo  ^|   [0]  Exit                                                ^|
echo  ^|                                                            ^|
echo  +============================================================+
echo.
set /p c=    Enter Option: 
if "%c%"=="1" ( set "orgPath=%USERPROFILE%\Downloads" & goto CONFIRMORG )
if "%c%"=="2" ( set "orgPath=%USERPROFILE%\Desktop"   & goto CONFIRMORG )
if "%c%"=="3" ( set "orgPath=%USERPROFILE%\Documents" & goto CONFIRMORG )
if "%c%"=="4" goto CUSTOMPATH
if "%c%"=="5" goto PREVIEWMODE
if "%c%"=="6" goto SHOWMAPPINGS
if "%c%"=="0" goto EXIT
goto MENU

:CUSTOMPATH
cls
color 06
echo.
echo  Enter the full folder path to organize:
echo  Example: C:\Users\%USERNAME%\Pictures
echo.
set /p orgPath=  Folder: 
goto CONFIRMORG

:CONFIRMORG
if not exist "!orgPath!" (
    color 0C
    echo.
    echo  [ERROR] Folder not found: !orgPath!
    pause
    goto MENU
)
cls
color 0E
echo.
echo  +------------------------------------------------------------+
echo  ^|  [WARNING] Files will be MOVED into subfolders.           ^|
echo  ^|  This cannot be automatically undone.                     ^|
echo  ^|  Use Option [5] to preview first.                         ^|
echo  ^|                                                            ^|
echo  ^|  Folder: !orgPath!
echo  +------------------------------------------------------------+
echo.
set /p confirm=  Organize this folder? (Y/N): 
if /i not "%confirm%"=="Y" ( echo  Cancelled. & pause & goto MENU )
set "previewOnly=0"
goto DOORGANIZE

:PREVIEWMODE
cls
color 06
echo.
echo  Enter folder to preview (no changes will be made):
echo  Example: C:\Users\%USERNAME%\Downloads
echo.
set /p orgPath=  Folder: 
if not exist "!orgPath!" (
    color 0C
    echo  [ERROR] Folder not found.
    pause
    goto MENU
)
set "previewOnly=1"
goto DOORGANIZE

:DOORGANIZE
cls
color 06
echo.
if !previewOnly!==1 (
    echo  +============================================================+
    echo  ^|  PREVIEW — No files will be moved                         ^|
    echo  +============================================================+
) else (
    echo  +============================================================+
    echo  ^|  ORGANIZING: !orgPath!
    echo  +============================================================+
)
echo.

set "cntImg=0"  & set "cntDoc=0"  & set "cntVid=0"
set "cntMus=0"  & set "cntArc=0"  & set "cntCod=0"  & set "cntOth=0"
set "cntSkip=0" & set "cntTotal=0"

for %%f in ("!orgPath!\*.*") do (
    set "fname=%%~nxf"
    set "fext=%%~xf"
    set "fext=!fext:~1!"
    set "fext_low=!fext!"

    :: Skip folders, hidden/system files, and desktop.ini
    if "!fname!"=="desktop.ini" goto :nextfile
    if exist "%%f\" goto :nextfile

    set /a cntTotal+=1
    set "destFolder="

    :: ── Images ──────────────────────────────────────────────────
    for %%e in (jpg jpeg png gif bmp webp svg ico tiff tif raw heic heif) do (
        if /i "!fext_low!"=="%%e" set "destFolder=Images"
    )
    :: ── Documents ───────────────────────────────────────────────
    for %%e in (pdf doc docx xls xlsx ppt pptx txt csv md rtf odt ods odp) do (
        if /i "!fext_low!"=="%%e" set "destFolder=Documents"
    )
    :: ── Videos ──────────────────────────────────────────────────
    for %%e in (mp4 mkv avi mov wmv flv m4v webm mpeg mpg 3gp) do (
        if /i "!fext_low!"=="%%e" set "destFolder=Videos"
    )
    :: ── Music ───────────────────────────────────────────────────
    for %%e in (mp3 flac wav aac ogg wma m4a opus aiff) do (
        if /i "!fext_low!"=="%%e" set "destFolder=Music"
    )
    :: ── Archives ────────────────────────────────────────────────
    for %%e in (zip rar 7z tar gz bz2 xz iso dmg cab) do (
        if /i "!fext_low!"=="%%e" set "destFolder=Archives"
    )
    :: ── Code ────────────────────────────────────────────────────
    for %%e in (py js ts html css java cpp c cs php rb go rs sh bat ps1 json xml yaml yml) do (
        if /i "!fext_low!"=="%%e" set "destFolder=Code"
    )

    :: Default to Others
    if not defined destFolder set "destFolder=Others"

    :: Skip if already in correct folder parent
    echo %%f | findstr /i "\\!destFolder!\\" >nul 2>&1
    if not errorlevel 1 (
        set /a cntSkip+=1
        goto :nextfile
    )

    :: Count and optionally move
    if "!destFolder!"=="Images"    set /a cntImg+=1
    if "!destFolder!"=="Documents" set /a cntDoc+=1
    if "!destFolder!"=="Videos"    set /a cntVid+=1
    if "!destFolder!"=="Music"     set /a cntMus+=1
    if "!destFolder!"=="Archives"  set /a cntArc+=1
    if "!destFolder!"=="Code"      set /a cntCod+=1
    if "!destFolder!"=="Others"    set /a cntOth+=1

    if !previewOnly!==1 (
        echo  MOVE: !fname!  -->  !destFolder!\
    ) else (
        if not exist "!orgPath!\!destFolder!" md "!orgPath!\!destFolder!" >nul 2>&1
        move /y "%%f" "!orgPath!\!destFolder!\" >nul 2>&1
    )

    :nextfile
)

echo.
echo  +============================================================+
if !previewOnly!==1 (
    echo  ^|  PREVIEW RESULTS  (no files were moved)                 ^|
) else (
    echo  ^|  ORGANIZATION COMPLETE                                   ^|
)
echo  +============================================================+
echo  ^|                                                            ^|
echo  ^|   Images     : !cntImg! file(s)
echo  ^|   Documents  : !cntDoc! file(s)
echo  ^|   Videos     : !cntVid! file(s)
echo  ^|   Music      : !cntMus! file(s)
echo  ^|   Archives   : !cntArc! file(s)
echo  ^|   Code       : !cntCod! file(s)
echo  ^|   Others     : !cntOth! file(s)
echo  ^|   Skipped    : !cntSkip! file(s)  (already organized)
echo  ^|   Total      : !cntTotal! file(s) scanned
echo  ^|                                                            ^|
echo  +============================================================+
echo.
pause
goto MENU

:SHOWMAPPINGS
cls
color 09
echo.
echo  +============================================================+
echo  ^|  FILE TYPE MAPPINGS                                        ^|
echo  +============================================================+
echo.
echo  Images     : jpg jpeg png gif bmp webp svg ico tiff tif
echo               raw heic heif
echo.
echo  Documents  : pdf doc docx xls xlsx ppt pptx txt csv md
echo               rtf odt ods odp
echo.
echo  Videos     : mp4 mkv avi mov wmv flv m4v webm mpeg mpg 3gp
echo.
echo  Music      : mp3 flac wav aac ogg wma m4a opus aiff
echo.
echo  Archives   : zip rar 7z tar gz bz2 xz iso dmg cab
echo.
echo  Code       : py js ts html css java cpp c cs php rb go rs
echo               sh bat ps1 json xml yaml yml
echo.
echo  Others     : Everything else not listed above
echo.
pause
goto MENU

:EXIT
exit
