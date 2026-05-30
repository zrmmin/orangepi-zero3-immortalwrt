#!/usr/bin/env bash
# Build ImmortalWrt rootfs.tar.gz (armsr/armv8) with OpenClash etc.
# Runs as normal user (OpenWrt build refuses root).
set -uo pipefail
source /mnt/d/zrm/orangepi/zero3/build-scripts/lib-common.sh
cd "$IMM_DIR" || { echo "no immortalwrt"; exit 1; }

JOBS=$(nproc)
echo "start: $(date)  jobs=$JOBS"

echo "=== make download ==="
make download -j8 V=s 2>&1 | tail -n 5 || true

echo "=== make (parallel) ==="
if make -j"$JOBS"; then
  rc=0
else
  echo "!!! parallel build failed, retrying single-thread verbose to capture error !!!"
  make -j1 V=s
  rc=$?
fi

echo "end: $(date) rc=$rc"
echo "=== resulting rootfs archives ==="
find "$IMM_DIR/bin/targets" -name "*rootfs.tar.gz" 2>/dev/null
echo "IMM-BUILD-DONE rc=$rc"
