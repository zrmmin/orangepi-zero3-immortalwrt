#!/usr/bin/env bash
# Build the vendor 6.1 kernel (with uwe5622 wifi) via orangepi-build.
# Run as the normal user; build.sh elevates with sudo internally (NOPASSWD enabled).
set -uo pipefail
source /mnt/d/zrm/orangepi/zero3/build-scripts/lib-common.sh

OPI="$BUILD_ROOT/orangepi-build"
cd "$OPI" || { echo "no orangepi-build dir"; exit 1; }

# Avoid the interactive "you made changes / update" prompt.
touch "$OPI/.ignore_changes"

echo "=== orangepi-build kernel compile: BOARD=orangepizero3 BRANCH=next (6.1) ==="
echo "start: $(date)"

# BRANCH=next maps to orange-pi-6.1-sun50iw9 (kernel 6.1) for this board.
sudo ./build.sh BOARD=orangepizero3 BRANCH=next BUILD_OPT=kernel KERNEL_CONFIGURE=no
rc=$?

echo "end: $(date) rc=$rc"
echo "=== resulting kernel debs ==="
ls -l "$OPI/output/debs/" 2>/dev/null | grep -iE "linux-(image|dtb|headers)" || ls -l "$OPI/output/debs/" 2>/dev/null | head
echo "KERNEL-BUILD-DONE-NEXT rc=$rc"
