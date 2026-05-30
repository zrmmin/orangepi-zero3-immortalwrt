#!/usr/bin/env bash
# Patch orangepi-build (Armbian framework) to not hard-exit on WSL.
# Kernel cross-compile does not need an ARM chroot, so WSL is fine here.
set -uo pipefail
source /mnt/d/zrm/orangepi/zero3/build-scripts/lib-common.sh
GEN="$BUILD_ROOT/orangepi-build/scripts/general.sh"

cp -n "$GEN" "$GEN.orig" 2>/dev/null || true

sed -i 's#exit_with_error "Windows subsystem for Linux is not a supported build environment"#display_alert "WSL detected - patched to continue (kernel cross-build only)" "" "wrn"#' "$GEN"

echo "=== verify patch ==="
grep -n "Windows subsystem for Linux\|patched to continue" "$GEN"
echo "PATCH-DONE"
