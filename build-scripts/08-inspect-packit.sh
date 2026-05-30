#!/usr/bin/env bash
set -uo pipefail
source /mnt/d/zrm/orangepi/zero3/build-scripts/lib-common.sh
P="$PACKIT_DIR"

echo "############ packit top-level ############"
ls -1 "$P" 2>/dev/null

echo
echo "############ README (head) ############"
sed -n '1,80p' "$P/README.md" 2>/dev/null

echo
echo "############ make / mk scripts ############"
ls -1 "$P" 2>/dev/null | grep -iE "mk_|make|\.sh$"

echo
echo "############ grep board support: zero3 / allwinner / sun50iw9 / h6 ############"
grep -rniE "zero3|sun50iw9|allwinner|h618|h616" "$P" 2>/dev/null | grep -viE "\.git" | head -n 50

echo
echo "############ how kernel is located (boot-/dtb-/modules- tar.gz) ############"
grep -rniE "boot-|dtb-|modules-|header-|kernel.*tar.gz|KERNEL_VERSION|flippy" "$P"/*.sh 2>/dev/null | head -n 40

echo
echo "############ kernel dir hints ############"
grep -rniE "/opt/kernel|kernel/|KERNEL_PKG|SERVER_KERNEL" "$P"/*.sh 2>/dev/null | head -n 30

echo "INSPECT-PACKIT-DONE"
