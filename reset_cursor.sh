#!/bin/bash

# Cursor Device ID Reset Tool with Enhanced TUI
# Author: Converted from Python script
# Description: Reset Cursor editor device IDs with backup functionality

set -euo pipefail

# Color codes for better visual output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

# Global variables
STORAGE_FILE=""
BACKUP_DIR=""
DIALOG_AVAILABLE=false

# Check if dialog/whiptail is available for TUI
check_dialog_availability() {
    if command -v dialog >/dev/null 2>&1; then
        DIALOG_AVAILABLE=true
        DIALOG_CMD="dialog"
    elif command -v whiptail >/dev/null 2>&1; then
        DIALOG_AVAILABLE=true
        DIALOG_CMD="whiptail"
    else
        DIALOG_AVAILABLE=false
    fi
}

# Print colored text
print_colored() {
    local color=$1
    local text=$2
    echo -e "${color}${text}${NC}"
}

# Print header
print_header() {
    clear
    print_colored "$CYAN" "╔══════════════════════════════════════════════════════════════╗"
    print_colored "$CYAN" "║              🎯 Cursor Device ID Reset Tool                  ║"
    print_colored "$CYAN" "║                     Enhanced TUI Version                    ║"
    print_colored "$CYAN" "╚══════════════════════════════════════════════════════════════╝"
    echo
}

# Show error message
show_error() {
    local message=$1
    if [ "$DIALOG_AVAILABLE" = true ]; then
        $DIALOG_CMD --title "Error" --msgbox "$message" 8 60
    else
        print_colored "$RED" "❌ Error: $message"
        echo
        read -p "Press Enter to continue..."
    fi
}

# Show success message
show_success() {
    local message=$1
    if [ "$DIALOG_AVAILABLE" = true ]; then
        $DIALOG_CMD --title "Success" --msgbox "$message" 8 60
    else
        print_colored "$GREEN" "✅ $message"
        echo
        read -p "Press Enter to continue..."
    fi
}

# Show info message
show_info() {
    local message=$1
    if [ "$DIALOG_AVAILABLE" = true ]; then
        $DIALOG_CMD --title "Information" --msgbox "$message" 10 70
    else
        print_colored "$BLUE" "ℹ️  $message"
        echo
        read -p "Press Enter to continue..."
    fi
}

# Confirm action
confirm_action() {
    local message=$1
    if [ "$DIALOG_AVAILABLE" = true ]; then
        $DIALOG_CMD --title "Confirmation" --yesno "$message" 8 60
        return $?
    else
        print_colored "$YELLOW" "⚠️  $message"
        read -p "Do you want to continue? (y/N): " -n 1 -r
        echo
        [[ $REPLY =~ ^[Yy]$ ]]
    fi
}

# Get storage file path based on OS
get_storage_file() {
    local os_type=$(uname -s)
    case "$os_type" in
        "Linux")
            STORAGE_FILE="$HOME/.config/Cursor/User/globalStorage/storage.json"
            BACKUP_DIR="$HOME/.config/Cursor/User/globalStorage/backups"
            ;;
        "Darwin")
            STORAGE_FILE="$HOME/Library/Application Support/Cursor/User/globalStorage/storage.json"
            BACKUP_DIR="$HOME/Library/Application Support/Cursor/User/globalStorage/backups"
            ;;
        "CYGWIN"*|"MINGW"*|"MSYS"*)
            STORAGE_FILE="$APPDATA/Cursor/User/globalStorage/storage.json"
            BACKUP_DIR="$APPDATA/Cursor/User/globalStorage/backups"
            ;;
        *)
            show_error "Unsupported operating system: $os_type"
            exit 1
            ;;
    esac
}

