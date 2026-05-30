#!/usr/bin/env bash
set -uo pipefail
OUT=/mnt/d/zrm/orangepi/zero3/build-scripts/out-57-luci.txt
IMM=/home/zrm/build/immortalwrt
CFG="$IMM/.config"
cd "$IMM"
export HOME=/home/zrm
{
echo "=== 重新补 LuCI 选择(feed 已就绪) ==="
cat >> "$CFG" <<'EOF'
CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-ssl=y
CONFIG_PACKAGE_luci-mod-admin-full=y
CONFIG_PACKAGE_luci-mod-network=y
CONFIG_PACKAGE_luci-mod-status=y
CONFIG_PACKAGE_luci-mod-system=y
CONFIG_PACKAGE_luci-theme-bootstrap=y
CONFIG_PACKAGE_luci-theme-argon=y
CONFIG_PACKAGE_luci-app-firewall=y
CONFIG_PACKAGE_luci-app-opkg=y
CONFIG_PACKAGE_luci-i18n-base-zh-cn=y
CONFIG_PACKAGE_luci-i18n-firewall-zh-cn=y
CONFIG_PACKAGE_luci-i18n-opkg-zh-cn=y
CONFIG_PACKAGE_luci-i18n-openclash-zh-cn=y
EOF
echo appended
make defconfig 2>&1 | tail -4
echo
echo "=== 最终 LuCI 关键包状态 ==="
for p in luci luci-base luci-mod-admin-full luci-compat luci-theme-argon luci-theme-bootstrap \
         luci-mod-network luci-mod-status luci-mod-system luci-app-firewall luci-app-opkg \
         luci-ssl luci-i18n-base-zh-cn luci-i18n-firewall-zh-cn luci-i18n-opkg-zh-cn luci-i18n-openclash-zh-cn \
         luci-app-openclash uhttpd rpcd; do
  s=$(grep -m1 "^CONFIG_PACKAGE_${p}=" "$CFG")
  [ -n "$s" ] && echo "OK   $s" || echo "MISS $p"
done
} > "$OUT" 2>&1
echo wrote
