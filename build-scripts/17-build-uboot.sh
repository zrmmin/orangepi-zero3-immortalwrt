#!/usr/bin/env bash
# Build u-boot (+ ATF) for Orange Pi Zero3 via orangepi-build, BRANCH=next.
set -uo pipefail
source /mnt/d/zrm/orangepi/zero3/build-scripts/lib-common.sh
OPI="$BUILD_ROOT/orangepi-build"
cd "$OPI" || exit 1
touch "$OPI/.ignore_changes"

echo "=== u-boot compile: BOARD=orangepizero3 BRANCH=next ==="
echo "start: $(date)"
sudo ./build.sh BOARD=orangepizero3 BRANCH=next BUILD_OPT=u-boot
rc=$?
echo "end: $(date) rc=$rc"
echo "=== resulting u-boot debs ==="
ls -l "$OPI/output/debs/" 2>/dev/null | grep -iE "u-boot|uboot"
echo "UBOOT-BUILD-DONE rc=$rc"
