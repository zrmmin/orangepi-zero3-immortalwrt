#!/usr/bin/env bash
set -uo pipefail
source /mnt/d/zrm/orangepi/zero3/build-scripts/lib-common.sh
cd "$IMM_DIR" || { echo "no immortalwrt"; exit 1; }

echo "=== targets: armsr / armvirt ==="
ls -1 target/linux/ | grep -iE "armsr|armvirt" || echo "(neither found)"

echo
echo "=== armsr subtargets ==="
ls -1 target/linux/armsr/ 2>/dev/null
grep -rniE "armv8|cortexa53|generic" target/linux/armsr/*.mk target/linux/armsr/*/* 2>/dev/null | head

echo
echo "=== feeds.conf.default (current) ==="
cat feeds.conf.default

echo
echo "=== does any feed already provide openclash? ==="
grep -rni "openclash" feeds.conf.default 2>/dev/null || echo "openclash NOT in feeds yet"

echo "INSPECT-IMM-DONE"
