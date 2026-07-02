#!/bin/bash

# Function Description:
# Lists all aliases and functions defined in the ~/.Musalias/aliases file.
# Usage:
#   listAliases            - Lists aliases and functions with their descriptions.
#   listAliases -v         - Displays the entire aliases file with syntax highlighting.
#   listAliases -m         - Prints in Markdown format (for README).
#   listAliases -H <word>  - Hint mode: plain text for zsh overlay (exact + up to -n suggestions)
#   listAliases -n <N>     - Limit number of suggestions in hint mode (default 3)

# Reset OPTIND to ensure getopts works correctly when sourced
OPTIND=1

# Initialize flags
LISTALIASES_VERBOSE=false
LISTALIASES_MARKDOWN=false
LISTALIASES_HINT_PREFIX=""
LISTALIASES_HINT_LIMIT=3

# Parse options
while getopts ":v:mn:H:" opt; do
    case $opt in
        v )
            LISTALIASES_VERBOSE=true
            echo "Verbose mode set"
            ;;
        m )
            LISTALIASES_MARKDOWN=true
            ;;
        n )
            LISTALIASES_HINT_LIMIT="$OPTARG"
            ;;
        H )
            LISTALIASES_HINT_PREFIX="$OPTARG"
            ;;
        \? )
            echo "Invalid option: -$OPTARG" >&2
            echo "Usage: listAliases [-v] [-m] [-H <prefix>] [-n <N>]"
            exit 2
            ;;
    esac
done
shift $((OPTIND -1))

ALIASES_FILE="$HOME/.Musalias/aliases"

# --- HINT MODE (for zsh status line) ------------------------------------------
if [ -n "$LISTALIASES_HINT_PREFIX" ]; then
    ALIASES_FILE="$HOME/.Musalias/aliases"

    if [ ! -f "$ALIASES_FILE" ]; then
        echo ""
        exit 0
    fi

    awk -v px="$LISTALIASES_HINT_PREFIX" '
        # Grab one-line comment above alias; trim leading/trailing space
        /^#/ {
            c = substr($0, 2)
            sub(/^[[:space:]]+/, "", c)
            sub(/[[:space:]]+$/, "", c)
            next
        }

        # Aliases
        /^alias[[:space:]]+[A-Za-z0-9_]+=*/ {
            name = $0
            sub(/^alias[[:space:]]+/, "", name)
            sub(/=.*/, "", name)

            desc = c
            sub(/^[[:space:]]+/, "", desc)   # trim left again just in case
            sub(/[[:space:]]+$/, "", desc)   # trim right
            c = ""

            if (name == px) {
                printf "0\t%s\t%s\n", name, desc
            } else if (index(name, px) == 1) {
                printf "1\t%s\t%s\n", name, desc
            }
        }
    ' "$ALIASES_FILE" \
    | sort -t$'\t' -k1,1n -k2,2 \
    | awk -v lim="$LISTALIASES_HINT_LIMIT" '
        function lineout(n, d,    s) {
            s = (length(d) ? n " — " d : n " —")
            return s
        }
        BEGIN { shown = 0; prefixes = 0 }
        {
            rank = $1; name = $2; $1=""; $2=""
            sub(/^\t+/, "")
            desc = $0
            sub(/^[[:space:]]+/, "", desc)
            sub(/[[:space:]]+$/, "", desc)

            if (rank == 0) {
                printf "%s", lineout(name, desc)
                shown = 1
            } else if (rank == 1 && prefixes < lim) {
                if (shown == 0) {
                    printf "%s", lineout(name, desc)
                    shown = 1
                    prefixes++
                } else {
                    printf "\n%s", lineout(name, desc)
                    prefixes++
                }
            }
        }
        END {
            if (shown == 0) print ""
            else            printf "\n"   # ensure trailing newline
        }
    '
    exit 0
fi
# -----------------------------------------------------------------------------


if [ "$LISTALIASES_VERBOSE" = true ]; then
    # Verbose mode: display the entire aliases file with syntax highlighting
    if command -v highlight &> /dev/null; then
        highlight -O ansi --syntax=sh "$ALIASES_FILE"
    else
        printf "Error: No syntax highlighter found. Install 'highlight' to use verbose mode. For Debian-based distros use:\n"
        printf "sudo apt install highlight\n" >&2
        printf "Would you like to install 'highlight' now? [Y/n]: "
        read -r response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]] || [ -z "$response" ]; then
            echo "Installing 'highlight'..."
            sudo apt install highlight
        else
            echo "Installation aborted by the user."
        fi
        exit 1
    fi

