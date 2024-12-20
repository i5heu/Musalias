#!/bin/bash

# Script Name: show_contents.sh
# Description: Outputs all text-based file contents in the current directory recursively,
#              prefixing each with its filepath. Excludes specified patterns and can
#              optionally clean the content by removing excessive whitespace and line breaks.
# Usage: ./show_contents.sh [-e pattern1,pattern2,...] [-c]

# -------------------- Configuration --------------------

# Default exclude patterns
DEFAULT_EXCLUDES=(
    "go.sum"
    "go.mod"
    "vendor/*"
    ".git/*"
    "node_modules/*"
    "dist/*"
    "build/*"
    "*.log"
    "*.tmp"
    "*.bak"
    "*.swp"
    "package-lock.json"
    "yarn.lock"
    "pnpm-lock.yaml"
    "coverage/*"
    "public/*"
    "tmp/*"
    "cache/*"
    "*.exe"
    "*.dll"
    "*.so"
    "*.dylib"
    "*.bin"
    "*.class"
    "*.jar"
    "*.pyc"
    "*.o"
    "*.out"
    "*.obj"
    "*.pdb"
    "*.lock"
    "*.sqlite"
)

# Initialize variables
EXCLUDE_PATTERNS=("${DEFAULT_EXCLUDES[@]}")
CLEAN_CONTENT=false

# Output file
OUTPUT_FILE="showContentsOutput.txt"
if ! touch "$OUTPUT_FILE" 2>/dev/null; then
    echo "Warning: Could not write to $OUTPUT_FILE. Will write to stdout." >&2
else
    exec 1> "$OUTPUT_FILE"
fi

# -------------------- Functions --------------------

# Function to display usage
usage() {
    echo "Usage: $0 [-e pattern1,pattern2,...] [-c]"
    echo "  -e : Comma-separated list of glob patterns to exclude (overrides default excludes)"
    echo "  -c : Clean content by removing excessive whitespace and line breaks"
    echo
    echo "Example:"
    echo "  $0 -e \"*.env,*.secret\" -c"
    exit 1
}

# Function to check if a command exists
check_command() {
    local cmd="$1"
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: Required command '$cmd' is not installed or not in PATH." >&2
        echo "Please install '$cmd' and try again." >&2
        exit 1
    fi
}

# -------------------- Dependency Checks --------------------

# Check for required commands
REQUIRED_COMMANDS=("find" "file" "awk" "grep")
for cmd in "${REQUIRED_COMMANDS[@]}"; do
    check_command "$cmd"
done

# -------------------- Option Parsing --------------------

# Parse options
while getopts ":e:c" opt; do
    case ${opt} in
        e )
            IFS=',' read -ra ADDR <<< "$OPTARG"
            EXCLUDE_PATTERNS=("${ADDR[@]}")
            ;;
        c )
            CLEAN_CONTENT=true
            ;;
        \? )
            echo "Invalid Option: -$OPTARG" >&2
            usage
            ;;
        : )
            echo "Invalid Option: -$OPTARG requires an argument" >&2
            usage
            ;;
    esac
done
shift $((OPTIND -1))

# -------------------- File Discovery --------------------

# Build the find command with exclude patterns
FIND_CMD=(find . -type f)
FIND_CMD+=(! -name "showContentsOutput.txt")
for pattern in "${EXCLUDE_PATTERNS[@]}"; do
    FIND_CMD+=(! -path "./$pattern")
done

# Execute find and store files
mapfile -t FILES < <("${FIND_CMD[@]}")

# -------------------- Processing Files --------------------

# Iterate over each file
for file in "${FILES[@]}"; do
    # Check if the file is text-based using MIME type
    MIME_TYPE=$(file -b --mime-type "$file")
    if [[ $MIME_TYPE != text/* ]]; then
        continue
    fi

    # Remove leading './' from filepath
    filepath="${file#./}"
    echo "## /$filepath"

    if [ "$CLEAN_CONTENT" = true ]; then
        # Remove trailing whitespace and condense multiple empty lines to a single empty line
        awk '{
            # Remove trailing whitespace
            sub(/[ \t]+$/, "");
            print
        }' "$file" | awk '
            BEGIN { empty=0 }
            /^$/ {
                empty++;
                if (empty <= 1) print
            }
            /^[^\t ]/ {
                empty=0
                print
            }
            /^[ \t]/ {
                empty=0
                print
            }
        '
    else
        cat "$file"
    fi

    echo    # Add a newline for readability
done
