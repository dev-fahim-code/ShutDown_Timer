@echo off
setlocal enabledelayedexpansion
title Windows Shutdown Timer PRO - Dev-Fahim-Code

:: ============================================================
::   WINDOWS SHUTDOWN TIMER  -  PRO EDITION   (v2.1)
::   Developed by : Dev-Fahim-Code
::   GitHub       : https://github.com/dev-fahim-code
::
::   Single .bat file. No admin rights needed.
::
::   ACTIONS     : Shutdown, Restart, Sleep, Hibernate, Lock, Log off
::   TIMERS      : 30m / 1h / 2h / 3h presets, flexible custom time
::                 (90, 1h30m, 2:15, 45m ...), or a clock time
::                 (11:30pm, 23:30), repeat last custom time
::   EXTEND      : +15 / +30 / +60 min or custom, without restarting
::   WARNINGS    : popup notification 5 minutes and 1 minute before
::   COUNTDOWN   : real-clock based (no drift, sleep-safe) + progress bar
::   REMEMBERS   : an active timer is recognised when you re-open the
::                 script; settings and last custom time are saved
::   THEMES      : red, green, blue, aqua, yellow, classic
::   SETTINGS    : default action, ask-before-start toggle, force mode,
::                 warning popups, reset to defaults
::   COMMAND LINE: ShutdownTimer.bat 45
::                 ShutdownTimer.bat 1h30m restart
::                 ShutdownTimer.bat at 11:30pm sleep
::                 ShutdownTimer.bat status
::                 ShutdownTimer.bat cancel
::
::   NOTES
::   - Shutdown and Restart are scheduled with Windows itself
::     (shutdown /t), so they happen even if this window is closed.
::   - Sleep, Hibernate, Lock and Log off are run by a small hidden
::     PowerShell helper, which also survives closing this window
::     (but not logging off / rebooting).
::   - Apps are NOT force-closed unless you turn on Force mode in
::     Settings. Without it, Windows may show "an app is preventing
::     shutdown" if something has unsaved work.
::   - Saved data lives in %APPDATA%\DevFahimShutdownTimer
:: ============================================================

set "VERSION=2.1"
if not defined APPDATA set "APPDATA=%TEMP%"
set "DATA=%APPDATA%\DevFahimShutdownTimer"
if not exist "%DATA%" mkdir "%DATA%" >nul 2>&1
set "CORE=%DATA%\core.ps1"
set "SETFILE=%DATA%\settings.cmd"
set "TIMERFILE=%DATA%\timer.cmd"
set "PS=powershell -NoProfile -ExecutionPolicy Bypass -File "%CORE%""

:: ---------- Default settings, then load saved ones ----------
set "S_THEME=red"
set "S_FORCE=0"
set "S_WARN=1"
set "S_LASTSEC=0"
set "S_LASTLBL="
set "S_ACTION=shutdown"
set "S_CONFIRM=1"
if exist "%SETFILE%" call "%SETFILE%"

:: ---------- Extract the embedded PowerShell helper (bottom of this file) ----------
powershell -NoProfile -ExecutionPolicy Bypass -Command "$t=[IO.File]::ReadAllText('%~f0'); if($t -match '(?ms)^#PS-BEGIN\r?\n(.*?)^#PS-END'){[IO.File]::WriteAllText('%CORE%',$Matches[1])}" >nul 2>&1

set "NOWEPOCH="
if exist "%CORE%" for /f "usebackq delims=" %%i in (`%PS% -Mode now 2^>nul`) do set "NOWEPOCH=%%i"
if not defined NOWEPOCH (
    color 0C
    echo.
    echo   PowerShell could not be started, or it is blocked by a policy
    echo   on this PC. This timer needs Windows PowerShell 5.1 ^(built
    echo   into Windows 10 and 11^).
    echo.
    pause
    exit /b 1
)

:: ---------- Window setup (skipped inside Windows Terminal) ----------
if not defined WT_SESSION (
    mode con: cols=100 lines=38 >nul 2>&1
    %PS% -Mode center >nul 2>&1
)

call :ApplyTheme
call :LoadTimer
set "ACTION=shutdown"
call :ValidAction "!S_ACTION!"
call :NameOf !ACTION! ACTNAME

if "%~1"=="" goto MainMenu
goto CliMode

