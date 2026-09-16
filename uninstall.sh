#!/bin/sh
set -eu

gnome-extensions disable touchscreen-toggle@local 2>/dev/null || true
rm -rf "$HOME/.local/share/gnome-shell/extensions/touchscreen-toggle@local"
sudo rm -f /usr/local/libexec/gnome-touchscreen-toggle
sudo rm -f /usr/share/polkit-1/actions/org.local.gnome-touchscreen-toggle.policy

echo "Touchscreen Toggle was removed."
