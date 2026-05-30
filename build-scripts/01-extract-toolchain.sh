#!/usr/bin/env bash
set -euo pipefail
source /mnt/d/zrm/orangepi/zero3/build-scripts/lib-common.sh

echo "=== toolchains.tar.gz top-level listing (first 40 entries) ==="
tar -tzf "$TOOLCHAIN_TGZ" 2>/dev/null | head -n 40 || true

echo
echo "=== extracting to $TOOLCHAIN_DIR ==="
mkdir -p "$TOOLCHAIN_DIR"
tar -xzf "$TOOLCHAIN_TGZ" -C "$TOOLCHAIN_DIR"

echo
echo "=== extracted top dirs ==="
ls -l "$TOOLCHAIN_DIR"

echo
echo "=== locate aarch64 cross gcc binaries ==="
find "$TOOLCHAIN_DIR" -maxdepth 4 -type f -name 'aarch64-*-gcc' 2>/dev/null | head -n 40

echo "DONE-EXTRACT"