:: ============================================================
::   MAIN MENU
:: ============================================================
:MainMenu
call :ApplyTheme
cls
call :Banner
call :ShowActiveBrief
echo   Current action : !ACTNAME!
echo.
echo   [1]  In 30 Minutes
echo   [2]  In 1 Hour
echo   [3]  In 2 Hours
echo   [4]  In 3 Hours
echo   [5]  Custom time        ^(90  /  1h30m  /  2:15  /  45m^)
echo   [6]  At a clock time    ^(11:30pm  /  23:30^)
if not "!S_LASTSEC!"=="0" echo   [R]  Repeat last custom : !S_LASTLBL!
echo   [7]  Change action      ^(shutdown / restart / sleep ...^)
echo   [8]  Active timer       ^(watch / extend / cancel^)
echo   [9]  Settings           ^(theme / force mode / warnings^)
echo   [0]  Exit
echo.
set "menuChoice="
set /p "menuChoice=  Select an option: "

set "isCustom=0"
if "!menuChoice!"=="1" (set "totalSeconds=1800"  & goto ConfirmStart)
if "!menuChoice!"=="2" (set "totalSeconds=3600"  & goto ConfirmStart)
if "!menuChoice!"=="3" (set "totalSeconds=7200"  & goto ConfirmStart)
if "!menuChoice!"=="4" (set "totalSeconds=10800" & goto ConfirmStart)
if "!menuChoice!"=="5" goto CustomTime
if "!menuChoice!"=="6" goto ClockTime
if /i "!menuChoice!"=="R" if not "!S_LASTSEC!"=="0" (set "totalSeconds=!S_LASTSEC!" & goto ConfirmStart)
if "!menuChoice!"=="7" goto ChangeAction
if "!menuChoice!"=="8" goto ActiveMenu
if "!menuChoice!"=="9" goto Settings
if "!menuChoice!"=="0" goto ExitScript

echo.
echo   Invalid option, please try again.
timeout /t 2 >nul
goto MainMenu

:: ============================================================
::   CUSTOM TIME  (flexible input)
:: ============================================================
:CustomTime
cls
call :Banner
echo   CUSTOM TIMER  -  !ACTNAME!
echo   --------------------------------------------------------
echo   How long until the action runs?
echo.
echo     90      = 90 minutes        1h30m   = 1 hour 30 minutes
echo     2:15    = 2 hours 15 min    45m     = 45 minutes
echo     2h      = 2 hours           30s     = 30 seconds
echo.
echo   Maximum 168 hours.  Type  B  to go back.
echo   --------------------------------------------------------
echo.
set "custIn="
set /p "custIn=  Time: "
if /i "!custIn!"=="B" goto MainMenu

call :IsSafe custIn
if "!SAFE!"=="0" (
    echo.
    echo   Please use only numbers and the letters h, m, s.
    timeout /t 2 >nul
    goto CustomTime
)

set "totalSeconds=0"
for /f "usebackq delims=" %%i in (`%PS% -Mode parse -Text "!custIn!"`) do set "totalSeconds=%%i"
if "!totalSeconds!"=="0" (
    echo.
    echo   Could not understand that time. Please try again.
    timeout /t 2 >nul
    goto CustomTime
)

:: Remember this as the "last custom time"
set "S_LASTSEC=!totalSeconds!"
for /f "usebackq delims=" %%i in (`%PS% -Mode fmt -Secs !totalSeconds!`) do set "S_LASTLBL=%%i"
call :SaveSettings
goto ConfirmStart

:: ============================================================
::   AT A CLOCK TIME
:: ============================================================
:ClockTime
cls
call :Banner
echo   AT A CLOCK TIME  -  !ACTNAME!
echo   --------------------------------------------------------
echo   Enter the time of day when the action should run.
echo.
echo     11:30pm    23:30    7am    0:15
echo.
echo   If that time already passed today, tomorrow is used.
echo   Type  B  to go back.
echo   --------------------------------------------------------
echo.
set "clockIn="
set /p "clockIn=  At: "
if /i "!clockIn!"=="B" goto MainMenu

call :IsSafe clockIn
if "!SAFE!"=="0" (
    echo.
    echo   Please enter a time like 11:30pm or 23:30.
    timeout /t 2 >nul
    goto ClockTime
)

set "totalSeconds=0"
for /f "usebackq delims=" %%i in (`%PS% -Mode untilclock -Text "!clockIn!"`) do set "totalSeconds=%%i"
if "!totalSeconds!"=="0" (
    echo.
    echo   Could not understand that time. Please try again.
    timeout /t 2 >nul
    goto ClockTime
)
goto ConfirmStart

