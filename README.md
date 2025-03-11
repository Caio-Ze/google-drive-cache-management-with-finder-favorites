# Google Drive Manager

Script to manage Google Drive cache and Finder sidebar favorites on macOS.

## Features

- Backup of Finder sidebar favorites
- Google Drive cache cleanup
- Restoration of favorites after cleanup
- Automatic addition of important Google Drive favorites

## Requirements

- macOS
- Homebrew (optional, for installing mysides)
- `mysides` tool (will be automatically installed if necessary)

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

## License

This script is provided "as is", without warranties.

## Author

Created to manage Google Drive and its Finder favorites. 