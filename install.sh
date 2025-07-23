#!/bin/bash

# Installation script for Cursor Device ID Reset Tool
# This script will install optional dependencies and set up the tool

set -euo pipefail

# Color codes
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'

print_colored() {
    local color=$1
    local text=$2
    echo -e "${color}${text}${NC}"
}

print_header() {
    clear
    print_colored "$BLUE" "╔══════════════════════════════════════════════════════════════╗"
    print_colored "$BLUE" "║           🚀 Cursor Reset Tool - Installation               ║"
    print_colored "$BLUE" "╚══════════════════════════════════════════════════════════════╝"
    echo
}

detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Detect Linux distribution
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            echo "$ID"
        else
            echo "linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

install_dependencies() {
    local os=$(detect_os)
    
    print_colored "$YELLOW" "🔍 Detected OS: $os"
    echo
    
    case "$os" in
        "ubuntu"|"debian")
            print_colored "$BLUE" "📦 Installing dependencies for Ubuntu/Debian..."
            sudo apt update
            sudo apt install -y dialog jq uuid-runtime
            ;;
        "fedora")
            print_colored "$BLUE" "📦 Installing dependencies for Fedora..."
            sudo dnf install -y dialog jq util-linux
            ;;
        "centos"|"rhel")
            print_colored "$BLUE" "📦 Installing dependencies for CentOS/RHEL..."
            sudo yum install -y dialog jq util-linux
            ;;
        "arch")
            print_colored "$BLUE" "📦 Installing dependencies for Arch Linux..."
            sudo pacman -S --noconfirm dialog jq util-linux
            ;;
        "macos")
            if command -v brew >/dev/null 2>&1; then
                print_colored "$BLUE" "📦 Installing dependencies for macOS (via Homebrew)..."
                brew install dialog jq
            else
                print_colored "$RED" "❌ Homebrew not found. Please install Homebrew first:"
                echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
                return 1
            fi
            ;;
        *)
            print_colored "$YELLOW" "⚠️  Unknown OS. Please install these packages manually:"
            echo "   - dialog (or whiptail)"
            echo "   - jq"
            echo "   - uuid tools (uuidgen)"
            return 1
            ;;
    esac
}

check_dependencies() {
    print_colored "$BLUE" "🔍 Checking dependencies..."
    echo
    
    local missing=()
    
    # Check for dialog/whiptail
    if ! command -v dialog >/dev/null 2>&1 && ! command -v whiptail >/dev/null 2>&1; then
        missing+=("dialog/whiptail")
    else
        print_colored "$GREEN" "✅ TUI support: Available"
    fi
    
    # Check for jq
    if ! command -v jq >/dev/null 2>&1; then
        missing+=("jq")
    else
        print_colored "$GREEN" "✅ JSON processor: Available"
    fi
    
    # Check for uuidgen
    if ! command -v uuidgen >/dev/null 2>&1; then
        missing+=("uuidgen")
    else
        print_colored "$GREEN" "✅ UUID generator: Available"
    fi
    
    if [ ${#missing[@]} -eq 0 ]; then
        print_colored "$GREEN" "🎉 All dependencies are available!"
        return 0
    else
        print_colored "$YELLOW" "⚠️  Missing optional dependencies: ${missing[*]}"
        echo
        read -p "Would you like to install them? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_dependencies
            return $?
        else
            print_colored "$BLUE" "ℹ️  The tool will work with reduced functionality."
            return 0
        fi
    fi
}

setup_script() {
    print_colored "$BLUE" "🔧 Setting up the reset tool..."
    
    # Make script executable
    chmod +x reset_cursor.sh
    
    # Check if we can create a symlink in a PATH directory
    local bin_dirs=("/usr/local/bin" "$HOME/.local/bin" "$HOME/bin")
    local installed=false
    
    for bin_dir in "${bin_dirs[@]}"; do
        if [ -d "$bin_dir" ] && [ -w "$bin_dir" ]; then
            ln -sf "$(pwd)/reset_cursor.sh" "$bin_dir/reset-cursor"
            print_colored "$GREEN" "✅ Installed to: $bin_dir/reset-cursor"
            print_colored "$BLUE" "   You can now run: reset-cursor"
            installed=true
            break
        fi
    done
    
    if [ "$installed" = false ]; then
        print_colored "$YELLOW" "⚠️  Could not install to PATH. You can run the script with:"
        print_colored "$BLUE" "   ./reset_cursor.sh"
    fi
}

main() {
    print_header
    
    print_colored "$BLUE" "This installer will:"
    echo "• Check and install optional dependencies"
    echo "• Make the script executable"
    echo "• Optionally install to PATH"
    echo
    
    read -p "Continue with installation? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        print_colored "$YELLOW" "Installation cancelled."
        exit 0
    fi
    
    echo
    
    # Check and install dependencies
    if check_dependencies; then
        echo
        setup_script
        echo
        print_colored "$GREEN" "🎉 Installation completed successfully!"
        echo
        print_colored "$BLUE" "To run the tool:"
        if command -v reset-cursor >/dev/null 2>&1; then
            print_colored "$BLUE" "   reset-cursor"
        else
            print_colored "$BLUE" "   ./reset_cursor.sh"
        fi
    else
        print_colored "$RED" "❌ Installation failed."
        exit 1
    fi
}

main "$@"
