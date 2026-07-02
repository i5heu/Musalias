# ~/.Musalias/scripts/zsh_picker_integration.sh
# Alt-a opens an interactive picker; on select, insert command and show description.

# Idempotent guard
[[ -n ${_MUSALIAS_ZSH_PICKER_LOADED:-} ]] && return
_MUSALIAS_ZSH_PICKER_LOADED=1

# Only interactive zsh
[[ -n ${ZSH_VERSION:-} && $- == *i* ]] || return
zmodload -i zsh/zle || return

: ${MUSALIAS_DIR:=$HOME/.Musalias}
ALIASES_FILE="$MUSALIAS_DIR/aliases"
LIST_SCRIPT="$MUSALIAS_DIR/scripts/listAliases.sh"

# Build "name<TAB>desc" list (aliases + functions) for fzf
_mus_build_list() {
  [[ -r "$ALIASES_FILE" ]] || return
  awk '
    # capture one-line comment above item
    /^#/ { c = substr($0,2); sub(/^[ \t]+/, "", c); sub(/[ \t]+$/, "", c); next }

    # aliases
    /^alias[ \t]+[A-Za-z0-9_]+=*/ {
      n=$0; sub(/^alias[ \t]+/,"",n); sub(/=.*/,"",n);
      printf "%s\t%s\n", n, c; c=""; next
    }

    # functions
    /^[A-Za-z_][A-Za-z0-9_]*[ \t]*\(\)[ \t]*\{/ {
      if (match($0,/^([A-Za-z_][A-Za-z0-9_]*)[ \t]*\(\)/,a)) {
        printf "%s\t%s\n", a[1], c; c=""
      }
    }
  ' "$ALIASES_FILE"
}

# Resolve description for exact name (fast, non-interactive)
_mus_desc_for() {
  local name="$1"
  [[ -r "$ALIASES_FILE" ]] || { print -r -- ""; return; }
  awk -v px="$name" '
    /^#/ { c = substr($0,2); sub(/^[ \t]+/,"",c); sub(/[ \t]+$/, "", c); next }
    /^alias[ \t]+[A-Za-z0-9_]+=*/ {
      n=$0; sub(/^alias[ \t]+/,"",n); sub(/=.*/,"",n);
      if (n==px) { print c; exit } c=""; next
    }
    /^[A-Za-z_][A-Za-z0-9_]*[ \t]*\(\)[ \t]*\{/ {
      if (match($0,/^([A-Za-z_][A-Za-z0-9_]*)[ \t]*\(\)/,a)) {
        if (a[1]==px) { print c; exit } c=""
      }
    }
  ' "$ALIASES_FILE"
}

# ZLE widget: Alt-a picker
_musalias_pick_widget() {
  local choice line desc

  if command -v fzf >/dev/null 2>&1; then
    line="$(_mus_build_list | sort | fzf --with-nth=1,2 --delimiter=$'\t' \
            --preview='echo {2}' --preview-window=down,3,wrap \
            --prompt='alias/function > ' )" || return
  else
    # Fallback: tiny menu using select
    local -a items
    local IFS=$'\n'
    items=($(_mus_build_list | sort))
    local PS3="Pick alias/function (or Ctrl-C): "
    select line in "${items[@]}"; do
      [[ -n "$line" ]] && break
    done || return
  fi

  choice="${line%%$'\t'*}"
  desc="$(_mus_desc_for "$choice")"

  # Insert chosen command; include #desc if interactivecomments is enabled
  if [[ -o interactivecomments && -n "$desc" ]]; then
    LBUFFER+="${choice}  # ${desc} "
  else
    LBUFFER+="${choice} "
    [[ -n "$desc" ]] && zle -M "${choice} — ${desc}"
  fi
}

zle -N musalias-pick _musalias_pick_widget
# Bind Alt-a (Meta-a)
bindkey '^[a' musalias-pick