# Create backup of storage file
backup_storage_file() {
    if [ -f "$STORAGE_FILE" ]; then
        local timestamp=$(date +"%Y%m%d_%H%M%S")
        local backup_file="$BACKUP_DIR/storage_backup_$timestamp.json"
        
        mkdir -p "$BACKUP_DIR"
        cp "$STORAGE_FILE" "$backup_file"
        print_colored "$GREEN" "✅ Backup created: $(basename "$backup_file")"
        return 0
    else
        print_colored "$YELLOW" "⚠️  Storage file doesn't exist, no backup needed"
        return 1
    fi
}

# Generate random hex string
generate_hex() {
    local length=$1
    od -An -tx1 -N$((length/2)) /dev/urandom | tr -d ' \n'
}

# Generate UUID v4
generate_uuid() {
    if command -v uuidgen >/dev/null 2>&1; then
        uuidgen | tr '[:upper:]' '[:lower:]'
    else
        # Generate UUID manually if uuidgen is not available
        local hex=$(generate_hex 32)
        echo "${hex:0:8}-${hex:8:4}-4${hex:13:3}-$(printf '%x' $((0x8 + RANDOM % 4)))${hex:17:3}-${hex:20:12}"
    fi
}

# Reset device IDs
reset_device_ids() {
    print_colored "$BLUE" "🔄 Generating new device IDs..."
    
    # Generate new IDs
    local machine_id=$(generate_hex 64)
    local mac_machine_id=$(generate_hex 64)
    local dev_device_id=$(generate_uuid)
    
    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$STORAGE_FILE")"
    
    # Read existing data or create new
    local temp_file=$(mktemp)
    if [ -f "$STORAGE_FILE" ]; then
        cp "$STORAGE_FILE" "$temp_file"
    else
        echo '{}' > "$temp_file"
    fi
    
    # Update the JSON file using jq if available, otherwise use sed
    if command -v jq >/dev/null 2>&1; then
        jq --arg mid "$machine_id" \
           --arg mmid "$mac_machine_id" \
           --arg ddid "$dev_device_id" \
           '. + {"telemetry.machineId": $mid, "telemetry.macMachineId": $mmid, "telemetry.devDeviceId": $ddid}' \
           "$temp_file" > "$STORAGE_FILE"
    else
        # Fallback method without jq
        cat > "$STORAGE_FILE" << EOF
{
  "telemetry.machineId": "$machine_id",
  "telemetry.macMachineId": "$mac_machine_id",
  "telemetry.devDeviceId": "$dev_device_id"
}
EOF
    fi
    
    rm "$temp_file"
    
    # Display results
    local result_text="🎉 Device IDs have been successfully reset!

New Device IDs:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Machine ID: $machine_id
Mac Machine ID: $mac_machine_id
Device ID: $dev_device_id
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Storage file: $STORAGE_FILE"
    
    if [ "$DIALOG_AVAILABLE" = true ]; then
        $DIALOG_CMD --title "Success - IDs Reset" --msgbox "$result_text" 15 80
    else
        print_colored "$GREEN" "$result_text"
        echo
        read -p "Press Enter to continue..."
    fi
}

# Show current device IDs
show_current_ids() {
    if [ ! -f "$STORAGE_FILE" ]; then
        show_info "Storage file doesn't exist yet. No device IDs are currently set."
        return
    fi
    
    local current_ids=""
    if command -v jq >/dev/null 2>&1; then
        local machine_id=$(jq -r '.["telemetry.machineId"] // "Not set"' "$STORAGE_FILE")
        local mac_machine_id=$(jq -r '.["telemetry.macMachineId"] // "Not set"' "$STORAGE_FILE")
        local dev_device_id=$(jq -r '.["telemetry.devDeviceId"] // "Not set"' "$STORAGE_FILE")
        
        current_ids="Current Device IDs:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Machine ID: $machine_id
Mac Machine ID: $mac_machine_id
Device ID: $dev_device_id
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Storage file: $STORAGE_FILE"
    else
        current_ids="Storage file exists at: $STORAGE_FILE

Note: Install 'jq' for detailed ID display"
    fi
    
    show_info "$current_ids"
}

