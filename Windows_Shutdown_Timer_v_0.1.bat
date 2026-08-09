@echo off
setlocal enabledelayedexpansion
title Windows Shutdown Timer - Dev-Fahim-Code

:: ============================================================
::   WINDOWS SHUTDOWN TIMER
::   Developed by : Dev-Fahim-Code
::   GitHub       : https://github.com/dev-fahim-code
::
::   Features: 30 min / 1h / 2h / 3h presets, custom timer
::   (hours + minutes), back option in custom menu, active
::   timer display with exact shutdown clock time, cancel
::   option, centers itself on screen with a light-red theme.
::   Runs as a normal user (no admin rights required) and does
::   NOT force-close any other applications. Works standalone,
::   no extra files needed.
::
::   IMPORTANT: as soon as you confirm a timer, the shutdown is
::   scheduled directly with Windows (shutdown /t). It will still
::   happen even if you close this window. To cancel, run this
::   script again and choose option 6 (or press C while this
::   window is still open and the countdown is showing).
:: ============================================================

:: ---------- Console look ----------
mode con: cols=100 lines=38 >nul 2>&1
color 0C
call :CenterWindow

goto MainMenu

:: ============================================================
::   MAIN MENU
:: ============================================================
:MainMenu
cls
call :Banner
echo   [1]  Shutdown in 30 Minutes
echo   [2]  Shutdown in 1 Hour
echo   [3]  Shutdown in 2 Hours
echo   [4]  Shutdown in 3 Hours
echo   [5]  Custom Time  (Set Hours + Minutes)
echo   [6]  Cancel Any Scheduled Shutdown
echo   [7]  Exit
echo.
set "menuChoice="
set /p "menuChoice=  Select an option (1-7): "

if "!menuChoice!"=="1" (set "totalSeconds=1800"  & set "timeLabel=30 Minutes"  & goto ConfirmStart)
if "!menuChoice!"=="2" (set "totalSeconds=3600"  & set "timeLabel=1 Hour"      & goto ConfirmStart)
if "!menuChoice!"=="3" (set "totalSeconds=7200"  & set "timeLabel=2 Hours"     & goto ConfirmStart)
if "!menuChoice!"=="4" (set "totalSeconds=10800" & set "timeLabel=3 Hours"     & goto ConfirmStart)
if "!menuChoice!"=="5" goto CustomTime
if "!menuChoice!"=="6" goto CancelShutdown
if "!menuChoice!"=="7" goto ExitScript

echo.
echo   Invalid option, please try again.
timeout /t 2 >nul
goto MainMenu

:: ============================================================
::   CUSTOM TIME  (B to go back, hours + minutes)
:: ============================================================
:CustomTime
cls
call :Banner
echo   CUSTOM SHUTDOWN TIMER
echo   --------------------------------------------------------
echo   Set how many hours AND minutes until shutdown.
echo   Type  B  at any prompt to return to the Main Menu.
echo   --------------------------------------------------------
echo.

set "custH="
set /p "custH=  Hours   (0-23)   [B = Back to Menu]: "
if /i "!custH!"=="B" goto MainMenu

set "custM="
set /p "custM=  Minutes (0-59)   [B = Back to Menu]: "
if /i "!custM!"=="B" goto MainMenu

