# Google Drive Cache Management with Finder Favorites Backup and Preservation

Script to manage Google Drive cache and Finder sidebar favorites on macOS.

## Why This Project Is Unique

This project offers a specialized end-to-end workflow that combines multiple functionalities:
- Backup of Finder sidebar favorites before cleanup
- Google Drive cache cleanup optimization
- Restoration of favorites after cleanup
- Automatic addition of important Google Drive favorites

## Features

- Backup of Finder sidebar favorites
- Google Drive cache cleanup
- Restoration of favorites after cleanup
- Automatic addition of important Google Drive favorites

## Requirements

- macOS
- Xcode Command Line Tools (for installing sidebartool)
- `sidebartool` (Script will offer to install it if necessary)

## Compatibility

- **macOS Versions**: 10.15 Catalina, 11 Big Sur, 12 Monterey
- **Google Drive Versions**: 
  - Google Drive for Desktop 52.0.6 - 70.0.2 (2022-2023)
  - Google Drive File Stream 45.0.12 and later
- **Note**: May work with newer versions, but has been specifically tested with these versions

## Usage

1. Make the script executable:
```bash
chmod +x google_drive_manager_fixed.sh
```

2. Run the script:
```bash
./google_drive_manager_fixed.sh
```

3. Follow the instructions in the interactive menu:
   - Option 1: Complete process (backup, cleanup, and restoration)
   - Option 2: Backup Finder favorites
   - Option 3: Clean Google Drive cache
   - Option 4: Restore favorites from backup
   - Option 5: Add only Google Drive favorites
   - Option 6: Exit

## Notes

- Backups are saved in `~/Desktop/Google_Drive_Manager/Backups/`
- Restoration uses the most recent backup by default
- If there are issues with automatic restoration, the script provides instructions for manually adding favorites

## Versions

- **v1.0**: Initial version with basic features
- **v1.1**: Fixed "segmentation fault" issue with mysides
- **v1.2**: Improvements in URL decoding and support for special characters
- **v1.3**: Translated menu and interface to English for better accessibility

## Latest Updates

- Menu and user interface translated to English
- Added version tracking with Git
- Published on GitHub for better version control and sharing

## Contributing

Contributions to improve the script are welcome! Feel free to:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

Created by Caio Raphael to manage Google Drive cache and preserve Finder favorites on macOS. 