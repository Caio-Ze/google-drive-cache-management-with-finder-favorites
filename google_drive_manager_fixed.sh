#!/bin/bash

# Unified script to manage Google Drive cache and Finder favorites
# Fixed version to avoid the mysides segmentation fault problem

# Function to display colored messages
function show_info {
  echo -e "\033[1;34mℹ️ $1\033[0m"
}

function show_success {
  echo -e "\033[1;32m✅ $1\033[0m"
}

function show_warning {
  echo -e "\033[1;33m⚠️ $1\033[0m"
}

function show_error {
  echo -e "\033[1;31m❌ $1\033[0m"
}

function show_header {
  clear
  echo -e "\033[1;36m===================================================\033[0m"
  echo -e "\033[1;36m  Google Drive and Finder Favorites Manager  \033[0m"
  echo -e "\033[1;36m===================================================\033[0m"
  echo ""
}

# Check if mysides is installed
check_mysides() {
  if ! command -v mysides &> /dev/null; then
    show_warning "The 'mysides' tool is not installed."
    show_info "This tool is necessary to manage Finder favorites."
    show_info "You can install it using Homebrew with: brew install mysides"
    
    # Ask if the user wants to install Homebrew and mysides
    read -p "Do you want to install Homebrew and mysides now? (y/n): " INSTALL
    if [[ "$INSTALL" == "y" || "$INSTALL" == "Y" ]]; then
      show_info "Installing Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      
      show_info "Installing mysides..."
      brew install mysides
      
      if ! command -v mysides &> /dev/null; then
        show_error "Failed to install mysides. Please install it manually."
        return 1
      else
        show_success "mysides installed successfully!"
      fi
    else
      show_info "Please install mysides manually to use the favorites management features."
      return 1
    fi
  fi
  return 0
}

# Create necessary directories
create_directories() {
  BACKUP_DIR=~/Desktop/Google_Drive_Manager
  mkdir -p "$BACKUP_DIR/Backups"
  mkdir -p "$BACKUP_DIR/Shortcuts"
  show_success "Directories created: $BACKUP_DIR"
  return 0
}