:: ============================================================
::   CHANGE ACTION
:: ============================================================
:ChangeAction
cls
call :Banner
echo   WHAT SHOULD HAPPEN WHEN THE TIMER ENDS?
echo   --------------------------------------------------------
echo   [1]  Shutdown
echo   [2]  Restart
echo   [3]  Sleep
echo   [4]  Hibernate      ^(must be enabled in Windows^)
echo   [5]  Lock screen
echo   [6]  Log off
echo   [0]  Back
echo   --------------------------------------------------------
echo.
set "actChoice="
set /p "actChoice=  Select (0-6): "
if "!actChoice!"=="1" set "ACTION=shutdown"
if "!actChoice!"=="2" set "ACTION=restart"
if "!actChoice!"=="3" set "ACTION=sleep"
if "!actChoice!"=="4" set "ACTION=hibernate"
if "!actChoice!"=="5" set "ACTION=lock"
if "!actChoice!"=="6" set "ACTION=logoff"
call :NameOf !ACTION! ACTNAME
goto MainMenu

:: ============================================================
::   CONFIRM
:: ============================================================
:ConfirmStart
if "!S_CONFIRM!"=="0" goto DoSchedule
cls
call :Banner
set "durLabel="
set "clockLabel="
for /f "usebackq delims=" %%i in (`%PS% -Mode fmt -Secs !totalSeconds!`) do set "durLabel=%%i"
for /f "usebackq delims=" %%i in (`%PS% -Mode clockin -Secs !totalSeconds!`) do set "clockLabel=%%i"

echo   Action       : !ACTNAME!
echo   Runs in      : !durLabel!
echo   Runs at      : !clockLabel!
echo.
if defined T_TARGET echo   NOTE: this will REPLACE the timer that is already active.
if defined T_TARGET echo.
if "!ACTION!"=="shutdown" echo   Scheduled with Windows itself, so it still happens if you close this window.
if "!ACTION!"=="restart"  echo   Scheduled with Windows itself, so it still happens if you close this window.
if not "!ACTION!"=="shutdown" if not "!ACTION!"=="restart" echo   Run by a hidden helper, so it still happens if you close this window.
if "!S_FORCE!"=="1" (echo   Force mode is ON: open apps will be closed without asking.) else (echo   Force mode is OFF: Windows may ask about apps with unsaved work.)
if "!S_WARN!"=="1" echo   You will get a popup warning 5 minutes and 1 minute before.
echo.
echo   Save your work now if anything is open and unsaved.
echo.
choice /c YN /n /m "  Start this timer now? (Y/N): "
if errorlevel 2 goto MainMenu
goto DoSchedule

:: ============================================================
::   SCHEDULE  (uses ACTION and totalSeconds)
:: ============================================================
:DoSchedule
call :CancelAll
set "T_TARGET="
for /f "usebackq delims=" %%i in (`%PS% -Mode target -Secs !totalSeconds!`) do set "T_TARGET=%%i"
set "T_TOTAL=!totalSeconds!"
set "T_ACTION=!ACTION!"
call :NameOf !T_ACTION! T_ACTNAME

set "forceFlag="
if "!S_FORCE!"=="1" set "forceFlag=/f"
set "nativeFail=0"

if "!ACTION!"=="shutdown" (
    shutdown /s /t !totalSeconds! !forceFlag! /c "Shutdown scheduled by Dev-Fahim-Code Shutdown Timer."
    if errorlevel 1 set "nativeFail=1"
)
if "!ACTION!"=="restart" (
    shutdown /r /t !totalSeconds! !forceFlag! /c "Restart scheduled by Dev-Fahim-Code Shutdown Timer."
    if errorlevel 1 set "nativeFail=1"
)
if "!nativeFail!"=="1" (
    call :ClearTimerState
    cls
    call :Banner
    echo   Could not schedule it. If this PC is managed by a work or
    echo   school policy that restricts shutdown rights, try running
    echo   this script as Administrator, or ask your administrator.
    echo.
    pause
    goto MainMenu
)

:: Hidden helper: warning popups, and the action itself for non-native actions
%PS% -Mode startwaiter -Target !T_TARGET! -Action !ACTION! -Warn !S_WARN! >nul 2>&1

call :SaveTimer
goto Countdown

:: ============================================================
::   COUNTDOWN  (real-clock based, progress bar)
:: ============================================================
:Countdown
:CountdownLoop
call :GetStatus
if "!remaining!"=="0" goto CountdownFinished
cls
call :Banner
echo   ==========================================================
echo    Action             :  !T_ACTNAME!
echo    Scheduled for      :  !clk!
echo   ==========================================================
echo.
echo    Time Remaining     :  !hms!
echo.
echo    !bar!
echo.
echo    It is already scheduled, so it still happens if you close
echo    this window.
echo.
echo    [C] Cancel timer          [E] Extend by 15 minutes
echo    [M] Back to menu ^(timer keeps running^)
echo   ==========================================================
echo.
if !remaining! gtr 300 (set "waitStep=5") else (set "waitStep=1")
choice /c CEMX /n /t !waitStep! /d X >nul
if errorlevel 4 goto CountdownLoop
if errorlevel 3 goto MainMenu
if errorlevel 2 goto ExtendQuick

