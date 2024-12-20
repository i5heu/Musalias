#!/bin/bash

# Script Name: setup.sh
# Description: Sets up the alias library by adding source lines to shell configuration files.

# Source line to be added
SOURCE_LINE="source \$HOME/.Musalias/aliases"

# Function to add source line to a file if not already present
add_source_line() {
    local file="$1"
    local line="$2"

    if [ ! -f "$file" ]; then
        touch "$file"
        echo "Created $file"
    fi

    if ! grep -qxF "$line" "$file"; then
        echo "$line" >> "$file"
        echo "Added sourcing of Musalias to $file"
    else
        echo "Sourcing of Musalias already exists in $file"
    fi
}

# Add to .bashrc
add_source_line "$HOME/.bashrc" "$SOURCE_LINE"

# Determine appropriate profile file for bash
if [ -f "$HOME/.bash_profile" ]; then
    PROFILE_FILE="$HOME/.bash_profile"
elif [ -f "$HOME/.profile" ]; then
    PROFILE_FILE="$HOME/.profile"
else
    PROFILE_FILE="$HOME/.bashrc"
fi

# Add sourcing to bash profile file
add_source_line "$PROFILE_FILE" "source \$HOME/.bashrc"

# Reload the bash profile
if [ -n "$PROFILE_FILE" ]; then
    source "$PROFILE_FILE"
    echo "Reloaded $PROFILE_FILE"
fi

# Check if the user is using zsh
if [ -n "$ZSH_VERSION" ]; then
    # Add to .zshrc
    add_source_line "$HOME/.zshrc" "$SOURCE_LINE"

    # Determine appropriate zsh profile file
    if [ -f "$HOME/.zprofile" ]; then
        ZPROFILE_FILE="$HOME/.zprofile"
    else
        ZPROFILE_FILE="$HOME/.zshrc"
    fi

    # Add sourcing to zsh profile file
    add_source_line "$ZPROFILE_FILE" "source \$HOME/.zshrc"

    # Reload the zsh profile
    if [ -n "$ZPROFILE_FILE" ]; then
        source "$ZPROFILE_FILE"
        echo "Reloaded $ZPROFILE_FILE"
    fi
fi