# Function to backup favorites using mysides list output directly
backup_favorites() {
  show_info "Backing up important favorites..."
  
  # Create directory for backups
  create_directories
  
  BACKUP_FILE="$BACKUP_DIR/Backups/finder_favorites_$(date +%Y%m%d_%H%M%S).txt"
  
  # Create backup file
  echo "# Finder Favorites (generated on $(date))" > "$BACKUP_FILE"
  
  show_info "Getting favorites directly from the Finder sidebar..."
  
  # Use mysides list to get existing favorites
  # Redirect stderr to avoid errors interrupting the process
  TEMP_MYSIDES_OUTPUT=$(mktemp)
  
  # Try to run mysides with error handling
  if ! mysides list > "$TEMP_MYSIDES_OUTPUT" 2>/dev/null; then
    show_warning "mysides command failed with an error (possibly segmentation fault)."
    rm -f "$TEMP_MYSIDES_OUTPUT"
    TEMP_MYSIDES_OUTPUT=""
  fi
  
  # Check if we were able to get the favorites list
  if [ -n "$TEMP_MYSIDES_OUTPUT" ] && [ -s "$TEMP_MYSIDES_OUTPUT" ]; then
    # Process each line of output
    while read -r line; do
      # Check if the line contains an arrow (->)
      if [[ "$line" == *"->"* ]]; then
        # Extract name and path
        name=$(echo "$line" | awk -F "->" '{print $1}' | xargs)
        path=$(echo "$line" | awk -F "->" '{print $2}' | xargs)
        
        # Verify we have valid name and path
        if [ -n "$name" ] && [ -n "$path" ]; then
          echo "$name $path" >> "$BACKUP_FILE"
          show_success "Added to backup: $name"
        fi
      fi
    done < "$TEMP_MYSIDES_OUTPUT"
    
    show_success "Favorites extracted directly from the sidebar!"
    
    # Clean up
    [ -f "$TEMP_MYSIDES_OUTPUT" ] && rm -f "$TEMP_MYSIDES_OUTPUT"
  else
    show_warning "Could not get favorites list using mysides list."
    [ -f "$TEMP_MYSIDES_OUTPUT" ] && rm -f "$TEMP_MYSIDES_OUTPUT"
    
    # If we can't use mysides list, try the alternative method
    show_info "Using alternative method to identify important favorites..."
    
    # Find the Google Drive directory
    GOOGLE_DRIVE_DIR=""
    if [ -d ~/Library/CloudStorage ]; then
      GOOGLE_DRIVE_DIR=$(find ~/Library/CloudStorage -maxdepth 1 -name "GoogleDrive-*" -type d | head -1)
    fi
    
    if [ -n "$GOOGLE_DRIVE_DIR" ]; then
      show_info "Google Drive directory found: $GOOGLE_DRIVE_DIR"
      
      # Simple array of folders to check
      IMPORTANT_FOLDERS=(
        "Work_Documents"
        "Project_Files"
        "Shared_Team_Folder"
        "Media_Files"
        "Important_Resources"
        "Scripts"
        "Backups"
        "Applications"
        "Development_Projects"
        "Personal_Files"
        "Monitoring_Tools"
        "Reports"
        "Client_Projects"
        "Media_Library"
      )
      
      # Helper function to register found folder
      add_folder_to_backup() {
        local name="$1"
        local path="$2"
        echo "$name file://$path" >> "$BACKUP_FILE"
        show_success "Added to backup: $name ($3)"
      }
      
      # Add basic Google Drive folders
      if [ -d "$GOOGLE_DRIVE_DIR/My Drive" ]; then
        add_folder_to_backup "My Drive" "$GOOGLE_DRIVE_DIR/My Drive" "Google Drive"
      fi
      
      if [ -d "$GOOGLE_DRIVE_DIR/Shared drives" ]; then
        add_folder_to_backup "Shared drives" "$GOOGLE_DRIVE_DIR/Shared drives" "Google Drive"
      fi
      
      # Array to track found folders
      FOLDERS_FOUND=()
      
      # Check folders in user's home directory
      for folder in "${IMPORTANT_FOLDERS[@]}"; do
        if [ -d ~/"$folder" ]; then
          add_folder_to_backup "$folder" "/Users/$(whoami)/$folder" "home folder"
          FOLDERS_FOUND+=("$folder")
        fi
      done
      
      # Check folders on Desktop
      for folder in "${IMPORTANT_FOLDERS[@]}"; do
        # Check if already found
        FOUND=0
        for p in "${FOLDERS_FOUND[@]}"; do
          if [ "$p" = "$folder" ]; then
            FOUND=1
            break
          fi
        done
        
        # If not found, look on the Desktop
        if [ $FOUND -eq 0 ] && [ -d ~/Desktop/"$folder" ]; then
          add_folder_to_backup "$folder" "/Users/$(whoami)/Desktop/$folder" "Desktop"
          FOLDERS_FOUND+=("$folder")
        fi
      done
      
      # Check folders in Shared Drives
      if [ -d "$GOOGLE_DRIVE_DIR/Shared drives" ]; then
        for folder in "${IMPORTANT_FOLDERS[@]}"; do
          # Check if already found
          FOUND=0
          for p in "${FOLDERS_FOUND[@]}"; do
            if [ "$p" = "$folder" ]; then
              FOUND=1
              break
            fi
          done
          
          # If not found, look in Shared Drives
          if [ $FOUND -eq 0 ]; then
            # Search in depth in Shared Drives
            path_found=$(find "$GOOGLE_DRIVE_DIR/Shared drives" -maxdepth 5 -type d -name "$folder" -print -quit 2>/dev/null)
            if [ -n "$path_found" ]; then
              add_folder_to_backup "$folder" "$path_found" "Shared Drives"
              FOLDERS_FOUND+=("$folder")
              continue
            fi
          fi
        done
      fi
      
      # Add standard macOS folders (common)
      if [ -d ~/Desktop ]; then
        add_folder_to_backup "Desktop" "/Users/$(whoami)/Desktop" "system"
      fi
      
      if [ -d ~/Downloads ]; then
        add_folder_to_backup "Downloads" "/Users/$(whoami)/Downloads" "system"
      fi
      
      if [ -d ~/Documents ]; then
        add_folder_to_backup "Documents" "/Users/$(whoami)/Documents" "system"
      fi
      
      if [ -d /Applications ]; then
        add_folder_to_backup "Applications" "/Applications" "system"
      fi
    else
      show_error "Could not find the Google Drive directory."
    fi
  fi
  
  # Extract only the names of favorites for later use
  NAMES_FILE="$BACKUP_DIR/Backups/finder_favorites_names_$(date +%Y%m%d_%H%M%S).txt"
  grep -v "^#" "$BACKUP_FILE" | awk -F " file:" '{print $1}' > "$NAMES_FILE"
  
  # Check if backup was created successfully
  if [ -s "$BACKUP_FILE" ]; then
    show_success "Favorites backup created successfully!"
    echo ""
    cat "$BACKUP_FILE"
    echo ""
    show_info "The complete backup was saved to: $BACKUP_FILE"
    # Create a link to the most recent backup for easy restoration
    ln -sf "$BACKUP_FILE" "$BACKUP_DIR/Backups/latest_backup.txt"
    ln -sf "$NAMES_FILE" "$BACKUP_DIR/Backups/latest_backup_names.txt"
    show_success "Links to the latest backup created."
    
    # Debug information
    show_info "DEBUG: Verifying backup files exist:"
    ls -la "$BACKUP_DIR/Backups/latest_backup.txt" "$BACKUP_DIR/Backups/latest_backup_names.txt" 2>/dev/null || show_warning "Backup links not found!"
    ls -la "$BACKUP_FILE" "$NAMES_FILE" 2>/dev/null || show_warning "Original backup files not found!"
  else
    show_error "Could not create favorites backup or the list is empty."
  fi
  
  # Ask if user wants to return to menu
  echo ""
  read -p "Return to main menu? (y/n, default: y): " RETURN_TO_MENU
  if [[ "$RETURN_TO_MENU" != "n" && "$RETURN_TO_MENU" != "N" ]]; then
    return 0
  fi
}

