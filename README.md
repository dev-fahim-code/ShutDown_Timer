# ⏱️ Windows Shutdown Timer

Simple, standalone Windows shutdown timer implemented as a single batch file. Provides quick presets (30 minutes, 1 / 2 / 3 hours), a custom hours+minutes timer, an active countdown with exact shutdown clock time, a cancel option, automatic closing of background apps before shutdown, and automatic elevation to Administrator when needed. No extra files or dependencies required.

## Features
- Presets: 30 minutes, 1 hour, 2 hours, 3 hours.
- Custom timer: set hours + minutes (0–23 hours, 0–59 minutes).
- Active countdown display with zero-padded time and the exact clock time when shutdown will occur.
- Cancel scheduled shutdown via menu or `shutdown /a`.
- Automatically closes most background apps (configurable safelist) before shutting down.
- Self-elevates (UAC) to Admin if required.
- Centers the console window on screen for a tidy UI.
- Standalone: single `ShutDown_Timer.bat` file.

## Requirements
- Windows (tested on modern Windows 10/11).
- Administrative privileges are required to issue a system shutdown; the script will request elevation automatically.

## Installation
1. Download `ShutDown_Timer.bat` from this repository.
2. Place it anywhere on your PC (e.g., Desktop or Downloads).

## Usage
- Double‑click `ShutDown_Timer.bat` from Explorer, or run it from a console:
  - PowerShell: `.\ShutDown_Timer.bat`
  - Command Prompt: `ShutDown_Timer.bat`

When launched the script will:
- Request UAC elevation if not already running as Administrator.
- Open a console menu with preset and custom timer options.
- Show an active countdown and scheduled shutdown clock time.
- Allow cancellation at any time by pressing `C` during the countdown, or selecting "Cancel Any Scheduled Shutdown" from the main menu.

Quick operation:
- Start a timer using menu choices 1–5.
- To cancel a pending OS shutdown from anywhere, run:
  ```
  shutdown /a
  ```
  (The script also provides a menu option to cancel.)

## Custom Time Notes
- Choose option 5 in the menu to set a custom timer (hours + minutes).
- You can type `B` during the custom prompts to go back to the main menu.
- Hours must be 0–23, minutes 0–59; the script strips leading zeros and validates ranges.

## Customization
- Open `ShutDown_Timer.bat` in a text editor to tweak behavior.
  - `safelist` — a comma-separated list of process names that the script will NOT forcibly close before shutdown (defaults include system-critical processes). Edit carefully.
  - Console appearance — the script sets `mode con:` (cols & lines) and `color` at the top; adjust as desired.
  - Presets — the preset durations are defined in the main menu branch; you can change the seconds values for presets if you want different defaults.

## How it works (brief)
- Admin check: runs `net session` and, if not elevated, re-launches itself via PowerShell `Start-Process -Verb RunAs`.
- Shutdown scheduling: internal countdown loop using `choice` and `timeout` to wake periodically and update display.
- Exact shutdown clock time is calculated via PowerShell: `[datetime]::Now.AddSeconds(...)`.
- Closes background apps using `tasklist` and `taskkill`, protected by a safelist to avoid killing system-critical processes.
- Final shutdown: `shutdown /s /t 5 /f` with a short delay and a comment.

## Safety & Warnings
- The script force-closes background processes (`taskkill /f`) except those listed in `safelist`. Save work before starting a timer.
- Be cautious editing the safelist — removing critical processes may cause system instability.
- Administrative privileges are required to perform a system shutdown.

## Troubleshooting
- UAC prompt not shown / no elevation: try right-click → Run as administrator.
- Shutdown not happening: check for pending `shutdown /a` or if another process cancelled the shutdown.
- To abort a scheduled shutdown manually: run `shutdown /a` in an elevated command prompt.
- If the script fails to center the window or the centering step errors, it's non-fatal — the timer will still run.

## Contributing
- This project is a single-file utility. If you'd like improvements (e.g., additional presets, safer app-closing logic, or localization), open an issue or submit a PR with your proposed changes.
- When editing, keep the script standalone and avoid adding external dependencies.

## License
[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](https://choosealicense.com/licenses/mit/)

## Support

For support, 
[![Discord](https://img.shields.io/badge/Discord-%237289DA.svg?logo=discord&logoColor=white)](https://discord.gg/bb2k3w5Q5A) join our Discord Server.

## Author

- [@Dev-Fahim-Code](https://github.com/dev-fahim-code)
