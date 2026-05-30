#!/usr/bin/env bash
set -uo pipefail
source /mnt/d/zrm/orangepi/zero3/build-scripts/lib-common.sh
cd "$IMM_DIR" || exit 1

echo "=== look for existing po2lmo host tool ==="
find staging_dir -name 'po2lmo' 2>/dev/null
ls -la staging_dir/host/bin/po2lmo 2>/dev/null || echo "po2lmo NOT in staging_dir/host/bin"

echo
echo "=== luci-base host build target available? ==="
ls -d package/feeds/luci/luci-base 2>/dev/null
grep -nE "HostBuild|po2lmo|host/compile" feeds/luci/luci-base/Makefile 2>/dev/null | head

echo
echo "=== build luci-base host tools (po2lmo/lmo2po) ==="
make package/feeds/luci/luci-base/host/compile V=s 2>&1 | tail -n 30

echo
echo "=== verify po2lmo now present ==="
find staging_dir -name 'po2lmo' 2>/dev/null
echo "FIX-PO2LMO-DONE"