elif [ "$LISTALIASES_MARKDOWN" = true ]; then
    # Markdown mode: list aliases and functions with their comments

    # Check if the aliases file exists
    if [ ! -f "$ALIASES_FILE" ]; then
        echo "Error: Aliases file '$ALIASES_FILE' does not exist." >&2
        exit 1
    fi

    # Extract aliases with their comments
    awk '
        # Define the function in awk to handle comments
        function print_comment(comment, name) {
            len = length($0);
            spaces = "";
            for (i = 1; i <= len; i++) { spaces = spaces " " }

            if (comment != "") {
                options_index = index(comment, "Options:");
                if (options_index > 0) {
                    printf " -%s  \n", substr(comment, 1, options_index - 1);
                    options_part = substr(comment, options_index);
                    n = split(options_part, words, /[ \t]+/);
                    printf "%s\n", words[1];
                    for (i = 2; i <= n; i++) {
                        if (words[i] ~ /^-/) {
                            printf "   - **%s**", words[i];
                        } else {
                            printf "%s", words[i];
                        }
                        if (i < n && words[i+1] !~ /^-/) {
                            printf " ";
                        } else {
                            if (i != n) { printf "\n" }
                        }
                    }
                } else {
                    printf " -%s", comment;
                }
            }
        }

        /^##.*##$/ {
            if ($0 !~ /^#+$/) {
                if (match($0, /^##\s*(.*?)\s*##$/, arr)) {
                    printf "\n\n### %s", arr[1];
                }
            }
        }

        /^#/ { comment = substr($0, 2); next }

        /^alias/ {
            sub(/^alias\s+/, "");
            sub(/=.*/, "");
            printf "\n- **%s**", $0;
            if (comment != "") { print_comment(comment, $0) }
            comment = "";
        }

        /^[a-zA-Z_][a-zA-Z0-9_]*\s*\(\)\s*\{/ {
            if (match($0, /^([a-zA-Z_][a-zA-Z0-9_]*)\s*\(\)\s*\{/, arr)) {
                printf "\n- **%s**", arr[1];
            }
            if (comment != "") { print_comment(comment, arr[1]) }
            comment = "";
        }

    ' "$ALIASES_FILE"
    echo
    echo "
### Legend
Aliase marked with 👑 will call sudo"
    echo
else
    # Standard mode: list aliases and functions with their comments
    echo "Hint: To output the entire aliases file with syntax highlighting, use the -v option."
    echo "Available Aliases and Functions:"
    echo "---------------------------------"

    # Check if the aliases file exists
    if [ ! -f "$ALIASES_FILE" ]; then
        echo "Error: Aliases file '$ALIASES_FILE' does not exist." >&2
        exit 1
    fi

    # Extract aliases with their comments
    awk '
        function print_comment(comment, name) {
            len = length($0);
            spaces = "";
            for (i = 1; i <= len; i++) { spaces = spaces " " }

            if (comment != "") {
                options_index = index(comment, "Options:");
                if (options_index > 0) {
                    printf " -%s\n", substr(comment, 1, options_index - 1);
                    options_part = substr(comment, options_index);
                    n = split(options_part, words, /[ \t]+/);
                    printf "%s   %s", spaces, words[1];
                    for (i = 2; i <= n; i++) {
                        if (words[i] ~ /^-/) {
                            if (i == 2) {
                                printf " %s", words[i];
                            } else {
                                printf "%s            %s", spaces, words[i];
                            }
                        } else {
                            printf "%s", words[i];
                        }
                        if (i < n && words[i+1] !~ /^-/) {
                            printf " ";
                        } else {
                            if (i != n) { printf "\n" }
                        }
                    }
                } else {
                    printf " -%s", comment;
                }
            }
        }

        /^##.*##$/ {
            if ($0 !~ /^#+$/) {
                if (match($0, /^##\s*(.*?)\s*##$/, arr)) {
                    printf "\n\n\033[1m>\033[0m %s", arr[1];
                }
            }
        }

        /^#/ { comment = substr($0, 2); next }

        /^alias/ {
            sub(/^alias\s+/, "");
            sub(/=.*/, "");
            printf "\n    \033[1m%s\033[0m", $0;
            if (comment != "") { print_comment(comment, $0) }
            comment = "";
        }

        /^[a-zA-Z_][a-zA-Z0-9_]*\s*\(\)\s*\{/ {
            if (match($0, /^([a-zA-Z_][a-zA-Z0-9_]*)\s*\(\)\s*\{/, arr)) {
                printf "\n    \033[1m%s\033[0m", arr[1];
            }
            if (comment != "") { print_comment(comment, arr[1]) }
            comment = "";
        }

    ' "$ALIASES_FILE"
    echo
    echo
    echo "Aliase marked with 👑 will call sudo"
    echo
fi
