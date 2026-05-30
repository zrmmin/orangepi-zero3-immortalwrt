#!/usr/bin/env bash
set -uo pipefail
source /mnt/d/zrm/orangepi/zero3/build-scripts/lib-common.sh

echo "=== toolchain top dirs ==="
ls -1 "$TOOLCHAIN_DIR" 2>/dev/null || echo "no toolchain dir"

echo
echo "=== aarch64 linux-gnu gcc (for u-boot/kernel) ==="
find "$TOOLCHAIN_DIR" -maxdepth 3 -type f -name 'aarch64-linux-gnu-gcc' 2>/dev/null
echo "--- aarch64-none-linux-gnu-gcc ---"
find "$TOOLCHAIN_DIR" -maxdepth 3 -type f -name 'aarch64-none-linux-gnu-gcc' 2>/dev/null

echo
echo "=== immortalwrt clone status ==="
if [ -d "$IMM_DIR/.git" ]; then
  cd "$IMM_DIR"
  git log -1 --oneline 2>/dev/null && echo "IMM_CLONE=OK"
  du -sh "$IMM_DIR" 2>/dev/null
else
  echo "IMM_CLONE=NOT_READY (no .git yet)"
  ls -la "$IMM_DIR" 2>/dev/null | head
fi

echo
echo "=== disk ==="
df -h "$BUILD_ROOT" | tail -n1
echo "STATUS-DONE"