call :CancelAll
cls
call :Banner
echo   The scheduled timer has been cancelled.
echo.
pause
goto MainMenu

:CountdownFinished
cls
call :Banner
echo   Countdown finished. The scheduled !T_ACTNAME! is happening now.
echo.
call :ClearTimerState
timeout /t 6 >nul
goto ExitScript

:: ============================================================
::   ACTIVE TIMER MENU  (watch / extend / cancel)
:: ============================================================
:ActiveMenu
cls
call :Banner
if not defined T_TARGET (
    echo   There is no active timer right now.
    echo.
    pause
    goto MainMenu
)
call :ShowActiveBrief
if not defined T_TARGET (
    echo   The timer has just finished.
    echo.
    pause
    goto MainMenu
)
echo   [1]  Watch live countdown
echo   [2]  Extend by 15 minutes
echo   [3]  Extend by 30 minutes
echo   [4]  Extend by 1 hour
echo   [5]  Extend by a custom amount
echo   [6]  Cancel timer
echo   [0]  Back
echo.
set "actvChoice="
set /p "actvChoice=  Select (0-6): "
if "!actvChoice!"=="1" goto Countdown
if "!actvChoice!"=="2" (set "addSeconds=900"  & goto DoExtend)
if "!actvChoice!"=="3" (set "addSeconds=1800" & goto DoExtend)
if "!actvChoice!"=="4" (set "addSeconds=3600" & goto DoExtend)
if "!actvChoice!"=="5" goto ExtendCustom
if "!actvChoice!"=="6" goto CancelShutdown
goto MainMenu

:ExtendQuick
set "addSeconds=900"
goto DoExtend

:ExtendCustom
cls
call :Banner
echo   EXTEND BY HOW MUCH?   ^(for example  20   or  1h15m^)
echo   Type  B  to go back.
echo.
set "extIn="
set /p "extIn=  Add: "
if /i "!extIn!"=="B" goto ActiveMenu
call :IsSafe extIn
if "!SAFE!"=="0" (
    echo.
    echo   Please use only numbers and the letters h, m, s.
    timeout /t 2 >nul
    goto ExtendCustom
)
set "addSeconds=0"
for /f "usebackq delims=" %%i in (`%PS% -Mode parse -Text "!extIn!"`) do set "addSeconds=%%i"
if "!addSeconds!"=="0" (
    echo.
    echo   Could not understand that time. Please try again.
    timeout /t 2 >nul
    goto ExtendCustom
)
goto DoExtend

:DoExtend
if not defined T_TARGET (
    echo   There is no active timer to extend.
    pause
    goto MainMenu
)
set "rem2=0"
for /f "usebackq delims=" %%i in (`%PS% -Mode remaining -Target !T_TARGET!`) do set "rem2=%%i"
if "!rem2!"=="0" (
    echo   The timer has already finished.
    pause
    goto MainMenu
)
set /a totalSeconds=rem2+addSeconds
set "ACTION=!T_ACTION!"
call :NameOf !ACTION! ACTNAME
goto DoSchedule

:: ============================================================
::   CANCEL
:: ============================================================
:CancelShutdown
cls
call :Banner
set "wasActive=0"
if defined T_TARGET set "wasActive=1"
shutdown /a >nul 2>&1 && set "wasActive=1"
call :CancelAll
if "!wasActive!"=="1" (
    echo   Any scheduled timer has been cancelled.
) else (
    echo   No timer was scheduled.
)
echo.
pause
goto MainMenu

