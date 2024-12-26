#!/usr/bin/env bash

# Source the kumander script
source ./kumander.sh

# Create a temporary directory for test commands
TEST_DIR=$(mktemp -d)
export KUMANDER_COMMANDS_DIR="$TEST_DIR"

# Clean up function
cleanup() {
    rm -rf "$TEST_DIR"
}

# Set up trap to clean up on exit
trap cleanup EXIT

# Test helper function
assert() {
    if [ "$1" = "$2" ]; then
        echo -e "\033[0;32mPASS\033[0m: $3"
    else
        echo -e "\033[0;31mFAIL\033[0m: $3"
        echo "  Expected: $2"
        echo "  Got: $1"
    fi
}

# Function to create test command files
create_test_files() {
    cat << EOF > "$TEST_DIR/test1.md"
## command1
Description for command1
\`\`\`bash
echo "Executing command1"
\`\`\`

## command2
Description for command2
\`\`\`bash
echo "Executing command2"
\`\`\`
EOF

    cat << EOF > "$TEST_DIR/test2.md"
## hello
Say hello
\`\`\`bash
echo "Hello, World!"
\`\`\`
EOF
}

# Function to run tests
run_tests() {
    # Test 1: List files
    result=$(kumander | grep -c "test[12]")
    assert "$result" "2" "List files"

    # Test 2: List commands in a file
    result=$(kumander test1 | grep -c "command[12]")
    assert "$result" "2" "List commands in test1"

    # Test 3: Execute a command
    result=$(kumander test1 command1)
    assert "$result" "Executing command1" "Execute command1 in test1"

    # Test 4: Execute a command from another file
    result=$(kumander test2 hello)
    assert "$result" "Hello, World!" "Execute hello command in test2"

    # Test 5: Try to execute a non-existent command
    result=$(kumander test1 nonexistent 2>&1 | grep -c "Error: Command 'nonexistent' not found")
    assert "$result" "1" "Execute non-existent command"

    # Test 6: Try to access a non-existent file
    result=$(kumander nonexistent 2>&1 | grep -c "Error: File 'nonexistent' not found")
    assert "$result" "1" "Access non-existent file"
}

# Main function
main() {
    create_test_files
    run_tests
    echo "All tests completed."
}

main