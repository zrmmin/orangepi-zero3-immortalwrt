#!/usr/bin/env bash
set -uo pipefail
source /mnt/d/zrm/orangepi/zero3/build-scripts/lib-common.sh   # 干净 PATH + HOME
export FORCE_UNSAFE_CONFIGURE=1
IMM=/home/zrm/build/immortalwrt
LOG=/mnt/d/zrm/orangepi/zero3/build-scripts/out-64-resume.log
cd "$IMM"
N=$(nproc)
{
echo "=== $(date) PATH=$PATH ==="
echo "=== 重新组装 rootfs (-j$N) ==="
if make -j"$N" 2>&1 | tail -20; then
  echo "RESUME_RC=ok"
else
  echo "并行失败, 单线程 V=s:"
  make -j1 V=s 2>&1 | tail -40
  echo "RESUME_RC=fail"
fi
echo "=== rootfs 产物时间 ==="
ls -lt "$IMM"/bin/targets/armsr/armv8/*rootfs.tar.gz 2>&1 | head -2
echo "RESUME_DONE_MARKER"
} >> "$LOG" 2>&1
echo "see $LOG"
