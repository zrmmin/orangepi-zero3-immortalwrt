#!/usr/bin/env bash
set -uo pipefail
source /mnt/d/zrm/orangepi/zero3/build-scripts/lib-common.sh
OPI="$BUILD_ROOT/orangepi-build"

echo "=== KERNELSOURCE / KERNELDIR / BOOTSOURCE in sun50iw9.conf ==="
grep -nE "KERNELSOURCE|KERNELDIR|KERNELBRANCH|BOOTSOURCE|BOOTDIR|BOOTBRANCH|LINUXCONFIG" "$OPI/external/config/sources/families/sun50iw9.conf"

echo
echo "=== branch->kernel mapping context (lines 1-90) ==="
sed -n '1,90p' "$OPI/external/config/sources/families/sun50iw9.conf"

echo
echo "=== OFFLINE_WORK / GITHUB mirror / FORCE_USE_RAMDISK vars ==="
grep -rnE "OFFLINE_WORK|GITHUB_SOURCE|ghproxy|MIRROR|USE_MAINLINE_GOOGLE|FORCE" "$OPI/scripts/general.sh" | head -n 30

echo
echo "=== fetch_from_repo function (head) ==="
awk '/fetch_from_repo\(\)/,/^}/' "$OPI/scripts/general.sh" | head -n 90

echo
echo "=== existing kernel cache dirs ==="
ls -la "$OPI/cache/sources/" 2>/dev/null | head
find "$OPI" -maxdepth 2 -type d -name 'linux-orangepi*' 2>/dev/null
echo "INSPECT15-DONE"
