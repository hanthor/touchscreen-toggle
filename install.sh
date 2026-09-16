#!/bin/sh
set -eu

project_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
extension_dir="$HOME/.local/share/gnome-shell/extensions/touchscreen-toggle@local"

install -d "$extension_dir"
install -m 0644 "$project_dir/extension/metadata.json" "$extension_dir/metadata.json"
install -m 0644 "$project_dir/extension/extension.js" "$extension_dir/extension.js"

sudo install -D -m 0755 "$project_dir/gnome-touchscreen-toggle" \
    /usr/local/libexec/gnome-touchscreen-toggle
sudo install -D -m 0644 "$project_dir/org.local.gnome-touchscreen-toggle.policy" \
    /usr/share/polkit-1/actions/org.local.gnome-touchscreen-toggle.policy

echo "Installed Touchscreen Toggle. Log out and back in, then run:"
echo "  gnome-extensions enable touchscreen-toggle@local"
