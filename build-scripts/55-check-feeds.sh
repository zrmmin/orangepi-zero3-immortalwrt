#!/usr/bin/env bash
set -uo pipefail
OUT=/mnt/d/zrm/orangepi/zero3/build-scripts/out-55-feeds.txt
IMM=/home/zrm/build/immortalwrt
cd "$IMM"
export HOME=/home/zrm
{
echo "=== feeds.conf(.default) ==="
[ -f feeds.conf ] && { echo "-- feeds.conf --"; cat feeds.conf; } || echo "(无 feeds.conf, 用 default)"
echo "-- feeds.conf.default --"; cat feeds.conf.default 2>/dev/null | head -30
echo
echo "=== package/feeds 下已 install 的 feed 目录 ==="
ls -l package/feeds/ 2>/dev/null
echo
echo "=== luci feed 是否已下载到 feeds/luci ==="
ls -ld feeds/luci 2>/dev/null && ls feeds/luci/ 2>/dev/null | head
echo "-- 是否能列出 luci-base --"
./scripts/feeds list -r luci 2>/dev/null | grep -E "^luci-base|^luci-mod-admin-full|^luci-compat|^luci\b" | head
echo
echo "=== package/feeds/luci 里有哪些符号链接(install 结果) ==="
ls package/feeds/luci/ 2>/dev/null | grep -E "luci-base|luci-mod-admin-full|luci-compat|^luci$" | head
echo
echo "=== wpad 默认变体当前选择 ==="
grep -E "^CONFIG_PACKAGE_wpad" "$IMM/.config" | head
grep -E "wpad-basic" "$IMM/.config" | head
} > "$OUT" 2>&1
echo wrote
