#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Check if curl or wget is available
if command -v curl >/dev/null 2>&1; then
    DOWNLOADER="curl -fsSL"
elif command -v wget >/dev/null 2>&1; then
    DOWNLOADER="wget -qO-"
else
    print_message "$RED" "Error: Neither curl nor wget found. Please install one of them first."
    exit 1
fi

# Detect shell
detect_shell() {
    if [ -n "$ZSH_VERSION" ]; then
        echo "zsh"
    elif [ -n "$BASH_VERSION" ]; then
        echo "bash"
    else
        echo "unknown"
    fi
}

# Get shell config file path
get_shell_config() {
    local shell=$1
    local config_file=""
    
    case $shell in
        "zsh")
            config_file="$HOME/.zshrc"
            ;;
        "bash")
            if [[ "$OSTYPE" == "darwin"* ]]; then
                config_file="$HOME/.bash_profile"
            else
                config_file="$HOME/.bashrc"
            fi
            ;;
        *)
            print_message "$RED" "Error: Unsupported shell. Please manually add the configuration to your shell's config file."
            exit 1
            ;;
    esac
    
    echo "$config_file"
}

# Main installation
main() {
    print_message "$BLUE" "Installing Kumander..."
    
    # Create installation directory
    INSTALL_DIR="$HOME/.kumander"
    mkdir -p "$INSTALL_DIR"
    
    # Download files from GitHub
    print_message "$BLUE" "Downloading Kumander from GitHub..."
    
    $DOWNLOADER https://github.com/trenchapps/kumander/archive/main.tar.gz | tar xz -C "$INSTALL_DIR" --strip-components=1
    
    if [ $? -ne 0 ]; then
        print_message "$RED" "Error: Failed to download and extract Kumander."
        exit 1
    fi
    
    # Make scripts executable
    chmod +x "$INSTALL_DIR/kumander.sh"
    chmod +x "$INSTALL_DIR/install.sh"
    
    # Setup shell configuration
    SHELL_TYPE=$(detect_shell)
    CONFIG_FILE=$(get_shell_config "$SHELL_TYPE")
    
    # Add Kumander to PATH and set up environment
    {
        echo ""
        echo "# Kumander Configuration"
        echo "export KUMANDER_COMMANDS_DIR=\"\$HOME/.kumander/commands\""
        echo "source \$HOME/.kumander/kumander.sh"
    } >> "$CONFIG_FILE"
    
    print_message "$GREEN" "Kumander has been successfully installed!"
    print_message "$BLUE" "Please restart your shell or run: source $CONFIG_FILE"
    print_message "$BLUE" "To get started, run: kumander --help"
}

# Run installation
main 