#!/usr/bin/env bash
set -uo pipefail
source /mnt/d/zrm/orangepi/zero3/build-scripts/lib-common.sh
P="$PACKIT_DIR"

echo "############ mk_h6_vplus.sh (full) ############"
cat "$P/mk_h6_vplus.sh" 2>/dev/null

echo
echo "############ files/bootfiles/allwinner (list) ############"
ls -la "$P/files/bootfiles/allwinner" 2>/dev/null
echo "--- uEnv.txt ---"
cat "$P/files/bootfiles/allwinner/uEnv.txt" 2>/dev/null
echo "--- boot cmd(s) ---"
ls -la "$P/files/bootfiles/allwinner/"*.cmd 2>/dev/null
cat "$P/files/bootfiles/allwinner/"*.cmd 2>/dev/null

echo
echo "############ public_funcs: extract_allwinner_boot_files ############"
awk '/function extract_allwinner_boot_files/,/^}/' "$P/public_funcs" 2>/dev/null

echo "INSPECT9-DONE"