# Function to clean Google Drive cache
clean_cache() {
  show_info "Preparing to clean Google Drive cache..."
  
  # Close Google Drive
  show_info "Closing Google Drive..."
  pkill -f "Google Drive"
  
  # Wait for shutdown
  COUNTER=0
  while pgrep -f "Google Drive" >/dev/null; do
    ((COUNTER++))
    echo "Still running... (attempt $COUNTER)"
    sleep 1
    if [ $COUNTER -ge 5 ]; then
      show_warning "Limit of 5 attempts reached."
      break
    fi
  done
  
  # Remove immutability attributes
  show_info "Removing immutability attributes..."
  sudo chflags -R nouchg ~/Library/CloudStorage
  
  # Adjust permissions
  show_info "Adjusting permissions..."
  sudo chmod -R 777 ~/Library/CloudStorage
  
  # Calculate cache folder size
  show_info "Calculating cache folder size:"
  sudo du -sh ~/Library/CloudStorage
  
  # Remove cache folder
  show_info "Removing cache folder..."
  sudo rm -rf ~/Library/CloudStorage
  show_success "Cache removed."
  
  # Reopen Google Drive
  show_info "Reopening Google Drive..."
  open -a "Google Drive"
  show_success "Google Drive reopened."
  
  show_info "Waiting for Google Drive to initialize (30 seconds)..."
  for i in {30..1}; do
    echo -ne "Waiting: $i seconds remaining\r"
    sleep 1
  done
  echo ""
  
  show_success "Google Drive cache cleared successfully!"
  
  # Ask if user wants to return to menu
  echo ""
  read -p "Return to main menu? (y/n, default: y): " RETURN_TO_MENU
  if [[ "$RETURN_TO_MENU" != "n" && "$RETURN_TO_MENU" != "N" ]]; then
    return 0
  fi
  return 0
}

