# Google Drive Cache Management with Finder Favorites Backup and Preservation

Self-contained macOS application and script to manage Google Drive cache and Finder sidebar favorites.

## Features

- Backup of Finder sidebar favorites before cache cleanup
- Google Drive cache cleanup with optimization
- Automatic restoration of favorites after cleanup
- Built-in sidebartool for Finder sidebar management
- Forceful termination of Google Drive processes when needed
- Self-contained macOS application with no external dependencies
- Fully compatible with latest macOS versions (Monterey to Sequoia)

## Installation Options

### Option 1: Use the App Bundle (Recommended)

1. Download the `GoogleDriveManager.dmg` file
2. Mount the DMG and drag `GoogleDriveManagerApp.app` to your Applications folder
3. Right-click on the app and select "Open" to bypass Gatekeeper on first run

### Option 2: Run the Script Directly

```bash
chmod +x google_drive_manager_fixed.sh
./google_drive_manager_fixed.sh
```

## Usage

The interactive menu offers these options:

1. Complete process (backup, cleanup, and restoration)
2. Backup Finder favorites
3. Clean Google Drive cache
4. Restore favorites from backup
5. Add only Google Drive favorites
6. Forcefully kill Google Drive processes
7. Exit

## Notes

- Backups are stored in `~/Desktop/Google_Drive_Manager/Backups/`
- The app bundle includes all necessary dependencies (including sidebartool)
- Compatible with macOS 12 Monterey, 13 Ventura, 14 Sonoma, 15 Sequoia
- Works with Google Drive for Desktop 52.0.6+ and Google Drive File Stream 45.0.12+

## Versions

- **v1.0-v1.3**: Initial versions with basic features and improvements
- **v2.0**: Added self-contained macOS application with bundled dependencies
- **v2.1**: Improved compatibility with macOS Sonoma and Sequoia, added force kill option

## Contributing

Contributions welcome! Fork the repository, create a feature branch, and open a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

Created by Caio Raphael to manage Google Drive cache and preserve Finder favorites on macOS. 