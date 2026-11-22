# Touchscreen Toggle

[![GNOME Shell 50](https://img.shields.io/badge/GNOME%20Shell-50-4A86CF)](https://www.gnome.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A GNOME Shell 50 Quick Settings toggle for enabling and disabling touchscreen
input on Wayland. It is not tied to a hardware model: it discovers all devices
tagged `ID_INPUT_TOUCHSCREEN=1` by udev and uses each kernel input device's
`inhibited` attribute, so it does not unload a shared HID driver or disturb the
touchpad. A clear “Unavailable” state is shown on kernels or devices that do not
provide that interface.

## Install

```sh
cd ~/touchscreen-toggle
chmod +x install.sh uninstall.sh gnome-touchscreen-toggle
./install.sh
```

Log out and back in, then enable it:

```sh
gnome-extensions enable touchscreen-toggle@local
```

The tile is checked when touchscreen input is enabled. The included PolicyKit
policy permits the active local session to invoke only the narrowly scoped
helper; the helper accepts no paths or arbitrary values.

## Command-line check

```sh
/usr/local/libexec/gnome-touchscreen-toggle status
pkexec /usr/local/libexec/gnome-touchscreen-toggle disable
pkexec /usr/local/libexec/gnome-touchscreen-toggle enable
```

Keep a mouse or keyboard available when testing the disable command.

## Uninstall

```sh
cd ~/touchscreen-toggle
./uninstall.sh
```

## Tests

```sh
sh tests/test-helper.sh
```

Runs the helper against a fake sysfs tree and a stub `udevadm`, so it needs no
touchscreen and changes nothing on the host.