:: ============================================================
::   SETTINGS
:: ============================================================
:Settings
cls
call :Banner
set "forceTxt=OFF"
if "!S_FORCE!"=="1" set "forceTxt=ON"
set "warnTxt=OFF"
if "!S_WARN!"=="1" set "warnTxt=ON"
set "confTxt=OFF"
if "!S_CONFIRM!"=="1" set "confTxt=ON"
call :NameOf !S_ACTION! defName
echo   SETTINGS
echo   --------------------------------------------------------
echo   [1]  Theme                   : !S_THEME!
echo   [2]  Force-close apps        : !forceTxt!
echo          ON  = open apps are closed without asking
echo          OFF = Windows may ask about unsaved work ^(safer^)
echo   [3]  Warning popups          : !warnTxt!
echo   [4]  Default action          : !defName!
echo          choose 4 to use the current action ^(!ACTNAME!^) as default
echo   [5]  Ask before starting     : !confTxt!
echo   [6]  Reset all settings
echo   [0]  Back
echo   --------------------------------------------------------
echo   Settings apply to timers started from now on.
echo.
set "setChoice="
set /p "setChoice=  Select (0-6): "
if "!setChoice!"=="1" goto ThemeMenu
if "!setChoice!"=="2" (
    if "!S_FORCE!"=="1" (set "S_FORCE=0") else (set "S_FORCE=1")
    call :SaveSettings
    goto Settings
)
if "!setChoice!"=="3" (
    if "!S_WARN!"=="1" (set "S_WARN=0") else (set "S_WARN=1")
    call :SaveSettings
    goto Settings
)
if "!setChoice!"=="4" (
    set "S_ACTION=!ACTION!"
    call :SaveSettings
    goto Settings
)
if "!setChoice!"=="5" (
    if "!S_CONFIRM!"=="1" (set "S_CONFIRM=0") else (set "S_CONFIRM=1")
    call :SaveSettings
    goto Settings
)
if "!setChoice!"=="6" goto ResetSettings
goto MainMenu

:ResetSettings
cls
call :Banner
echo   Reset theme, force mode, warnings, default action and the
echo   saved last custom time back to their defaults?
echo   An active timer is NOT affected.
echo.
choice /c YN /n /m "  Reset now? (Y/N): "
if errorlevel 2 goto Settings
if exist "%SETFILE%" del "%SETFILE%" >nul 2>&1
set "S_THEME=red"
set "S_FORCE=0"
set "S_WARN=1"
set "S_LASTSEC=0"
set "S_LASTLBL="
set "S_ACTION=shutdown"
set "S_CONFIRM=1"
set "ACTION=shutdown"
call :NameOf shutdown ACTNAME
call :ApplyTheme
goto Settings

:ThemeMenu
cls
call :Banner
echo   CHOOSE A THEME
echo   --------------------------------------------------------
echo   [1]  Red  ^(default^)
echo   [2]  Green
echo   [3]  Blue
echo   [4]  Aqua
echo   [5]  Yellow
echo   [6]  Classic  ^(white on black^)
echo   [0]  Back
echo   --------------------------------------------------------
echo.
set "thChoice="
set /p "thChoice=  Select (0-6): "
if "!thChoice!"=="1" set "S_THEME=red"
if "!thChoice!"=="2" set "S_THEME=green"
if "!thChoice!"=="3" set "S_THEME=blue"
if "!thChoice!"=="4" set "S_THEME=aqua"
if "!thChoice!"=="5" set "S_THEME=yellow"
if "!thChoice!"=="6" set "S_THEME=classic"
call :SaveSettings
call :ApplyTheme
goto Settings

:: ============================================================
::   COMMAND-LINE MODE
:: ============================================================
:CliMode
if /i "%~1"=="cancel" goto CliCancel
if /i "%~1"=="status" goto CliStatus
if /i "%~1"=="help"   goto CliHelp
if "%~1"=="/?"        goto CliHelp
if "%~1"=="-h"        goto CliHelp
if /i "%~1"=="version" goto CliVersion

set "cliType=dur"
set "cliTime=%~1"
set "cliAct=%~2"
if /i "%~1"=="at" (
    set "cliType=clock"
    set "cliTime=%~2"
    set "cliAct=%~3"
)
if not defined cliTime (
    echo   Missing time. Run  ShutdownTimer.bat help  for examples.
    exit /b 1
)
if defined cliAct (
    call :ValidAction "!cliAct!"
    if "!ACTOK!"=="0" (
        echo   Unknown action "!cliAct!". Use: shutdown restart sleep hibernate lock logoff
        exit /b 1
    )
)
call :NameOf !ACTION! ACTNAME

call :IsSafe cliTime
if "!SAFE!"=="0" (
    echo   Invalid time.
    exit /b 1
)
set "totalSeconds=0"
if "!cliType!"=="clock" (
    for /f "usebackq delims=" %%i in (`%PS% -Mode untilclock -Text "!cliTime!"`) do set "totalSeconds=%%i"
) else (
    for /f "usebackq delims=" %%i in (`%PS% -Mode parse -Text "!cliTime!"`) do set "totalSeconds=%%i"
)
if "!totalSeconds!"=="0" (
    echo   Could not understand the time "!cliTime!".
    exit /b 1
)
goto DoSchedule

