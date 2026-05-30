#!/usr/bin/env bash
# Build the bundled po2lmo host tool (OpenClash Makefile assumes it in PATH but
# never builds it) and resume the ImmortalWrt build.
set -uo pipefail
source /mnt/d/zrm/orangepi/zero3/build-scripts/lib-common.sh
cd "$IMM_DIR" || exit 1

HOSTBIN="$IMM_DIR/staging_dir/host/bin"
SRC="$IMM_DIR/feeds/openclash/luci-app-openclash/tools/po2lmo/src"
mkdir -p "$HOSTBIN"

echo "=== compile po2lmo (host) ==="
gcc -O2 -o "$HOSTBIN/po2lmo" "$SRC/po2lmo.c" "$SRC/template_lmo.c"
chmod +x "$HOSTBIN/po2lmo"
"$HOSTBIN/po2lmo" 2>&1 | head -n 2 || true
ls -l "$HOSTBIN/po2lmo"

JOBS=$(nproc)
echo "=== resume make (jobs=$JOBS) start: $(date) ==="
if make -j"$JOBS"; then
  rc=0
else
  echo "!!! parallel failed, single-thread verbose !!!"
  make -j1 V=s
  rc=$?
fi
echo "end: $(date) rc=$rc"
echo "=== rootfs archives ==="
find "$IMM_DIR/bin/targets" -name "*rootfs.tar.gz" 2>/dev/null
echo "IMM-RESUME-DONE rc=$rc"
