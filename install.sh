#!/bin/bash

# Exit on error. Append "|| true" if you expect an error.
set -e
# Exit on error in pipeline.
set -o pipefail
# Treat unset variables as an error.
set -u

kumander_install() {
    # Initialize color variables
    local RED='\033[0;31m'
    local GREEN='\033[0;32m'
    local BLUE='\033[0;34m'
    local NC='\033[0m' # No Color

    # Print colored output
    print_message() {
        local color_var="$1"
        local message="$2"
        case "$color_var" in
            "RED") echo -e "${RED}${message}${NC}" ;;
            "GREEN") echo -e "${GREEN}${message}${NC}" ;;
            "BLUE") echo -e "${BLUE}${message}${NC}" ;;
            *) echo "$message" ;;
        esac
    }

    # Setup downloader command
    setup_downloader() {
        local downloader
        if command -v curl >/dev/null 2>&1; then
            downloader="curl -fsSL"
        elif command -v wget >/dev/null 2>&1; then
            downloader="wget -qO-"
        else
            print_message "RED" "Error: Neither curl nor wget found. Please install one of them first."
            exit 1
        fi
        echo "$downloader"
    }

    # Detect shell and OS
    detect_shell_config() {
        local shell_config=""
        
        # First check if we're on macOS
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # Check current shell on macOS
            local current_shell
            current_shell=$(dscl . -read /Users/$USER UserShell || echo "")
            
            if [ -f "$HOME/.zshrc" ] && [[ "$current_shell" == *"zsh"* ]]; then
                shell_config="$HOME/.zshrc"
            else
                shell_config="$HOME/.bash_profile"
            fi
        else
            # For other Unix systems
            if [ -f "$HOME/.zshrc" ] && [[ "$SHELL" == *"zsh"* ]]; then
                shell_config="$HOME/.zshrc"
            else
                shell_config="$HOME/.bashrc"
            fi
        fi
        
        echo "$shell_config"
    }

    # Check if configuration already exists in shell config
    config_exists() {
        local config_file="$1"
        grep -q "KUMANDER_COMMANDS_DIR" "$config_file" && grep -q "source.*kumander.sh" "$config_file"
    }

    # Main installation logic
    local DOWNLOADER
    DOWNLOADER=$(setup_downloader)
    
    print_message "BLUE" "Installing Kumander..."
    
    # Create installation directory
    local INSTALL_DIR="$HOME/.kumander"
    mkdir -p "$INSTALL_DIR"
    
    # Backup existing commands if they exist
    if [ -d "$INSTALL_DIR/commands" ]; then
        print_message "BLUE" "Backing up existing commands directory..."
        mv "$INSTALL_DIR/commands" "$INSTALL_DIR/commands.bak"
    fi
    
    # Download files from GitHub
    print_message "BLUE" "Downloading Kumander from GitHub..."
    
    $DOWNLOADER https://github.com/christopheredrian/kumander/archive/main.tar.gz | tar xz -C "$INSTALL_DIR" --strip-components=1
    
    if [ $? -ne 0 ]; then
        print_message "RED" "Error: Failed to download and extract Kumander."
        # Restore commands backup if it exists
        if [ -d "$INSTALL_DIR/commands.bak" ]; then
            mv "$INSTALL_DIR/commands.bak" "$INSTALL_DIR/commands"
        fi
        exit 1
    fi
    
    # Make scripts executable
    chmod +x "$INSTALL_DIR/kumander.sh"
    
    # Restore commands from backup if it exists
    if [ -d "$INSTALL_DIR/commands.bak" ]; then
        print_message "BLUE" "Restoring commands from backup..."
        rm -rf "$INSTALL_DIR/commands"
        mv "$INSTALL_DIR/commands.bak" "$INSTALL_DIR/commands"
    else
        # Create commands directory only if it doesn't exist
        mkdir -p "$INSTALL_DIR/commands"
    fi
    
    # Setup shell configuration
    local CONFIG_FILE
    CONFIG_FILE=$(detect_shell_config)
    
    # Only add configuration if it doesn't exist
    if ! config_exists "$CONFIG_FILE"; then
        print_message "BLUE" "Adding Kumander configuration to $CONFIG_FILE..."
        {
            echo ""
            echo "# Kumander Configuration"
            echo "export KUMANDER_COMMANDS_DIR=\"\$HOME/.kumander/commands\""
            echo "alias km='kumander'"
            echo "source \$HOME/.kumander/kumander.sh"
        } >> "$CONFIG_FILE"
    else
        print_message "BLUE" "Kumander configuration already exists in $CONFIG_FILE"
    fi
    
    print_message "GREEN" "Kumander has been successfully installed!"
    print_message "BLUE" "Configuration file: $CONFIG_FILE"
    print_message "BLUE" "Please restart your shell or run: source $CONFIG_FILE"
    print_message "BLUE" "To get started, run: kumander --help"
}

# Run installation
kumander_install