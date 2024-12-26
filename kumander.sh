#!/bin/bash

# shellcheck disable=SC2016,SC2086
# Version: 1.0.0

# Color constants
readonly COLOR_RED="31"    # Error messages
readonly COLOR_GREEN="32"  # Success/Commands
readonly COLOR_YELLOW="33" # Warnings/Separators
readonly COLOR_BLUE="36"   # Info messages
readonly COLOR_WHITE="37"  # Normal text

kumander() {
    local VERBOSE=0
    local COMMANDS_DIR="${KUMANDER_COMMANDS_DIR:-~/.kumander/commands}"

    # Print colored output
    echo_color() {
        local color="$1"
        local message="$2"
        echo -e "\e[${color}m${message}\e[0m"
    }

    # Print error message in red
    error_message() {
        echo_color "$COLOR_RED" "Error: $1" >&2
    }

    # Print warning message in yellow
    warning_message() {
        echo_color "$COLOR_YELLOW" "Warning: $1"
    }

    usage() {
        echo_color "$COLOR_BLUE" "Usage: kumander [options] [file] [command]"
        echo_color "$COLOR_BLUE" "Options:"
        echo_color "$COLOR_BLUE" "  --help    Show this help message"
        echo_color "$COLOR_BLUE" "  --dir     Specify a custom commands directory"
        echo_color "$COLOR_BLUE" ""
        echo_color "$COLOR_BLUE" "If no arguments are provided, lists available files (without .md extension)."
        echo_color "$COLOR_BLUE" "If only a file is provided, lists commands in that file."
        echo_color "$COLOR_BLUE" "If both file and command are provided, executes the command."
    }

    extract_commands_and_descriptions() {
        local file="$1"
        # Using basename with quotes to handle filenames with spaces
        local filename
        filename=$(basename "$file" .md)
        # Using -v to safely pass variables to awk
        awk -v filename="$filename" '
        BEGIN { print filename "|Command|Description" }
        /^## / {
            if (NR > 1) printf "%s|%s|%s\n", filename, command, description
            command = substr($0, 4)
            description = ""
        }
        /^[^#]/ && description == "" { description = $0 }
        END { printf "%s|%s|%s\n", filename, command, description }
        ' "$file"
    }

    list_files() {
        echo_color "$COLOR_YELLOW" "----------------------------------------------------------------"
        echo_color "$COLOR_BLUE" "File specified not found, listing available files:"
        echo_color "$COLOR_YELLOW" "----------------------------------------------------------------"
        echo_color "$COLOR_BLUE" "Usage: kumander <file> <command>"
    
        if [ -d "$COMMANDS_DIR" ]; then
            # Added quotes around paths for better handling of spaces
            find "$COMMANDS_DIR" -type f -name "*.md" | while read -r file; do
                echo_color "$COLOR_GREEN" "$(basename "$file" .md)"
            done | sort | sed 's/^/  /'
        else
            echo_color "$COLOR_BLUE" "No markdown files found in $COMMANDS_DIR"
        fi
    }

    list_commands() {
        local file="$1"
        echo_color "$COLOR_YELLOW" "----------------------------------------------------------------"
        echo_color "$COLOR_BLUE" "Commands in $(basename "$file.md" .md):"
        echo_color "$COLOR_YELLOW" "----------------------------------------------------------------"
        echo_color "$COLOR_BLUE" "Usage: kumander <file> <command>\n"
        extract_commands_and_descriptions "$file" | awk -F'|' '{
            printf "\033[1;32m%-20s\033[0m \033[1;37m%-30s\033[0m \n", $2, $3
        }'
    }

    # Parse options
    while [[ "$1" =~ ^-- ]]; do
        case $1 in
            --help)
                usage
                return 0
                ;;
            --dir)
                if [ -z "$2" ] || [ "${2:0:1}" = "-" ]; then
                    error_message "--dir requires a valid directory path"
                    return 1
                fi
                COMMANDS_DIR="$2"
                shift 2
                ;;
            --verbose|-v)
                VERBOSE=1
                echo_color "$COLOR_BLUE" "Verbose mode enabled"
                shift
                ;;
            *)
                error_message "Unknown option: $1"
                usage
                return 1
                ;;
        esac
    done

    if [ ! -d "$COMMANDS_DIR" ]; then
        error_message "Commands directory '$COMMANDS_DIR' not found."
        return 1
    fi

    if [ $# -eq 0 ]; then
        list_files
        return 0
    fi

    local file="$COMMANDS_DIR/$1"
    if [[ ! "$file" =~ \.md$ ]]; then
        file="$file.md"
    fi

    if [ ! -f "$file" ]; then
        error_message "File '$1' not found in $COMMANDS_DIR."
        list_files
        return 1
    fi

    if [ $# -eq 1 ]; then
        list_commands "$file"
        return 0
    fi

    local command="$2"
    # Shift the arguments to remove the file and command
    shift 2

    local cmd
    # Note: The following awk script extracts bash commands from markdown code blocks
    cmd=$(awk -v cmd="$command" '
    /^## / {
        if ($0 == "## " cmd) {
            in_block = 1
            next
        } else {
            in_block = 0
        }
    }
    in_block && /^```bash/ {
        getline
        while ($0 != "```") {
            print
            getline
        }
        exit
    }
    ' "$file")

    if [ -n "$cmd" ]; then
        if [ "$VERBOSE" -eq 1 ]; then
            warning_message "⚠️  SECURITY WARNING ⚠️"
            warning_message "This command will be executed using eval, which can be dangerous if the command source is not trusted."
            warning_message "Only run commands from markdown files that you trust and have reviewed."
            echo_color "$COLOR_YELLOW" "Command to be executed:"
            echo_color "$COLOR_BLUE" "$cmd"
            echo_color "$COLOR_YELLOW" "----------------------------------------------------------------"
        fi

        # Note: eval is used here to execute markdown-sourced commands.
        # Security: Only use this with trusted markdown files.
        eval "$cmd"
    else
        error_message "Command '$command' not found in file $(basename "$file" .md)."
        return 1
    fi
}

# This line is optional, you can remove it if you only want to source the file
# If you keep it, the script will still work when executed directly
[[ "${BASH_SOURCE[0]}" == "${0}" ]] && kumander "$@"

# Add completions for kumander
_kumander_completions()
{
    COMPREPLY=()
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"

    local COMMANDS_DIR="${KUMANDER_COMMANDS_DIR:-$HOME/.kumander/commands}"

    case $COMP_CWORD in
        1)
            # Complete with available files (without .md extension)
            local files=$(find "$COMMANDS_DIR" -type f -name "*.md" -print0 | xargs -0 -n1 basename -s .md | sort)
            COMPREPLY=($(compgen -W "$files" -- "$cur"))
            ;;
        2)
            # Complete with commands from the specified file
            local file="$COMMANDS_DIR/${prev}.md"
            if [[ -f $file ]]; then
                local commands=$(awk '/^## / {print substr($0, 4)}' "$file")
                COMPREPLY=($(compgen -W "$commands" -- "$cur"))
            fi
            ;;
    esac
}

complete -F _kumander_completions kumander