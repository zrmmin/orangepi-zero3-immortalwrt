#!/usr/bin/env bash
set -uo pipefail
source /mnt/d/zrm/orangepi/zero3/build-scripts/lib-common.sh

cd "$BUILD_ROOT"

ORANGEPI_BUILD_DIR="$BUILD_ROOT/orangepi-build"
if [ -d "$ORANGEPI_BUILD_DIR/.git" ]; then
  echo "orangepi-build already present"
else
  echo "=== cloning orangepi-build (shallow) ==="
  git clone --depth 1 https://github.com/orangepi-xunlong/orangepi-build.git "$ORANGEPI_BUILD_DIR"
fi

if [ -d "$PACKIT_DIR/.git" ]; then
  echo "openwrt_packit already present"
else
  echo "=== cloning openwrt_packit (shallow) ==="
  git clone --depth 1 https://github.com/unifreq/openwrt_packit.git "$PACKIT_DIR"
fi

echo
echo "=== orangepi-build top ==="
ls -1 "$ORANGEPI_BUILD_DIR" 2>/dev/null | head -n 30
echo
echo "=== link pre-downloaded toolchains into orangepi-build/toolchains ==="
# orangepi-build expects its cross toolchains under <repo>/toolchains/<gcc-*>
if [ -d "$BUILD_ROOT/toolchains/toolchains" ]; then
  rm -rf "$ORANGEPI_BUILD_DIR/toolchains"
  ln -sfn "$BUILD_ROOT/toolchains/toolchains" "$ORANGEPI_BUILD_DIR/toolchains"
  echo "linked: $ORANGEPI_BUILD_DIR/toolchains -> $BUILD_ROOT/toolchains/toolchains"
  ls -1 "$ORANGEPI_BUILD_DIR/toolchains" | head
fi
echo "CLONE-TOOLS-DONE"
