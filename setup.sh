#!/bin/bash

# Script Name: setup.sh
# Description: Sets up the alias library by adding source lines to shell configuration files (idempotent).

set -u

# Source line to be added (literal $HOME in rc files)
SOURCE_LINE="source \$HOME/.Musalias/aliases"

# Append a line to a file iff it's not already present (exact match).
# Ensures there's a trailing newline before appending to avoid line-gluing.
add_source_line() {
    local file="$1"
    local line="$2"

    if [ ! -f "$file" ]; then
        touch "$file"
        echo "Created $file"
    fi

    if ! grep -qxF "$line" "$file"; then
        # ensure file ends with a newline before appending (if not empty)
        if [ -s "$file" ] && [ -n "$(tail -c1 "$file" 2>/dev/null || printf x)" ] && [ "$(tail -c1 "$file" 2>/dev/null)" != $'\n' ]; then
            printf '\n' >> "$file"
        fi
        printf '%s\n' "$line" >> "$file"
        echo "Added sourcing of Musalias to $file"
    else
        echo "Sourcing of Musalias already exists in $file"
    fi
}

# ------------------ Bash ------------------

# Always add to .bashrc
add_source_line "$HOME/.bashrc" "$SOURCE_LINE"

# Choose a bash profile file (if present)
if   [ -f "$HOME/.bash_profile" ]; then
    PROFILE_FILE="$HOME/.bash_profile"
elif [ -f "$HOME/.profile" ]; then
    PROFILE_FILE="$HOME/.profile"
else
    PROFILE_FILE=""
fi

# If a profile exists, ensure it sources .bashrc (idempotent)
if [ -n "${PROFILE_FILE}" ]; then
    add_source_line "$PROFILE_FILE" "source \$HOME/.bashrc"
fi

# Reload bash rc only when we are currently in an interactive bash
if [ -n "${BASH_VERSION:-}" ] && [ -n "${PS1:-}" ]; then
    # shellcheck disable=SC1090
    source "$HOME/.bashrc"
    echo "Reloaded ~/.bashrc"
fi

# --- zsh support (works even when run from bash) ---
ZDOTDIR_PATH="${ZDOTDIR:-$HOME}"
ZSHRC="$ZDOTDIR_PATH/.zshrc"
ZPROFILE="$ZDOTDIR_PATH/.zprofile"

# Always add Musalias aliases and hints to zshrc
add_source_line "$ZSHRC" "source \$HOME/.Musalias/aliases"
add_source_line "$ZSHRC" "source \$HOME/.Musalias/scripts/zsh_picker_integration.sh"

if [ -f "$ZPROFILE" ]; then
  add_source_line "$ZPROFILE" "source \$HOME/.zshrc"
fi

if [ -n "${ZSH_VERSION:-}" ]; then
  # shellcheck disable=SC1090
  source "$ZSHRC"
  echo "Reloaded $ZSHRC"
fi


echo "✅ Musalias setup complete."