:: --- Validate hours ---
echo(!custH!| findstr /r "^[0-9][0-9]*$" >nul
if errorlevel 1 (
    echo.
    echo   Hours must be a number between 0 and 23. Please try again.
    timeout /t 2 >nul
    goto CustomTime
)

:: --- Validate minutes ---
echo(!custM!| findstr /r "^[0-9][0-9]*$" >nul
if errorlevel 1 (
    echo.
    echo   Minutes must be a number between 0 and 59. Please try again.
    timeout /t 2 >nul
    goto CustomTime
)

:: --- Strip leading zeros (prevents octal arithmetic errors) ---
:StripZeroH
if "%custH%"=="0" goto StripZeroHDone
if "%custH:~0,1%"=="0" (set "custH=%custH:~1%" & goto StripZeroH)
:StripZeroHDone

:StripZeroM
if "%custM%"=="0" goto StripZeroMDone
if "%custM:~0,1%"=="0" (set "custM=%custM:~1%" & goto StripZeroM)
:StripZeroMDone

:: --- Validate range ---
if %custH% gtr 23 (
    echo.
    echo   Hours cannot exceed 23. Please try again.
    timeout /t 2 >nul
    goto CustomTime
)
if %custM% gtr 59 (
    echo.
    echo   Minutes cannot exceed 59. Please try again.
    timeout /t 2 >nul
    goto CustomTime
)

set /a totalSeconds=(custH * 3600) + (custM * 60)

if %totalSeconds% leq 0 (
    echo.
    echo   Total time must be greater than zero. Please try again.
    timeout /t 2 >nul
    goto CustomTime
)

set "timeLabel=%custH%h %custM%m - Custom"
goto ConfirmStart

:: ============================================================
::   CONFIRM
:: ============================================================
:ConfirmStart
cls
call :Banner
echo   Selected duration : %timeLabel%
echo.
echo   Shutdown will be scheduled with Windows the moment you
echo   confirm. It will still happen even if you close this
echo   window - to cancel, run this script again and pick
echo   option 6, or press C while the countdown is showing.
echo.
echo   Save your work now if anything is open and unsaved.
echo.
choice /c YN /n /m "  Start this timer now? (Y/N): "
if errorlevel 2 goto MainMenu
goto StartCountdown

:: ============================================================
::   COUNTDOWN  (shows active timer + exact shutdown clock time)
:: ============================================================
:StartCountdown
set /a remaining=totalSeconds

:: --- Schedule the shutdown with Windows itself right now. This is what
::     makes the timer survive closing this window - Windows owns the
::     countdown from this point on, not the batch script. ---
shutdown /s /t %totalSeconds% /f /c "Shutdown scheduled by Dev-Fahim-Code Shutdown Timer."
if errorlevel 1 (
    cls
    call :Banner
    echo   Could not schedule the shutdown. If this PC is managed by
    echo   a work or school policy that restricts shutdown rights,
    echo   try running this script as Administrator, or contact your
    echo   system administrator.
    echo.
    pause
    goto MainMenu
)

:: --- Calculate the exact clock time when shutdown will occur ---
powershell -NoProfile -Command "[datetime]::Now.AddSeconds(%totalSeconds%).ToString('hh:mm tt')" > "%temp%\dfc_stime.tmp" 2>nul
set "shutdownAt=--:-- --"
if exist "%temp%\dfc_stime.tmp" (
    set /p shutdownAt= < "%temp%\dfc_stime.tmp"
    del "%temp%\dfc_stime.tmp" >nul 2>&1
)

:CountdownLoop
if %remaining% leq 0 goto CountdownFinished
cls
call :Banner

:: Zero-pad hours, minutes, seconds for clean display
set /a hh=remaining/3600
set /a mm=(remaining/60)%%60
set /a ss=remaining%%60
if %hh% lss 10 set "hh=0%hh%"
if %mm% lss 10 set "mm=0%mm%"
if %ss% lss 10 set "ss=0%ss%"

echo   ========================================================
echo    Active Timer      :  %timeLabel%
echo    Scheduled Shutdown:  %shutdownAt%
echo   ========================================================
echo.
echo    Time Remaining    :  %hh%h  %mm%m  %ss%s
echo.
echo    Shutdown is already scheduled with Windows - it will still
echo    happen even if you close this window.
echo.
echo    Press [C] to CANCEL the scheduled shutdown and return to
echo    the menu.
echo   ========================================================
echo.

if %remaining% gtr 60 (set "waitStep=30") else (set "waitStep=1")
choice /c CX /n /t %waitStep% /d X >nul
if errorlevel 2 goto StepDone
goto CancelFromCountdown

:StepDone
if %waitStep% gtr %remaining% (set /a remaining=0) else (set /a remaining-=waitStep)
goto CountdownLoop

:CancelFromCountdown
shutdown /a >nul 2>&1
cls
call :Banner
echo   The scheduled shutdown has been cancelled.
echo.
pause
goto MainMenu

:: ============================================================
::   COUNTDOWN DISPLAY FINISHED
:: ============================================================
:CountdownFinished
cls
call :Banner
echo   Countdown finished. The shutdown that was scheduled with
echo   Windows when you confirmed the timer should occur any
echo   moment now.
echo.
timeout /t 5 >nul
goto ExitScript

:: ============================================================
::   CANCEL
:: ============================================================
:CancelShutdown
cls
call :Banner
shutdown /a >nul 2>&1
if errorlevel 1 (
    echo   No shutdown was currently scheduled ^(or it could not be cancelled^).
) else (
    echo   Any pending shutdown has been cancelled.
)
echo.
pause
goto MainMenu

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
echo   ====================================================
echo.
echo     Developed by : Dev-Fahim-Code
echo     GitHub       : https://github.com/dev-fahim-code
echo   ====================================================
echo.
goto :eof

:CenterWindow
set "psFile=%temp%\dfc_center_%random%.ps1"
echo $sig = @' > "%psFile%"
echo using System; >> "%psFile%"
echo using System.Runtime.InteropServices; >> "%psFile%"
echo public class Win32Center { >> "%psFile%"
echo     [DllImport("user32.dll")] >> "%psFile%"
echo     public static extern IntPtr GetForegroundWindow(); >> "%psFile%"
echo     [DllImport("user32.dll")] >> "%psFile%"
echo     public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect); >> "%psFile%"
echo     [DllImport("user32.dll")] >> "%psFile%"
echo     public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint); >> "%psFile%"
echo     public struct RECT { public int Left; public int Top; public int Right; public int Bottom; } >> "%psFile%"
echo } >> "%psFile%"
echo '@ >> "%psFile%"
echo Add-Type -TypeDefinition $sig -Language CSharp >> "%psFile%"
echo Add-Type -AssemblyName System.Windows.Forms >> "%psFile%"
echo $hwnd = [Win32Center]::GetForegroundWindow() >> "%psFile%"
echo $rect = New-Object Win32Center+RECT >> "%psFile%"
echo [Win32Center]::GetWindowRect($hwnd, [ref]$rect) ^| Out-Null >> "%psFile%"
echo $w = $rect.Right - $rect.Left >> "%psFile%"
echo $h = $rect.Bottom - $rect.Top >> "%psFile%"
echo $screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea >> "%psFile%"
echo $x = [int](($screen.Width - $w) / 2) >> "%psFile%"
echo $y = [int](($screen.Height - $h) / 2) >> "%psFile%"
echo [Win32Center]::MoveWindow($hwnd, $x, $y, $w, $h, $true) ^| Out-Null >> "%psFile%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%psFile%" >nul 2>&1
del "%psFile%" >nul 2>&1
goto :eof
