#!/usr/bin/env bash
set -euo pipefail
source /mnt/d/zrm/orangepi/zero3/build-scripts/lib-common.sh

cd "$BUILD_ROOT"
if [ -d "$IMM_DIR/.git" ]; then
  echo "ImmortalWrt already cloned at $IMM_DIR"
else
  echo "=== cloning ImmortalWrt (master, shallow) ==="
  git clone --depth 1 https://github.com/immortalwrt/immortalwrt.git "$IMM_DIR"
fi
cd "$IMM_DIR"
echo "=== HEAD ==="
git log -1 --oneline || true
echo "DONE-CLONE-IMM"
