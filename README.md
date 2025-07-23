# Cursor Device ID Reset Tool

A comprehensive tool to reset Cursor editor device IDs with enhanced TUI (Text User Interface) and backup functionality.

## Features

- 🎯 **Interactive TUI**: Menu-driven interface using dialog/whiptail when available
- 🔒 **Automatic Backups**: Creates timestamped backups before making changes
- 🌍 **Cross-Platform**: Supports Linux, macOS, and Windows (WSL/Cygwin/MSYS2)
- 📋 **View Current IDs**: Display existing device IDs before resetting
- 📁 **Backup Management**: List and manage backup files
- 🎨 **Colorized Output**: Beautiful colored output for better readability
- ⚡ **Fast & Reliable**: Pure bash implementation with error handling

## Available Scripts

### Shell Script (Recommended) - `reset_cursor.sh`
Enhanced version with TUI and additional features:
- Interactive menu system
- Backup management
- Colored output
- Better error handling
- Cross-platform compatibility

### Python Script - `reset_cursor.py`
Original simple version for basic functionality.

## Quick Installation

### Automatic Installation (Recommended)

```bash
# Run the installation script
./install.sh
```

The installer will:
- Detect your operating system
- Install optional dependencies (dialog, jq, uuidgen)
- Make scripts executable
- Optionally install to your PATH

### Manual Installation

#### Prerequisites
- **bash** (available on all Unix-like systems)
- **dialog** or **whiptail** (optional, for enhanced TUI)
- **jq** (optional, for JSON parsing - will fallback without it)
- **uuidgen** (optional, for UUID generation - will fallback without it)

#### Running the Shell Script

```bash
# Make executable (if not already)
chmod +x reset_cursor.sh

# Run the script
./reset_cursor.sh
```

### Installing Optional Dependencies

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install dialog jq uuid-runtime
```

**CentOS/RHEL/Fedora:**
```bash
# Fedora
sudo dnf install dialog jq util-linux

# CentOS/RHEL
sudo yum install dialog jq util-linux
```

**macOS:**
```bash
brew install dialog jq
```

### Running the Python Script

```bash
# Ensure Python 3 is installed
python3 reset_cursor.py
```

## How It Works

1. **Detects your OS** and locates the Cursor storage file:
   - **Linux**: `~/.config/Cursor/User/globalStorage/storage.json`
   - **macOS**: `~/Library/Application Support/Cursor/User/globalStorage/storage.json`
   - **Windows**: `%APPDATA%/Cursor/User/globalStorage/storage.json`

2. **Creates a backup** (shell script only) with timestamp in the format:
   `storage_backup_YYYYMMDD_HHMMSS.json`

3. **Generates new random device IDs**:
   - `telemetry.machineId`: 64-character hex string
   - `telemetry.macMachineId`: 64-character hex string  
   - `telemetry.devDeviceId`: UUID v4 format

4. **Updates the storage file** with the new IDs

## Menu Options (Shell Script)

1. **Show current device IDs** - Display existing IDs without making changes
2. **Reset device IDs (with backup)** - Create backup and generate new IDs
3. **Create backup only** - Backup current configuration without resetting
4. **List available backups** - Show all backup files with timestamps
5. **About this tool** - Display tool information
6. **Exit** - Quit the application

## File Structure

```
reset_cursor/
├── README.md           # This documentation
├── install.sh          # Automatic installation script
├── reset_cursor.py     # Original Python version
└── reset_cursor.sh     # Enhanced shell script version
```

## Backup Location

Backups are stored in:
- **Linux**: `~/.config/Cursor/User/globalStorage/backups/`
- **macOS**: `~/Library/Application Support/Cursor/User/globalStorage/backups/`
- **Windows**: `%APPDATA%/Cursor/User/globalStorage/backups/`

## Safety Features

- ✅ **Automatic backups** before any changes
- ✅ **Confirmation prompts** for destructive operations
- ✅ **Error handling** with clear messages
- ✅ **Directory creation** if paths don't exist
- ✅ **Graceful fallbacks** when optional tools are missing

## Troubleshooting

### "Command not found" errors
The script will work without optional dependencies but with reduced functionality:
- Without `dialog`/`whiptail`: Falls back to simple text menu
- Without `jq`: Uses basic JSON manipulation
- Without `uuidgen`: Generates UUID manually

### Permission errors
Ensure the script has execute permissions:
```bash
chmod +x reset_cursor.sh
```

### Storage file not found
The script will create the necessary directories and files if they don't exist.

## License

This project is open source. Feel free to modify and distribute.

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for bugs and feature requests.
