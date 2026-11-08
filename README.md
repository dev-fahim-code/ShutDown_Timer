# ⏱️ Windows Shutdown Timer PRO

![Version](https://img.shields.io/badge/version-2.1-red) ![Platform](https://img.shields.io/badge/platform-Windows%2010%2F11-blue) ![Type](https://img.shields.io/badge/type-Batch-lightgrey)

A single-file Windows batch script for scheduling **shutdown, restart, sleep, hibernate, lock or log off**, with a live countdown, popup warnings and a clean light-red console UI.

No installation. No admin rights. One `.bat` file.

---

## ✨ Features

- **6 actions:** shutdown, restart, sleep, hibernate, lock screen, log off
- **Quick presets:** 30 min, 1 h, 2 h, 3 h
- **Flexible custom time:** `90`, `1h30m`, `2:15`, `45m`, `30s` (up to 168 hours)
- **Clock-time mode:** `11:30pm`, `23:30`, `7am`
- **Extend a running timer:** +15 / +30 / +60 min or a custom amount, without restarting it
- **Warning popups:** a Windows notification 5 minutes and 1 minute before the action
- **Accurate countdown:** based on the real clock, so it does not drift and stays correct after sleep
- **Progress bar** and the exact time the action will run
- **Remembers an active timer:** reopen the script and it shows what is running
- **Repeat last custom time** with one key
- **Themes:** red (default), green, blue, aqua, yellow, classic
- **Default action:** choose what the timer does when you open it or run it from the command line
- **Skip the confirmation screen** if you prefer one-key timers
- **Reset to defaults** from the Settings menu
- **Command-line mode** for shortcuts and scripts
- Does **not** force-close your apps unless you turn on Force mode

---

## 🚀 Usage

1. Download `ShutdownTimer.bat`.
2. Double-click it.
3. Pick an option from the menu.

### Command line

```bat
ShutdownTimer.bat 45                   :: shutdown in 45 minutes
ShutdownTimer.bat 1h30m restart        :: restart in 1 hour 30 minutes
ShutdownTimer.bat at 11:30pm sleep     :: sleep at 11:30 PM
ShutdownTimer.bat status               :: show the active timer
ShutdownTimer.bat cancel               :: cancel the active timer
ShutdownTimer.bat help                 :: show usage
ShutdownTimer.bat version              :: show the version
```

Actions: `shutdown` `restart` `sleep` `hibernate` `lock` `logoff`
If you leave the action out, your **default action** from Settings is used (`shutdown` until you change it).

---

## 🧠 How it works

| Action | Scheduled by | Survives closing the window |
|---|---|---|
| Shutdown, Restart | Windows itself (`shutdown /t`) | ✅ Yes |
| Sleep, Hibernate, Lock, Log off | A small hidden PowerShell helper | ✅ Yes (not through log off or reboot) |

To cancel, run the script again and choose **Active timer → Cancel**, press **C** on the countdown screen, or run `ShutdownTimer.bat cancel`.

---

## ⚙️ Settings

| Setting | Default | Description |
|---|---|---|
| Theme | Red | Console colour theme |
| Force-close apps | OFF | When ON, open apps are closed without asking (`/f`) |
| Warning popups | ON | Notifications 5 min and 1 min before the action |
| Default action | Shutdown | Used at start-up and when no action is given on the command line |
| Ask before starting | ON | Show the confirmation screen before a timer starts |
| Reset all settings | - | Restores every setting above and clears the saved last custom time |

Settings and the active timer are saved in `%APPDATA%\DevFahimShutdownTimer`.

---

## 📋 Requirements

- Windows 10 or 11
- Windows PowerShell 5.1 (built into Windows)
- Hibernate must be enabled in Windows to use the Hibernate action (`powercfg /h on` in an admin prompt)

---

## ❓ FAQ

**Does it need administrator rights?**
No. If your PC is managed by a work or school policy that restricts shutdown rights, try running it as administrator.

**Windows says an app is preventing shutdown.**
Force mode is off by default so you do not lose unsaved work. Turn it on in **Settings** if you want apps closed automatically.

**Why does it create a PowerShell file?**
The script writes a small helper to `%APPDATA%\DevFahimShutdownTimer` for time calculations and warnings. Security software may notice the hidden PowerShell process. This is expected.

---

## 📝 Changelog

**v2.1**
- Added a version number (shown in the banner and with `ShutdownTimer.bat version`)
- New settings: default action, ask-before-starting toggle, reset all settings

**v2.0**
- Six actions, clock-time mode, flexible custom input, extend, warning popups, progress bar, themes, command-line mode
- Removed forced app closing by default (now opt-in)
- Real-clock countdown that no longer drifts

---

## 👤 Author

**Dev-Fahim-Code**
GitHub: [github.com/dev-fahim-code](https://github.com/dev-fahim-code)

## 📄 License

Add a `LICENSE` file (MIT is a common choice for scripts) and mention it here.
