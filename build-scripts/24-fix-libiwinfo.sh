#!/usr/bin/env bash
set -uo pipefail
source /mnt/d/zrm/orangepi/zero3/build-scripts/lib-common.sh
cd "$IMM_DIR" || exit 1

echo "=== enable libiwinfo + libiwinfo-data explicitly ==="
sed -i '/CONFIG_PACKAGE_libiwinfo is not set/d' .config
grep -q '^CONFIG_PACKAGE_libiwinfo=y' .config || echo 'CONFIG_PACKAGE_libiwinfo=y' >> .config
grep -q '^CONFIG_PACKAGE_libiwinfo-data=y' .config || echo 'CONFIG_PACKAGE_libiwinfo-data=y' >> .config
make defconfig >/dev/null 2>&1
echo "after defconfig:"; grep -iE '^CONFIG_PACKAGE_(iwinfo|libiwinfo)' .config

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
echo "IMM-FIX2-DONE rc=$rc"