:CliCancel
call :CancelAll
echo   Any scheduled timer has been cancelled.
exit /b 0

:CliStatus
if not defined T_TARGET (
    echo   No active timer.
    exit /b 0
)
call :GetStatus
echo   Active: !T_ACTNAME! at !clk!  ^(!hms! left^)
exit /b 0

:CliVersion
echo   Windows Shutdown Timer PRO v%VERSION%
exit /b 0

:CliHelp
echo.
echo   Windows Shutdown Timer PRO  -  Dev-Fahim-Code
echo.
echo   Usage:
echo     ShutdownTimer.bat                      open the menu
echo     ShutdownTimer.bat 45                   shutdown in 45 minutes
echo     ShutdownTimer.bat 1h30m restart        restart in 1h 30m
echo     ShutdownTimer.bat at 11:30pm sleep     sleep at 11:30 PM
echo     ShutdownTimer.bat status               show the active timer
echo     ShutdownTimer.bat cancel               cancel the active timer
echo     ShutdownTimer.bat version              show the version
echo.
echo   Actions: shutdown  restart  sleep  hibernate  lock  logoff
echo   If no action is given, your default action from Settings is used.
echo.
exit /b 0

:: ============================================================
::   EXIT
:: ============================================================
:ExitScript
cls
call :Banner
echo   Thank you for using Windows Shutdown Timer.
echo   Dev-Fahim-Code  -  https://github.com/dev-fahim-code
echo.
timeout /t 2 >nul
endlocal
exit /b

:: ============================================================
::   SUBROUTINES (these never run unless called)
:: ============================================================

:Banner
echo.
echo   ====================================================
echo      W I N D O W S   S H U T D O W N   T I M E R
echo                P R O   E D I T I O N   -   v%VERSION%
echo   ====================================================
echo.
echo     Developed by : Dev-Fahim-Code
echo     GitHub       : https://github.com/dev-fahim-code
echo   ====================================================
echo.
goto :eof

:ApplyTheme
set "tc=0C"
if /i "!S_THEME!"=="green"   set "tc=0A"
if /i "!S_THEME!"=="blue"    set "tc=09"
if /i "!S_THEME!"=="aqua"    set "tc=0B"
if /i "!S_THEME!"=="yellow"  set "tc=0E"
if /i "!S_THEME!"=="classic" set "tc=07"
color !tc!
goto :eof

:NameOf
:: %1 = action id, %2 = variable to receive the display name
set "%~2=Shutdown"
if /i "%~1"=="restart"   set "%~2=Restart"
if /i "%~1"=="sleep"     set "%~2=Sleep"
if /i "%~1"=="hibernate" set "%~2=Hibernate"
if /i "%~1"=="lock"      set "%~2=Lock screen"
if /i "%~1"=="logoff"    set "%~2=Log off"
goto :eof

:ValidAction
:: %1 = action typed on the command line; sets ACTION (lowercase) and ACTOK
set "ACTOK=0"
for %%a in (shutdown restart sleep hibernate lock logoff) do (
    if /i "%~1"=="%%a" (
        set "ACTION=%%a"
        set "ACTOK=1"
    )
)
goto :eof

