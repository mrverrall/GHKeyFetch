#!/bin/bash

# Check if a username is provided as an argument
if [ $# -lt 1 ]; then
    echo "Usage: $0 <github-username> [-c|--confirm] [-a|--add] [-q|--quiet] [-v|--verbose]"
    exit 1
fi

# Variables
USERNAME="$1"
CONFIRM=false
ADD=false
QUIET=false
VERBOSE=false

# Parse additional arguments
for arg in "$@"; do
    case $arg in
        -c|--confirm)
            CONFIRM=true
            ;;
        -a|--add)
            ADD=true
            ;;
        -q|--quiet)
            QUIET=true
            ;;
        -v|--verbose)
            VERBOSE=true
            ;;
        *)
            ;;
    esac
done

# Validate the username
if [[ ! "$USERNAME" =~ ^[a-zA-Z0-9]+(-[a-zA-Z0-9]+)*$ ]]; then
    echo "Error: Invalid GitHub username. Only letters, numbers, and hyphens are allowed, and hyphens cannot be at the start or end." >&2
    exit 1
fi

GITHUB_URL="https://github.com/$USERNAME.keys"
AUTHORIZED_KEYS_FILE="$HOME/.ssh/authorized_keys"

# Create a secure temporary file
AUTHORIZED_KEYS_TEMP=$(mktemp /tmp/authorized_keys_temp.XXXXXX)

# Ensure all temporary files are removed on script exit
cleanup() {
    rm -f "$AUTHORIZED_KEYS_TEMP"
    [ -n "$AUTHORIZED_KEYS_FILE.new" ] && rm -f "${AUTHORIZED_KEYS_FILE}.new"
}
trap cleanup EXIT

# Function to fetch keys using curl
fetch_with_curl() {
    curl -sSf "$GITHUB_URL" -o "$AUTHORIZED_KEYS_TEMP"
}

# Function to fetch keys using wget
fetch_with_wget() {
    wget -qO "$AUTHORIZED_KEYS_TEMP" "$GITHUB_URL"
}

# Attempt to download the authorized_keys file using curl or wget
if command -v curl > /dev/null; then
    $VERBOSE && echo "Using curl to fetch keys..."
    fetch_with_curl
elif command -v wget > /dev/null; then
    $VERBOSE && echo "curl not found, using wget to fetch keys..."
    fetch_with_wget
else
    echo "Error: Neither curl nor wget is available. Please install one of these tools to proceed." >&2
    exit 1
fi

# Check if the download was successful
if [ ! -s "$AUTHORIZED_KEYS_TEMP" ]; then
    echo "Error: Failed to download the authorized_keys file from GitHub." >&2
    exit 1
fi

# Validate each SSH key in the downloaded file using ssh-keygen
VALID=true
while read -r line; do
    echo "$line" | ssh-keygen -l -f /dev/stdin > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "Validation failed: Invalid SSH key detected." >&2
        VALID=false
        break
    fi
done < "$AUTHORIZED_KEYS_TEMP"

if [ "$VALID" = true ]; then
    $VERBOSE && echo "All keys are valid."

    if [ "$CONFIRM" = true ]; then
        if [ "$ADD" = true ]; then
            $VERBOSE && echo "Adding new keys to existing authorized_keys file."
            # Count existing keys
            existing_count=$(grep -c "ssh-" "$AUTHORIZED_KEYS_FILE" 2>/dev/null || echo "0")
            # Concatenate the existing keys and new keys, then dedupe
            cat "$AUTHORIZED_KEYS_TEMP" "$AUTHORIZED_KEYS_FILE" 2>/dev/null | sort | uniq > "${AUTHORIZED_KEYS_FILE}.new"
            # Count total keys after addition and deduplication
            total_count=$(grep -c "ssh-" "${AUTHORIZED_KEYS_FILE}.new")
            # Calculate the number of keys added
            added_count=$((total_count - existing_count))
            mv "${AUTHORIZED_KEYS_FILE}.new" "$AUTHORIZED_KEYS_FILE"
        else
            $VERBOSE && echo "Replacing existing authorized_keys file with new keys."
            # Backup the current authorized_keys file (optional)
            if [ -f "$AUTHORIZED_KEYS_FILE" ]; then
                cp "$AUTHORIZED_KEYS_FILE" "$AUTHORIZED_KEYS_FILE.bak"
            fi
            # Count the number of keys to be added
            added_count=$(grep -c "ssh-" "$AUTHORIZED_KEYS_TEMP")
            mv "$AUTHORIZED_KEYS_TEMP" "$AUTHORIZED_KEYS_FILE"
        fi

        # Set the correct permissions
        chmod 600 "$AUTHORIZED_KEYS_FILE"
        $VERBOSE && echo "The authorized_keys file has been updated successfully."
        
        # Report keys added if greater than zero (default mode) or in verbose mode
        if [ "$added_count" -gt 0 ]; then
            $QUIET || echo "Keys added: $added_count"
        fi
    else
        $VERBOSE && echo "Confirmation switch not provided. Skipping the update of the authorized_keys file."
    fi
else
    echo "Validation failed: No valid SSH key entries found." >&2
    exit 1
fi

# Exit with a success status code
exit 0
