#!/bin/bash

# Function Description:
# Lists all aliases and functions defined in the ~/.Musalias/aliases file.
# Usage:
#   listAliases        - Lists aliases and functions with their descriptions.
#   listAliases -v     - Displays the entire aliases file with syntax highlighting.

# Reset OPTIND to ensure getopts works correctly when sourced
OPTIND=1

# Initialize flags
LISTALIASES_VERBOSE=false
LISTALIASES_MARKDOWN=false

# Parse options
while getopts ":v:m" opt; do
    case $opt in
        v )
            LISTALIASES_VERBOSE=true
            echo "Verbose mode set"
            ;;
        m )
            LISTALIASES_MARKDOWN=true
            echo "Markdown mode set"
            ;;
        \? )
            echo "Invalid option: -$OPTARG" >&2
            echo "Usage: listAliases [-v]"
            exit 2
            ;;
    esac
done
shift $((OPTIND -1))

if [ "$LISTALIASES_VERBOSE" = true ]; then
    # Verbose mode: display the entire aliases file with syntax highlighting
    if command -v highlight &> /dev/null; then
        highlight -O ansi --syntax=sh "$HOME/.Musalias/aliases"
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
        return 1
    fi

elif [ "$LISTALIASES_MARKDOWN" = true ]; then
    # Standard mode: list aliases and functions with their comments
    echo "Hint: To output the entire aliases file with syntax highlighting, use the -v option."
    echo "Available Aliases and Functions:"
    echo "---------------------------------"

    # Path to the aliases file
    ALIASES_FILE="$HOME/.Musalias/aliases"

    # Check if the aliases file exists
    if [ ! -f "$ALIASES_FILE" ]; then
        echo "Error: Aliases file '$ALIASES_FILE' does not exist." >&2
        return 1
    fi

    # Extract aliases with their comments
    awk '
        # Define the function in awk to handle comments
        function print_comment(comment, name) {

            len = length($0); 
            spaces = ""; 
            for (i = 1; i <= len; i++) { 
                spaces = spaces " "; 
            } 

            if (comment != "") {
                options_index = index(comment, "Options:");
                if (options_index > 0) {
                    # Print the part before "Options:" and add a newline
                    printf " -%s  \n", substr(comment, 1, options_index - 1);
                    # Extract the options part
                    options_part = substr(comment, options_index);
                    # Split the options_part into words
                    n = split(options_part, words, /[ \t]+/);
                    # Print "Options:" on a new line
                    printf "%s\n", words[1];
                    # Process the rest of the words
                    for (i = 2; i <= n; i++) {
                        if (words[i] ~ /^-/) {                            
                            printf "   - **%s**", words[i];
                        } else {
                            # Continue printing the description on the same line
                            printf "%s", words[i];
                        }
                        # Add a space after each word unless its the last word
                        if (i < n && words[i+1] !~ /^-/) {
                            printf " ";
                        } else {
                            # if last option, do not print newline
                            if (i != n) { 
                                printf "\n";
                            }
                        }
                    }
                } else {
                    # Standard printing for comments without "Options:"
                    printf " -%s", comment;
                }
            }
        }

        # Match titles that begin and end with two '#' symbols
        /^##.*##$/ {
            if ($0 !~ /^#+$/) {  # Ensure the line is not just a series of '#'
                if (match($0, /^##\s*(.*?)\s*##$/, arr)) {
                    printf "\n\n### %s", arr[1];  # Print the content between ## in bold
                }
            }
        }

        # Process comments and skip to the next line
        /^#/ { 
            comment = substr($0, 2); 
            next; 
        }

        # For aliases
        /^alias/ {                             
            sub(/^alias\s+/, "");              
            sub(/=.*/, "");                    
            printf "\n- **%s**", $0;   # Print the alias name in bold
            if (comment != "") {
                print_comment(comment, $0);
            }
            comment = "";
        }

        # For functions
        /^[a-zA-Z_][a-zA-Z0-9_]*\s*\(\)\s*\{/ {
            if (match($0, /^([a-zA-Z_][a-zA-Z0-9_]*)\s*\(\)\s*\{/, arr)) {
                printf "\n- **%s**", arr[1];  # Print the function name in bold
            }
            if (comment != "") {
                print_comment(comment, arr[1]);
            }
            comment = "";
        }

    ' "$ALIASES_FILE"
    echo
echo "
## Legend
Aliase marked with 👑 will call sudo"
    echo
else
    # Standard mode: list aliases and functions with their comments
    echo "Hint: To output the entire aliases file with syntax highlighting, use the -v option."
    echo "Available Aliases and Functions:"
    echo "---------------------------------"

    # Path to the aliases file
    ALIASES_FILE="$HOME/.Musalias/aliases"

    # Check if the aliases file exists
    if [ ! -f "$ALIASES_FILE" ]; then
        echo "Error: Aliases file '$ALIASES_FILE' does not exist." >&2
        return 1
    fi

    # Extract aliases with their comments
    awk '
        # Define the function in awk to handle comments
        function print_comment(comment, name) {

            len = length($0); 
            spaces = ""; 
            for (i = 1; i <= len; i++) { 
                spaces = spaces " "; 
            } 

            if (comment != "") {
                options_index = index(comment, "Options:");
                if (options_index > 0) {
                    # Print the part before "Options:" and add a newline
                    printf " -%s\n", substr(comment, 1, options_index - 1);
                    # Extract the options part
                    options_part = substr(comment, options_index);
                    # Split the options_part into words
                    n = split(options_part, words, /[ \t]+/);
                    # Print "Options:" on a new line
                    printf "%s   %s", spaces, words[1];  # Should be "Options:"
                    # Process the rest of the words
                    for (i = 2; i <= n; i++) {
                        if (words[i] ~ /^-/) {
                            # If the word is an option (starts with -), print it on a new indented line except for the first option
                            if (i == 2) {
                                printf " %s", words[i];
                            } else {
                                printf "%s            %s", spaces, words[i];
                            }
                        } else {
                            # Continue printing the description on the same line
                            printf "%s", words[i];
                        }
                        # Add a space after each word unless its the last word
                        if (i < n && words[i+1] !~ /^-/) {
                            printf " ";
                        } else {
                            # if last option, do not print newline
                            if (i != n) { 
                                printf "\n";
                            }
                        }
                    }
                } else {
                    # Standard printing for comments without "Options:"
                    printf " -%s", comment;
                }
            }
        }

        # Match titles that begin and end with two '#' symbols
        /^##.*##$/ {
            if ($0 !~ /^#+$/) {  # Ensure the line is not just a series of '#'
                if (match($0, /^##\s*(.*?)\s*##$/, arr)) {
                    printf "\n\n\033[1m>\033[0m %s", arr[1];  # Print the content between ## in bold
                }
            }
        }

        # Process comments and skip to the next line
        /^#/ { 
            comment = substr($0, 2); 
            next; 
        }

        # For aliases
        /^alias/ {                             
            sub(/^alias\s+/, "");              
            sub(/=.*/, "");                    
            printf "\n    \033[1m%s\033[0m", $0;   # Print the alias name in bold
            if (comment != "") {
                print_comment(comment, $0);
            }
            comment = "";                      
        }

        # For functions
        /^[a-zA-Z_][a-zA-Z0-9_]*\s*\(\)\s*\{/ {
            if (match($0, /^([a-zA-Z_][a-zA-Z0-9_]*)\s*\(\)\s*\{/, arr)) {
                printf "\n    \033[1m%s\033[0m", arr[1];  # Print the function name in bold
            }
            if (comment != "") {
                print_comment(comment, arr[1]);
            }
            comment = "";
        }

    ' "$ALIASES_FILE"
    echo
    echo
    echo "Aliase marked with 👑 will call sudo"
    echo
fi