# List available backups
list_backups() {
    if [ ! -d "$BACKUP_DIR" ]; then
        show_info "No backup directory found. No backups available."
        return
    fi
    
    local backup_files=($(ls -1t "$BACKUP_DIR"/storage_backup_*.json 2>/dev/null || true))
    
    if [ ${#backup_files[@]} -eq 0 ]; then
        show_info "No backup files found in: $BACKUP_DIR"
        return
    fi
    
    local backup_list="Available Backups (newest first):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    for backup in "${backup_files[@]}"; do
        local filename=$(basename "$backup")
        local date_str=$(echo "$filename" | sed 's/storage_backup_\(.*\)\.json/\1/')
        local formatted_date=$(echo "$date_str" | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)_\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1-\2-\3 \4:\5:\6/')
        backup_list+="\n• $filename ($formatted_date)"
    done
    
    backup_list+="\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Backup directory: $BACKUP_DIR"
    
    show_info "$backup_list"
}

# Main menu for dialog/whiptail
show_dialog_menu() {
    while true; do
        local choice
        choice=$($DIALOG_CMD --clear --title "Cursor Device ID Reset Tool" \
            --menu "Choose an option:" 15 60 6 \
            "1" "Show current device IDs" \
            "2" "Reset device IDs (with backup)" \
            "3" "Create backup only" \
            "4" "List available backups" \
            "5" "About this tool" \
            "6" "Exit" 3>&1 1>&2 2>&3)
        
        case $choice in
            1) show_current_ids ;;
            2) 
                if confirm_action "This will reset all Cursor device IDs and create a backup. Continue?"; then
                    backup_storage_file
                    reset_device_ids
                fi
                ;;
            3) 
                backup_storage_file
                show_success "Backup created successfully!"
                ;;
            4) list_backups ;;
            5) show_info "Cursor Device ID Reset Tool v2.0

This tool helps you reset Cursor editor device IDs by:
• Creating timestamped backups
• Generating new random device IDs
• Updating the storage configuration

Compatible with Linux, macOS, and Windows.
Requires: bash, basic Unix tools" ;;
            6|"") break ;;
        esac
    done
}

# Simple menu for terminals without dialog
show_simple_menu() {
    while true; do
        print_header
        print_colored "$WHITE" "Select an option:"
        echo
        print_colored "$CYAN" "1) Show current device IDs"
        print_colored "$CYAN" "2) Reset device IDs (with backup)"
        print_colored "$CYAN" "3) Create backup only"
        print_colored "$CYAN" "4) List available backups"
        print_colored "$CYAN" "5) About this tool"
        print_colored "$CYAN" "6) Exit"
        echo
        read -p "Enter your choice (1-6): " choice
        echo
        
        case $choice in
            1) show_current_ids ;;
            2) 
                if confirm_action "This will reset all Cursor device IDs and create a backup."; then
                    backup_storage_file
                    reset_device_ids
                fi
                ;;
            3) 
                backup_storage_file
                show_success "Backup created successfully!"
                ;;
            4) list_backups ;;
            5) 
                print_colored "$BLUE" "ℹ️  Cursor Device ID Reset Tool v2.0

This tool helps you reset Cursor editor device IDs by:
• Creating timestamped backups  
• Generating new random device IDs
• Updating the storage configuration

Compatible with Linux, macOS, and Windows.
Requires: bash, basic Unix tools"
                echo
                read -p "Press Enter to continue..."
                ;;
            6) 
                print_colored "$GREEN" "👋 Goodbye!"
                exit 0
                ;;
            *) 
                show_error "Invalid choice. Please select 1-6."
                ;;
        esac
    done
}

# Main execution
main() {
    # Check dependencies
    check_dialog_availability
    
    # Get storage file path
    get_storage_file
    
    # Show appropriate menu
    if [ "$DIALOG_AVAILABLE" = true ]; then
        show_dialog_menu
    else
        show_simple_menu
    fi
}

# Handle script interruption
trap 'echo -e "\n${RED}Script interrupted by user${NC}"; exit 130' INT

# Run main function
main "$@"