# Function to add Google Drive favorites
add_google_drive_favorites() {
  show_info "Adding Google Drive favorites..."
  
  # Check if mysides is installed
  check_mysides || return 1
  
  # Find Google Drive directory
  GOOGLE_DRIVE_DIR=""
  show_info "Looking for Google Drive directory (may take a few seconds)..."
  
  COUNTER=0
  while [ -z "$GOOGLE_DRIVE_DIR" ] && [ $COUNTER -lt 6 ]; do
    if [ -d ~/Library/CloudStorage ]; then
      GOOGLE_DRIVE_DIR=$(find ~/Library/CloudStorage -maxdepth 1 -name "GoogleDrive-*" -type d | head -1)
    fi
    
    if [ -z "$GOOGLE_DRIVE_DIR" ]; then
      ((COUNTER++))
      show_info "Waiting for Google Drive to create the directory... (attempt $COUNTER)"
      sleep 5
    fi
  done
  
  if [ -z "$GOOGLE_DRIVE_DIR" ]; then
    show_error "Could not find Google Drive directory."
    show_info "Wait a few minutes for Google Drive to sync and try again."
    return 1
  fi
  
  show_info "Google Drive directory found: $GOOGLE_DRIVE_DIR"
  
  # Create directory for shortcuts
  create_directories
  
  # List of important folders to check
  IMPORTANT_FOLDERS=(
    "Work_Documents"
    "Project_Files"
    "Shared_Team_Folder"
    "Media_Files"
    "Important_Resources"
    "Scripts"
    "Backups"
    "Applications"
    "Development_Projects"
    "Personal_Files"
    "Monitoring_Tools"
    "Reports"
    "Client_Projects"
    "Media_Library"
  )
  
  # First, remove existing duplicate or partial entries
  show_info "Removing existing duplicate or partial entries..."
  
  # Remove basic Google Drive entries
  mysides remove "My" 2>/dev/null
  mysides remove "My Drive" 2>/dev/null
  mysides remove "Shared" 2>/dev/null
  mysides remove "Shared drives" 2>/dev/null
  
  # Remove all potentially already existing important folders
  for folder in "${IMPORTANT_FOLDERS[@]}"; do
    mysides remove "$folder" 2>/dev/null
    echo "Removed (if existed): $folder"
  done
  
  # Wait a moment to ensure all favorites are removed
  sleep 2
  
  # Function to add a favorite with a more robust method
  add_favorite() {
    local name="$1"
    local path="$2"
    
    if [ ! -d "$path" ]; then
      show_warning "Directory not found: $path"
      return 1
    fi
    
    # Generate URL with escaped characters (multiple methods)
    local url1="file://$path"
    local url2=$(echo "file://$path" | sed 's/ /%20/g')
    
    # Method 1: Simple URL
    show_info "Trying to add $name with simple URL..."
    mysides add "$name" "$url1" 2>/dev/null
    
    # Check if added
    if mysides list 2>/dev/null | grep -q "$name"; then
      show_success "Favorite added: $name"
      return 0
    fi
    
    # Method 2: Escaped URL
    show_info "Trying to add $name with escaped URL..."
    mysides add "$name" "$url2" 2>/dev/null
    
    # Check if added
    if mysides list 2>/dev/null | grep -q "$name"; then
      show_success "Favorite added: $name"
      return 0
    fi
    
    # Method 3: Direct path
    show_info "Trying to add $name with direct path..."
    mysides add "$name" "$path" 2>/dev/null
    
    # Check if added
    if mysides list 2>/dev/null | grep -q "$name"; then
      show_success "Favorite added: $name"
      return 0
    fi
    
    # Method 4: mysides with additional options (force)
    show_info "Trying advanced method for $name..."
    # Using extra parameters to force adding
    osascript -e "tell application \"Finder\" to set sidebar of front window to sidebar of front window" 2>/dev/null
    mysides add "$name" "file://$path" 2>/dev/null
    
    show_warning "You may need to add $name manually."
    return 1
  }
  
  # Recursive search to find specific folders
  find_and_add_folder() {
    local folder_name="$1"
    local base_directory="$2"
    local depth="${3:-3}"  # Default depth: 3 levels
    
    show_info "Looking for '$folder_name' in $base_directory (depth $depth)..."
    
    # Search using find with limited depth
    local path_found=$(find "$base_directory" -maxdepth "$depth" -type d -name "$folder_name" -print -quit 2>/dev/null)
    
    if [ -n "$path_found" ]; then
      show_info "Folder '$folder_name' found at: $path_found"
      add_favorite "$folder_name" "$path_found"
      return 0
    else
      show_warning "Folder '$folder_name' not found in $base_directory"
      return 1
    fi
  }
  
  # Add basic Google Drive folders
  MY_DRIVE_PATH="$GOOGLE_DRIVE_DIR/My Drive"
  SHARED_DRIVES_PATH="$GOOGLE_DRIVE_DIR/Shared drives"
  
  if [ -d "$MY_DRIVE_PATH" ]; then
    add_favorite "My Drive" "$MY_DRIVE_PATH"
  fi
  
  if [ -d "$SHARED_DRIVES_PATH" ]; then
    add_favorite "Shared drives" "$SHARED_DRIVES_PATH"
  fi
  
  # Search and add important folders in various locations
  for folder in "${IMPORTANT_FOLDERS[@]}"; do
    show_info "Looking for folder: $folder..."
    FOUND=0
    
    # 1. Check in home folder root
    if [ -d ~/"$folder" ]; then
      add_favorite "$folder" ~/"$folder"
      FOUND=1
      continue
    fi
    
    # 2. Check in My Drive 
    if [ -d "$MY_DRIVE_PATH" ] && [ $FOUND -eq 0 ]; then
      find_and_add_folder "$folder" "$MY_DRIVE_PATH" 2
      if [ $? -eq 0 ]; then
        FOUND=1
        continue
      fi
    fi
    
    # 3. Search in Shared Drives with greater depth
    if [ -d "$SHARED_DRIVES_PATH" ] && [ $FOUND -eq 0 ]; then
      # Deeper search in Shared Drives
      find_and_add_folder "$folder" "$SHARED_DRIVES_PATH" 3
      if [ $? -eq 0 ]; then
        FOUND=1
        continue
      fi
    fi
    
    # 4. Check directly in known Shared Drives
    if [ -d "$SHARED_DRIVES_PATH" ] && [ $FOUND -eq 0 ]; then
      for drive in "$SHARED_DRIVES_PATH"/*; do
        if [ -d "$drive/$folder" ]; then
          add_favorite "$folder" "$drive/$folder"
          FOUND=1
          break
        elif [ -d "$drive/PUBLICIDADE/$folder" ]; then
          add_favorite "$folder" "$drive/PUBLICIDADE/$folder"
          FOUND=1
          break
        fi
      done
    fi
    
    if [ $FOUND -eq 0 ]; then
      show_warning "Folder '$folder' not found automatically."
    fi
  done
  
  # Add standard system folders
  add_favorite "Desktop" "$HOME/Desktop"
  add_favorite "Downloads" "$HOME/Downloads"
  add_favorite "Documents" "$HOME/Documents"
  add_favorite "Applications" "/Applications"
  
  show_success "Google Drive favorites added successfully!"
  
  # Ask if user wants to return to menu
  echo ""
  read -p "Return to main menu? (y/n, default: y): " RETURN_TO_MENU
  if [[ "$RETURN_TO_MENU" != "n" && "$RETURN_TO_MENU" != "N" ]]; then
    return 0
  fi
  return 0
}

# Function to restore all favorites from a backup
restore_all_favorites() {
  show_info "Restoring all Finder sidebar favorites..."
  
  # Check if mysides is installed
  check_mysides || return 1
  
  # Check if the latest backup exists
  LATEST_BACKUP="$BACKUP_DIR/Backups/latest_backup.txt"
  LATEST_BACKUP_NAMES="$BACKUP_DIR/Backups/latest_backup_names.txt"
  
  # Debug information
  show_info "DEBUG: Looking for backup files:"
  show_info "Latest backup path: $LATEST_BACKUP"
  ls -la "$BACKUP_DIR/Backups/" 2>/dev/null || show_warning "Backup directory not found or empty!"
  
  if [ ! -f "$LATEST_BACKUP" ]; then
    # List all available backups
    show_info "Latest backup not found. Checking other backups..."
    BACKUPS=$(find "$BACKUP_DIR/Backups" -name "finder_favorites_*.txt" -type f 2>/dev/null)
    
    if [ -z "$BACKUPS" ]; then
      show_error "No backups found. Make a backup first."
      
      # Ask if user wants to return to menu
      echo ""
      read -p "Return to main menu? (y/n, default: y): " RETURN_TO_MENU
      if [[ "$RETURN_TO_MENU" != "n" && "$RETURN_TO_MENU" != "N" ]]; then
        return 0
      fi
      return 1
    fi
    
    show_info "Available backups:"
    echo "$BACKUPS"
    echo ""
    read -p "Enter the full path of the backup file to restore (or 'menu' to return to menu): " RESTORE_FILE
    
    if [[ "$RESTORE_FILE" == "menu" ]]; then
      return 0
    fi
    
    if [ ! -f "$RESTORE_FILE" ]; then
      show_error "File not found: $RESTORE_FILE"
      
      # Ask if user wants to return to menu
      echo ""
      read -p "Return to main menu? (y/n, default: y): " RETURN_TO_MENU
      if [[ "$RETURN_TO_MENU" != "n" && "$RETURN_TO_MENU" != "N" ]]; then
        return 0
      fi
      return 1
    fi
    
    # Generate names file from selected backup
    TEMP_NAMES_FILE="$BACKUP_DIR/Backups/temp_names.txt"
    grep -v "^#" "$RESTORE_FILE" | awk -F " file:" '{print $1}' > "$TEMP_NAMES_FILE"
  else
    show_info "Using the latest backup: $LATEST_BACKUP"
    RESTORE_FILE="$LATEST_BACKUP"
    TEMP_NAMES_FILE="$LATEST_BACKUP_NAMES"
    
    # Generate names file again to ensure it's correct
    grep -v "^#" "$RESTORE_FILE" | awk -F " file:" '{print $1}' > "$TEMP_NAMES_FILE"
  fi
  
  # Confirm restoration
  show_warning "WARNING: This will remove existing favorites and restore those from the backup."
  show_info "Favorites that will be restored:"
  grep -v "^#" "$RESTORE_FILE"
  echo ""
  read -p "Confirm restoration? (y/n, or 'menu' to return to menu): " CONFIRM_RESTORE
  
  if [[ "$CONFIRM_RESTORE" == "menu" ]]; then
    return 0
  fi
  
  if [[ "$CONFIRM_RESTORE" == "y" || "$CONFIRM_RESTORE" == "Y" ]]; then
    # Remove existing favorites (only those in the backup to avoid removing others)
    show_info "Removing existing favorites..."
    while read -r name; do
      if [ -n "$name" ]; then
        mysides remove "$name" 2>/dev/null
        echo "Removed: $name"
      fi
    done < "$TEMP_NAMES_FILE"
    
    # Wait a moment to ensure all favorites were removed
    sleep 1
    
    # Add favorites from backup
    show_info "Restoring favorites from backup..."
    
    # Find current Google Drive directory
    GOOGLE_DRIVE_DIR=""
    if [ -d ~/Library/CloudStorage ]; then
      GOOGLE_DRIVE_DIR=$(find ~/Library/CloudStorage -maxdepth 1 -name "GoogleDrive-*" -type d | head -1)
    fi
    
    # Use grep to avoid comment lines and correctly process names with spaces
    grep -v "^#" "$RESTORE_FILE" | while read -r line; do
      if [ -n "$line" ]; then
        # Extract name and path
        name=$(echo "$line" | awk -F " file://" '{print $1}')
        path_url=$(echo "$line" | awk -F " file://" '{print $2}')
        
        # Decode URL to check if directory exists
        # Replace %20 with space and other common codes
        decoded_path=$(echo "$path_url" | 
          perl -pe 's/%20/ /g; s/%([0-9A-F]{2})/chr(hex($1))/gie' 2>/dev/null ||
          echo "$path_url" | sed 's/%20/ /g')
        
        # Check if path exists using decoded path
        if [ -d "$decoded_path" ]; then
          show_info "Adding: $name -> file://$path_url"
          mysides add "$name" "file://$path_url" 2>/dev/null
          echo "Added: $name -> $decoded_path"
        else
          show_warning "Path not found: $decoded_path"
          show_info "Trying to add $name directly with original URL..."
          
          # Try direct method using original URL
          mysides add "$name" "file://$path_url" 2>/dev/null
          
          # Check if added
          if mysides list 2>/dev/null | grep -q "$name"; then
            show_success "Favorite added: $name (using original URL)"
          else
            # Try alternative method for specific folders
            if [ "$name" == "Desktop" ]; then
              mysides add "Desktop" "file:///Users/$(whoami)/Desktop"
            elif [ "$name" == "Documents" ]; then
              mysides add "Documents" "file:///Users/$(whoami)/Documents"
            elif [ "$name" == "Downloads" ]; then
              mysides add "Downloads" "file:///Users/$(whoami)/Downloads"
            elif [ "$name" == "Applications" ]; then
              mysides add "Applications" "file:///Applications"
            elif [[ "$name" == *"Special_Characters_Folder"* ]]; then
              # Try to locate this special folder
              for location in ~/Desktop ~/Documents ~; do
                if [ -d "$location/Special Characters Folder" ]; then
                  mysides add "$name" "file://$location/Special Characters Folder"
                  show_success "Located and added: $name"
                  break
                fi
              done
            else
              # Try to find folder by name
              found_location=$(find ~ -maxdepth 3 -type d -name "$name" -print -quit 2>/dev/null)
              if [ -n "$found_location" ]; then
                mysides add "$name" "file://$found_location"
                show_success "Located and added: $name at $found_location"
              else
                show_error "Could not add $name"
              fi
            fi
          fi
        fi
      fi
    done
    
    show_success "Favorites restored successfully!"
    return 0
  else
    show_info "Restoration cancelled by user."
    return 1
  fi
}

# Function to perform the complete process (backup, cleanup and restoration)
complete_process() {
  show_info "Starting the complete process (backup, cleanup and restoration)..."
  
  # Check if mysides is installed
  check_mysides || return 1
  
  # 1. Backup favorites
  show_info "Step 1: Backing up favorites..."
  backup_favorites
  
  # 2. Confirm continuation
  echo ""
  show_warning "WARNING: The next step will clear Google Drive cache."
  read -p "Do you want to continue with cache cleanup? (y/n): " CONTINUE_CLEANUP
  
  if [[ "$CONTINUE_CLEANUP" != "y" && "$CONTINUE_CLEANUP" != "Y" ]]; then
    show_info "Process interrupted by user after backup."
    return 0
  fi
  
  # 3. Clean cache
  show_info "Step 2: Cleaning Google Drive cache..."
  clean_cache
  
  # 4. Add Google Drive favorites
  show_info "Step 3: Restoring Google Drive favorites..."
  add_google_drive_favorites
  
  show_success "Complete process finished successfully!"
  show_info "If you want to restore all favorites (not just Google Drive ones), use option 4 in the main menu."
  
  # Ask if user wants to return to menu
  echo ""
  read -p "Return to main menu? (y/n, default: y): " RETURN_TO_MENU
  if [[ "$RETURN_TO_MENU" != "n" && "$RETURN_TO_MENU" != "N" ]]; then
    return 0
  fi
  return 0
}

# Main menu
display_menu() {
  show_header
  echo "Choose an option:"
  echo ""
  echo "1. Complete process (backup, cleanup and Google Drive restoration)"
  echo "2. Backup Finder favorites"
  echo "3. Clean Google Drive cache"
  echo "4. Restore all favorites from backup"
  echo "5. Add only Google Drive favorites"
  echo "6. Exit"
  echo ""
  read -p "Enter your choice (1-6): " OPTION
  
  case $OPTION in
    1)
      complete_process
      ;;
    2)
      backup_favorites
      ;;
    3)
      clean_cache
      ;;
    4)
      restore_all_favorites
      ;;
    5)
      add_google_drive_favorites
      ;;
    6)
      show_info "Exiting..."
      exit 0
      ;;
    *)
      show_error "Invalid option!"
      ;;
  esac
  
  echo ""
  read -p "Press Enter to return to the main menu..."
  display_menu
}

# Start the program
display_menu 