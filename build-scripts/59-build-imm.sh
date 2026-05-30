#!/usr/bin/env bash
set -uo pipefail
IMM=/home/zrm/build/immortalwrt
LOG=/mnt/d/zrm/orangepi/zero3/build-scripts/out-59-build.log
cd "$IMM"
export HOME=/home/zrm
export FORCE_UNSAFE_CONFIGURE=1
N=$(nproc)
echo "=== $(date) 开始下载源码 (-j$N) ===" > "$LOG"
make -j"$N" download >> "$LOG" 2>&1
echo "=== $(date) 开始编译 (-j$N) ===" >> "$LOG"
if make -j"$N" >> "$LOG" 2>&1; then
  echo "=== $(date) 编译成功(并行) ===" >> "$LOG"
else
  echo "=== $(date) 并行失败, 单线程 V=s 重试以定位错误 ===" >> "$LOG"
  make -j1 V=s >> "$LOG" 2>&1 && echo "=== 单线程成功 ===" >> "$LOG" || echo "=== 编译失败 ===" >> "$LOG"
fi
echo "=== 检查 rootfs 产物 ===" >> "$LOG"
ls -lt "$IMM"/bin/targets/armsr/armv8/*rootfs.tar.gz >> "$LOG" 2>&1
echo "DONE_MARKER" >> "$LOG"