:IsSafe
:: %1 = name of a variable; SAFE=1 only if it has just letters, digits, space, colon, dot
set "SAFE=0"
echo(!%~1!| findstr /r /c:"^[0-9a-zA-Z: .]*$" >nul && set "SAFE=1"
goto :eof

:GetStatus
:: Reads the real remaining time of the active timer
if not defined T_TOTAL set "T_TOTAL=1"
set "remaining=0"
set "hms=00h 00m 00s"
set "bar="
set "clk=--:--"
for /f "usebackq tokens=1-4 delims=;" %%a in (`%PS% -Mode status -Target !T_TARGET! -Secs !T_TOTAL!`) do (
    set "remaining=%%a"
    set "hms=%%b"
    set "bar=%%c"
    set "clk=%%d"
)
goto :eof

:ShowActiveBrief
if not defined T_TARGET goto :eof
call :GetStatus
if "!remaining!"=="0" (
    call :ClearTimerState
    goto :eof
)
echo   ACTIVE TIMER : !T_ACTNAME! at !clk!   ^(!hms! left^)
echo   --------------------------------------------------------
echo.
goto :eof

:LoadTimer
set "T_ACTION="
set "T_TARGET="
set "T_TOTAL="
set "T_ACTNAME="
if not exist "%TIMERFILE%" goto :eof
call "%TIMERFILE%"
if not defined T_TARGET goto :eof
call :NameOf !T_ACTION! T_ACTNAME
set "rem2=0"
for /f "usebackq delims=" %%i in (`%PS% -Mode remaining -Target !T_TARGET!`) do set "rem2=%%i"
if "!rem2!"=="0" call :ClearTimerState
goto :eof

:SaveTimer
(
    echo set "T_ACTION=!T_ACTION!"
    echo set "T_TARGET=!T_TARGET!"
    echo set "T_TOTAL=!T_TOTAL!"
)>"%TIMERFILE%"
goto :eof

:ClearTimerState
if exist "%TIMERFILE%" del "%TIMERFILE%" >nul 2>&1
set "T_ACTION="
set "T_TARGET="
set "T_TOTAL="
set "T_ACTNAME="
goto :eof

:CancelAll
shutdown /a >nul 2>&1
%PS% -Mode stopwaiter >nul 2>&1
call :ClearTimerState
goto :eof

:SaveSettings
(
    echo set "S_THEME=!S_THEME!"
    echo set "S_FORCE=!S_FORCE!"
    echo set "S_WARN=!S_WARN!"
    echo set "S_LASTSEC=!S_LASTSEC!"
    echo set "S_LASTLBL=!S_LASTLBL!"
    echo set "S_ACTION=!S_ACTION!"
    echo set "S_CONFIRM=!S_CONFIRM!"
)>"%SETFILE%"
goto :eof

exit /b

:: ============================================================
::   EMBEDDED POWERSHELL HELPER
::   Everything below is never executed by cmd.exe; it is copied
::   into core.ps1 at start-up. Keep it plain ASCII.
:: ============================================================
#PS-BEGIN
param(
    [string]$Mode = '',
    [long]$Target = 0,
    [long]$Secs = 0,
    [string]$Text = '',
    [string]$Action = 'shutdown',
    [int]$Warn = 1
)
$ErrorActionPreference = 'SilentlyContinue'
$inv = [Globalization.CultureInfo]::InvariantCulture

function Get-Now { [DateTimeOffset]::UtcNow.ToUnixTimeSeconds() }

function Fmt([long]$s) {
    if ($s -lt 0) { $s = 0 }
    $h = [math]::Floor($s / 3600)
    $m = [math]::Floor(($s % 3600) / 60)
    $x = $s % 60
    $p = @()
    if ($h -gt 0) { $p += "${h}h" }
    if ($m -gt 0) { $p += "${m}m" }
    if ($x -gt 0 -or $p.Count -eq 0) { $p += "${x}s" }
    $p -join ' '
}

function Clock([long]$t) {
    $d = [DateTimeOffset]::FromUnixTimeSeconds($t).LocalDateTime
    if ($d.Date -eq (Get-Date).Date) { $d.ToString('hh:mm tt', $inv) }
    else { $d.ToString('ddd hh:mm tt', $inv) }
}

function ActName([string]$a) {
    switch ($a.ToLower()) {
        'restart'   { 'Restart' }
        'sleep'     { 'Sleep' }
        'hibernate' { 'Hibernate' }
        'lock'      { 'Screen lock' }
        'logoff'    { 'Log off' }
        default     { 'Shutdown' }
    }
}

function Notify([string]$msg) {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    $n = New-Object System.Windows.Forms.NotifyIcon
    $n.Icon = [System.Drawing.SystemIcons]::Warning
    $n.Visible = $true
    $n.ShowBalloonTip(10000, 'Shutdown Timer', $msg, [System.Windows.Forms.ToolTipIcon]::Warning)
    Start-Sleep -Seconds 8
    $n.Dispose()
}

switch ($Mode) {

    'now' { Get-Now }

    'target' { (Get-Now) + $Secs }

    'remaining' {
        $r = $Target - (Get-Now)
        if ($r -lt 0) { $r = 0 }
        $r
    }

    'fmt' { Fmt $Secs }

    'clockin' { Clock ((Get-Now) + $Secs) }

    'status' {
        $r = $Target - (Get-Now)
        if ($r -lt 0) { $r = 0 }
        $h = [int][math]::Floor($r / 3600)
        $m = [int][math]::Floor(($r % 3600) / 60)
        $s = [int]($r % 60)
        $tot = $Secs
        if ($tot -lt 1) { $tot = 1 }
        $pct = [int][math]::Floor((($tot - $r) * 100) / $tot)
        if ($pct -lt 0) { $pct = 0 }
        if ($pct -gt 100) { $pct = 100 }
        $w = 40
        $f = [int][math]::Floor($w * $pct / 100)
        $bar = '[' + ('#' * $f) + ('-' * ($w - $f)) + '] ' + $pct + '%'
        '{0};{1:00}h {2:00}m {3:00}s;{4};{5}' -f $r, $h, $m, $s, $bar, (Clock $Target)
    }

    'parse' {
        $t = $Text.ToLower() -replace '\s', ''
        $t = $t -replace 'hours?|hrs?', 'h'
        $t = $t -replace 'minutes?|mins?', 'm'
        $t = $t -replace 'seconds?|secs?', 's'
        $s = 0
        if ($t -match '^(\d+):(\d{1,2})$') {
            $s = [long]$Matches[1] * 3600 + [long]$Matches[2] * 60
        }
        elseif ($t -match '^\d+$') {
            $s = [long]$t * 60
        }
        elseif ($t -ne '' -and $t -match '^(?:(\d+)h)?(?:(\d+)m)?(?:(\d+)s)?$') {
            $s = [long]('0' + $Matches[1]) * 3600 + [long]('0' + $Matches[2]) * 60 + [long]('0' + $Matches[3])
        }
        if ($s -gt 604800) { $s = 0 }
        $s
    }

    'untilclock' {
        $t = $Text.ToLower() -replace '\s', ''
        $h = -1
        $m = 0
        if ($t -match '^(\d{1,2})(?::(\d{2}))?(am|pm|a|p)?$') {
            $h = [int]$Matches[1]
            if ($Matches[2]) { $m = [int]$Matches[2] }
            $ap = $Matches[3]
            if ($ap) {
                if ($h -lt 1 -or $h -gt 12) { $h = -1 }
                elseif ($ap -like 'p*') { if ($h -lt 12) { $h += 12 } }
                else { if ($h -eq 12) { $h = 0 } }
            }
        }
        $out = 0
        if ($h -ge 0 -and $h -le 23 -and $m -ge 0 -and $m -le 59) {
            $now = Get-Date
            $d = Get-Date -Hour $h -Minute $m -Second 0 -Millisecond 0
            if ($d -le $now) { $d = $d.AddDays(1) }
            $out = [long][math]::Ceiling(($d - $now).TotalSeconds)
        }
        $out
    }

    'startwaiter' {
        $a = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"' + $PSCommandPath + '"'),
               '-Mode', 'wait', '-Target', "$Target", '-Action', $Action, '-Warn', "$Warn")
        $p = Start-Process -FilePath 'powershell.exe' -ArgumentList $a -WindowStyle Hidden -PassThru
        $p.Id
    }

    'stopwaiter' {
        Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
            Where-Object { $_.CommandLine -like '*core.ps1*-Mode wait*' -and $_.ProcessId -ne $PID } |
            ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
    }

    'wait' {
        $name = ActName $Action
        $total = $Target - (Get-Now)
        $w5 = $false
        $w1 = $false
        while ((Get-Now) -lt $Target) {
            $r = $Target - (Get-Now)
            if ($Warn -eq 1) {
                if ($r -le 60 -and -not $w1) {
                    $w1 = $true
                    $w5 = $true
                    if ($total -gt 60) { Notify "$name in about 1 minute. Save your work now." }
                }
                elseif ($r -le 300 -and -not $w5) {
                    $w5 = $true
                    if ($total -gt 300) { Notify "$name in about 5 minutes. Save your work." }
                }
            }
            Start-Sleep -Seconds 1
        }
        switch ($Action.ToLower()) {
            'sleep' {
                Add-Type -AssemblyName System.Windows.Forms
                [void][System.Windows.Forms.Application]::SetSuspendState([System.Windows.Forms.PowerState]::Suspend, $false, $false)
            }
            'hibernate' { & shutdown.exe /h }
            'lock'      { & rundll32.exe user32.dll,LockWorkStation }
            'logoff'    { & shutdown.exe /l }
            default     { }
        }
    }

    'center' {
        Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public class DfcWin {
    [DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr h, int x, int y, int w, int ht, bool repaint);
    public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
}
'@
        Add-Type -AssemblyName System.Windows.Forms
        $hwnd = [DfcWin]::GetConsoleWindow()
        if ($hwnd -ne [IntPtr]::Zero) {
            $rect = New-Object DfcWin+RECT
            [void][DfcWin]::GetWindowRect($hwnd, [ref]$rect)
            $w = $rect.Right - $rect.Left
            $h = $rect.Bottom - $rect.Top
            $scr = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
            $x = [int](($scr.Width - $w) / 2) + $scr.Left
            $y = [int](($scr.Height - $h) / 2) + $scr.Top
            [void][DfcWin]::MoveWindow($hwnd, $x, $y, $w, $h, $true)
        }
    }
}
#PS-END
