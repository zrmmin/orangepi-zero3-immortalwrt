#!/usr/bin/env bash
set -uo pipefail
OUT=/mnt/d/zrm/orangepi/zero3/build-scripts/out-58-i18n.txt
IMM=/home/zrm/build/immortalwrt
CFG="$IMM/.config"
cd "$IMM"
export HOME=/home/zrm
{
echo "=== 查可用的中文 i18n 包 / package-manager ==="
./scripts/feeds list 2>/dev/null | grep -iE "luci-i18n-(base|firewall|openclash|opkg|package-manager)-zh|luci-app-package-manager|luci-app-opkg" | head -30
echo
echo "=== LUCI_LANG 配置项 ==="
grep -E "LUCI_LANG" "$CFG" | head
echo
echo "=== 修正: 用 package-manager 取代 opkg; 修正 i18n 名;开启中文语言 ==="
# 去掉无效行
sed -i '/^CONFIG_PACKAGE_luci-app-opkg=y/d' "$CFG"
sed -i '/^CONFIG_PACKAGE_luci-i18n-opkg-zh-cn=y/d' "$CFG"
cat >> "$CFG" <<'EOF'
CONFIG_LUCI_LANG_zh_Hans=y
CONFIG_PACKAGE_luci-app-package-manager=y
CONFIG_PACKAGE_luci-i18n-base-zh-cn=y
CONFIG_PACKAGE_luci-i18n-firewall-zh-cn=y
CONFIG_PACKAGE_luci-i18n-package-manager-zh-cn=y
CONFIG_PACKAGE_luci-i18n-openclash-zh-cn=y
EOF
make defconfig 2>&1 | tail -3
echo
echo "=== 最终状态 ==="
for p in luci luci-app-package-manager luci-i18n-base-zh-cn luci-i18n-firewall-zh-cn \
         luci-i18n-package-manager-zh-cn luci-i18n-openclash-zh-cn; do
  s=$(grep -m1 "^CONFIG_PACKAGE_${p}=" "$CFG")
  [ -n "$s" ] && echo "OK   $s" || echo "MISS $p"
done
grep -E "^CONFIG_LUCI_LANG_zh_Hans" "$CFG"
} > "$OUT" 2>&1
echo wrote
