# Windows Shutdown Timer ⏱️

A simple, lightweight Windows batch script for quick and convenient power management. Set up automatic shutdown with preset options or custom time without requiring administrator rights.

## Features

✅ **Preset Timers**: Quick shutdown options for 30 minutes, 1 hour, 2 hours, or 3 hours  
✅ **Custom Time**: Set any custom duration with hours and minutes  
✅ **Live Countdown Display**: Real-time timer showing remaining time and exact shutdown clock time  
✅ **Cancel Anytime**: Cancel scheduled shutdown at any point  
✅ **Survives Window Close**: Shutdown is scheduled with Windows directly, so it happens even if you close the script  
✅ **No Admin Required**: Runs as normal user without administrator rights  
✅ **No Dependencies**: Works standalone without extra files or installations  
✅ **Clean UI**: Centered console window with light-red theme for easy visibility  
✅ **User-Friendly**: Back button in custom menu, clear navigation options  
✅ **Non-Destructive**: Doesn't force-close any applications, giving you time to save work

## Requirements

- Windows 7 or later
- PowerShell (usually pre-installed on Windows)
- No administrator rights needed
- No additional software or dependencies

## Installation

1. **Download** the `Windows_Shutdown_Timer_v_0.1.bat` file
2. **Save** it to your desired location (Desktop, Documents, etc.)
3. **Run** the batch file by double-clicking it
4. That's it! No installation needed.

## Usage

### Quick Start

1. Run the batch file
2. Select an option from the menu:
   - **Option 1-4**: Preset timers (30 min, 1h, 2h, 3h)
   - **Option 5**: Custom time entry
   - **Option 6**: Cancel any scheduled shutdown
   - **Option 7**: Exit

3. Confirm your selection
4. Watch the countdown timer display

### Custom Time Entry

When selecting option 5:
1. Enter hours (0-23)
2. Enter minutes (0-59)
3. Type `B` at any prompt to return to main menu
4. Confirm your custom timer

### Canceling a Shutdown

**While countdown is showing:**
- Press `C` to cancel and return to menu

**Without running the script:**
1. Run the script again
2. Select option 6 (Cancel Any Scheduled Shutdown)
3. The scheduled shutdown will be cancelled

## How It Works

1. When you confirm a timer, the script schedules the shutdown directly with Windows using the `shutdown` command
2. This means the shutdown is now managed by Windows, not just the batch script
3. The countdown display shows real-time information and exact shutdown time
4. You can close the window, but the shutdown will still happen as scheduled with Windows
5. To cancel, use option 6 or press `C` during countdown

## Screenshots

The script displays a clean menu interface with:
- Centered window on your screen
- Light red theme for easy visibility
- Clear status information during countdown
- Exact shutdown time display

## Menu Structure

```
[1] Shutdown in 30 Minutes
[2] Shutdown in 1 Hour
[3] Shutdown in 2 Hours
[4] Shutdown in 3 Hours
[5] Custom Time (Set Hours + Minutes)
[6] Cancel Any Scheduled Shutdown
[7] Exit
```

## Keyboard Shortcuts

- **1-7**: Navigate menu
- **Y/N**: Confirm or cancel timer setup
- **B**: Back to main menu (in custom time entry)
- **C**: Cancel scheduled shutdown (during countdown)

## Troubleshooting

### "Could not schedule the shutdown" Error

**Possible causes:**
- Your PC is managed by a work/school policy that restricts shutdown rights
- Lack of permissions in your user account

**Solution:**
- Try running the script as Administrator
- Contact your system administrator for policy changes

### Script won't open

- Right-click the `.bat` file and select "Run as Administrator"
- Check if batch files are blocked by your security software
- Try disabling antivirus temporarily

### Timer doesn't work

- Ensure Windows updates are current
- PowerShell must be enabled and available
- Restart your computer and try again

## System Requirements

| Requirement | Details |
|---|---|
| **OS** | Windows 7 or later |
| **Architecture** | 32-bit or 64-bit |
| **Permissions** | Normal user rights (no admin required for normal operation) |
| **Dependencies** | PowerShell (pre-installed on Windows) |

## Important Notes

⚠️ **Once you confirm a timer, the shutdown is scheduled directly with Windows.** It will still happen even if you close this window.

🔔 **To cancel a shutdown:**
- Option 1: Run the script again and select option 6
- Option 2: Press `C` while the countdown window is open

📌 **Best Practice:** Save all your work before confirming a timer.

## Tested On

- Windows 7
- Windows 10
- Windows 11

## Contributing

Have an idea for improvement? Found a bug? 

Feel free to:
- Open an issue on GitHub
- Submit a pull request
- Join our community on Discord

## Version History

**v0.1** - Initial release
- Preset shutdown timers
- Custom time configuration
- Live countdown display
- Cancel functionality
- Clean UI with centered window

## License

[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](https://choosealicense.com/licenses/mit/)

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support, join our community:

[![Discord](https://img.shields.io/badge/Discord-%237289DA.svg?logo=discord&logoColor=white)](https://discord.gg/bb2k3w5Q5A)

## Author

- [@Dev-Fahim-Code](https://github.com/dev-fahim-code)
