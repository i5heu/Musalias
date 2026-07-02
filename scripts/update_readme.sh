#!/bin/bash

echo "Updating README.md..."

TMP_FILE="$(mktemp)"
"$HOME/.Musalias/scripts/listAliases.sh" -m > "$TMP_FILE"

README="$HOME/.Musalias/README.md"

# Remove existing lines between "## Aliases" and the next "##" heading
sed -i '/^## Aliases/,/^## /{/^## Aliases/!{/^## /!d}}' "$README"

# Insert the new content
sed -i "/^## Aliases/r $TMP_FILE" "$README"

rm "$TMP_FILE"

echo "DONE"