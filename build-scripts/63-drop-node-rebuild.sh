#!/usr/bin/env bash
set -uo pipefail
IMM=/home/zrm/build/immortalwrt
CFG="$IMM/.config"
LOG=/mnt/d/zrm/orangepi/zero3/build-scripts/out-63-rebuild.log
cd "$IMM"; export HOME=/home/zrm; export FORCE_UNSAFE_CONFIGURE=1

{
echo "=== $(date) 停止当前编译 ==="
# 先杀构建脚本, 防止它进入单线程 V=s 重试
pkill -9 -f '59-build-imm.sh' 2>/dev/null
# 杀 make 主树与编译子进程
pkill -9 -f 'make -j' 2>/dev/null
pkill -9 -f 'node/compile' 2>/dev/null
pkill -9 -f 'BUILD_SUBDIR' 2>/dev/null
pkill -9 cc1plus 2>/dev/null
pkill -9 cc1 2>/dev/null
pkill -9 mksnapshot 2>/dev/null
sleep 3
echo "残留 make: $(pgrep -c 'make' || echo 0); cc1plus: $(pgrep -c cc1plus || echo 0)"

echo "=== 从 .config 移除 node / node-npm ==="
sed -i '/^CONFIG_PACKAGE_node=y/d;   /^CONFIG_PACKAGE_node-npm=y/d' "$CFG"
echo "# CONFIG_PACKAGE_node is not set"      >> "$CFG"
echo "# CONFIG_PACKAGE_node-npm is not set"  >> "$CFG"
make defconfig 2>&1 | tail -3
echo "node 现状: $(grep -E 'CONFIG_PACKAGE_node(=| is not set)' "$CFG" | head -2)"

echo "=== $(date) 重新编译(无 node, 其余已编, 主要做 rootfs 组装) ==="
N=$(nproc)
if make -j"$N" 2>&1 | tail -25; then
  echo "BUILD_RC=ok"
else
  echo "并行失败, 单线程 V=s 定位:"
  make -j1 V=s 2>&1 | tail -40
  echo "BUILD_RC=fail"
fi
echo "=== rootfs 产物 ==="
ls -lt "$IMM"/bin/targets/armsr/armv8/*rootfs.tar.gz 2>&1 | head
echo "REBUILD_DONE_MARKER"
} >> "$LOG" 2>&1
echo "see $LOG"
