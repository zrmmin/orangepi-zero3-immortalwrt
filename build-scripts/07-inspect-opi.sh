#!/usr/bin/env bash
set -uo pipefail
source /mnt/d/zrm/orangepi/zero3/build-scripts/lib-common.sh
OPI="$BUILD_ROOT/orangepi-build"

echo "############ README.md ############"
sed -n '1,160p' "$OPI/README.md" 2>/dev/null

echo
echo "############ build.sh (first 120 lines) ############"
sed -n '1,120p' "$OPI/build.sh" 2>/dev/null

echo
echo "############ board configs (external/config/boards) ############"
ls -1 "$OPI/external/config/boards" 2>/dev/null | grep -i zero || ls -1 "$OPI/external/config/boards" 2>/dev/null | head -n 60

echo
echo "############ orangepizero3 board conf ############"
cat "$OPI/external/config/boards/orangepizero3.conf" 2>/dev/null || cat "$OPI/external/config/boards/orangepizero3."* 2>/dev/null

echo
echo "############ grep BUILD_OPT options ############"
grep -rn "BUILD_OPT" "$OPI/scripts" 2>/dev/null | grep -iE "kernel|u-boot|rootfs|image|=" | head -n 40

echo
echo "############ grep BRANCH for sun50iw9 / zero3 family ############"
grep -rniE "sun50iw9|zero3" "$OPI/external/config" 2>/dev/null | head -n 40

echo "INSPECT-DONE"
