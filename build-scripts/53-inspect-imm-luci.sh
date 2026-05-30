#!/usr/bin/env bash
set -uo pipefail
OUT=/mnt/d/zrm/orangepi/zero3/build-scripts/out-53-imm.txt
# 找 immortalwrt 目录
IMM=$(ls -d /home/zrm/build/immortalwrt* 2>/dev/null | head -1)
{
echo "IMM=$IMM"
[ -z "$IMM" ] && { echo "no immortalwrt dir"; exit 0; }
echo
echo "=== .config 里 luci/uhttpd/rpcd 相关选择 ==="
grep -E "luci|uhttpd|rpcd|openclash|CONFIG_TARGET" "$IMM/.config" 2>/dev/null | grep -v "^#" | head -80
echo
echo "=== .config 里被显式关闭的(# ... is not set) 关键项 ==="
grep -E "uhttpd|rpcd|luci-base|luci-mod-admin|luci-ssl" "$IMM/.config" 2>/dev/null | grep "is not set" | head -30
echo
echo "=== 已编出的 ipk: uhttpd/rpcd/luci-base/luci-mod-admin ==="
sudo find "$IMM/bin" -name '*.ipk' 2>/dev/null | grep -iE "uhttpd|rpcd_|luci-base|luci-mod-admin|luci-compat|luci-lib" | head -40
echo "--- 是否有 luci-app-openclash ipk ---"
sudo find "$IMM/bin" -name '*openclash*' 2>/dev/null | head
echo
echo "=== 目标/架构 ==="
grep -E "CONFIG_TARGET_(BOARD|SUBTARGET|ARCH)|CONFIG_TARGET.*=y" "$IMM/.config" 2>/dev/null | head
echo
echo "=== bin/targets 路径 ==="
sudo find "$IMM/bin/targets" -maxdepth 2 -type d 2>/dev/null | head
} > "$OUT" 2>&1
echo wrote
