#!/bin/sh
# Tests for gnome-touchscreen-toggle.
#
# The helper hardcodes /sys/class/input and shells out to udevadm, so the test
# runs a copy of it with the sysfs root rewritten to a temp directory and a
# stub udevadm first on PATH. Nothing outside the temp directory is touched.
#
# Run: sh tests/test-helper.sh
set -u

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT INT TERM

sysfs="$work/sys/class/input"
mkdir -p "$work/bin" "$sysfs"
sed "s#/sys/class/input/#$sysfs/#" "$root/gnome-touchscreen-toggle" > "$work/helper"

# Stub: prints ID_INPUT_TOUCHSCREEN=1 for devices that carry a `touchscreen`
# marker file, and an unrelated property for everything else.
cat > "$work/bin/udevadm" <<'STUB'
#!/bin/sh
for arg in "$@"; do
    case "$arg" in --path=*) path=${arg#--path=} ;; esac
done
if [ -e "$path/touchscreen" ]; then
    printf 'ID_INPUT=1\nID_INPUT_TOUCHSCREEN=1\n'
else
    printf 'ID_INPUT=1\nID_INPUT_TOUCHPAD=1\n'
fi
STUB
chmod +x "$work/bin/udevadm"

pass=0
fail=0

reset_devices() {
    rm -rf "$sysfs"
    mkdir -p "$sysfs"
}

# add_device NAME KIND INHIBITED   (KIND: touchscreen|touchpad, INHIBITED may be "-" for none)
add_device() {
    mkdir -p "$sysfs/$1"
    [ "$2" = touchscreen ] && : > "$sysfs/$1/touchscreen"
    [ "$3" = - ] || printf '%s' "$3" > "$sysfs/$1/inhibited"
}

# run_helper ARGS... -> sets $out (stdout), $err (stderr), $rc
run_helper() {
    out=$(PATH="$work/bin:$PATH" sh "$work/helper" "$@" 2>"$work/err")
    rc=$?
    err=$(cat "$work/err")
}

check() {
    name=$1 want_rc=$2 want_out=$3 want_err=$4
    if [ "$rc" = "$want_rc" ] && [ "$out" = "$want_out" ] && [ "$err" = "$want_err" ]; then
        pass=$((pass + 1))
    else
        fail=$((fail + 1))
        printf 'FAIL: %s\n  rc=%s (want %s)\n  out=%s (want %s)\n  err=%s (want %s)\n' \
            "$name" "$rc" "$want_rc" "$out" "$want_out" "$err" "$want_err"
    fi
}

check_file() {
    name=$1 file=$2 want=$3
    got=$(cat "$file")
    if [ "$got" = "$want" ]; then
        pass=$((pass + 1))
    else
        fail=$((fail + 1))
        printf 'FAIL: %s\n  %s=%s (want %s)\n' "$name" "$file" "$got" "$want"
    fi
}

usage_msg='usage: gnome-touchscreen-toggle {status|enable|disable}'

# --- argument validation ---------------------------------------------------
reset_devices
run_helper
check "no arguments is a usage error" 2 "" "$usage_msg"
run_helper status extra
check "extra arguments are a usage error" 2 "" "$usage_msg"
run_helper reboot
check "unknown action is a usage error" 2 "" "$usage_msg"
run_helper ../../etc/passwd
check "path-like argument is rejected" 2 "" "$usage_msg"

# --- no usable device ------------------------------------------------------
reset_devices
run_helper status
check "no input devices" 1 "" "No touchscreen input device was found"

reset_devices
add_device input1 touchpad 0
run_helper status
check "only a touchpad present" 1 "" "No touchscreen input device was found"

reset_devices
add_device input2 touchscreen -
run_helper status
check "touchscreen without inhibit interface" 1 "" \
    "The touchscreen does not support the kernel inhibit interface"
run_helper disable
check "disable without inhibit interface fails" 1 "" \
    "The touchscreen does not support the kernel inhibit interface"

# --- status ----------------------------------------------------------------
reset_devices
add_device input2 touchscreen 0
run_helper status
check "status: not inhibited reports enabled" 0 enabled ""

reset_devices
add_device input2 touchscreen 1
run_helper status
check "status: inhibited reports disabled" 0 disabled ""

# --- enable / disable ------------------------------------------------------
reset_devices
add_device input2 touchscreen 0
run_helper disable
check "disable succeeds quietly" 0 "" ""
check_file "disable writes 1" "$sysfs/input2/inhibited" 1
run_helper status
check "status after disable" 0 disabled ""

run_helper enable
check "enable succeeds quietly" 0 "" ""
check_file "enable writes 0" "$sysfs/input2/inhibited" 0
run_helper status
check "status after enable" 0 enabled ""

# --- only touchscreens are touched -----------------------------------------
reset_devices
add_device input1 touchpad 0
add_device input2 touchscreen 0
add_device input3 touchscreen 0
run_helper disable
check "disable with several devices" 0 "" ""
check_file "touchpad is left alone" "$sysfs/input1/inhibited" 0
check_file "first touchscreen inhibited" "$sysfs/input2/inhibited" 1
check_file "second touchscreen inhibited" "$sysfs/input3/inhibited" 1

# A touchscreen lacking the inhibit file does not stop the others being toggled.
reset_devices
add_device input2 touchscreen -
add_device input3 touchscreen 0
run_helper disable
check "mixed touchscreens, one supported" 0 "" ""
check_file "supported touchscreen still inhibited" "$sysfs/input3/inhibited" 1

# Entries in the sysfs directory that are not directories are skipped.
reset_devices
: > "$sysfs/input9"
add_device input2 touchscreen 1
run_helper status
check "non-directory entries are skipped" 0 disabled ""

printf '%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
