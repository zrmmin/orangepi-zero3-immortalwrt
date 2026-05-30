#!/usr/bin/env bash
set -uo pipefail
OUT=/mnt/d/zrm/orangepi/zero3/build-scripts/out-51-find.txt
B=/home/zrm/build/orangepi-build
K=$B/kernel/orange-pi-6.1-sun50iw9
HEX=$K/drivers/net/wireless/uwe5622/unisocwcn/fw/wcnmodem.bin.hex
{
echo "=== 精确解码我转出的 wcnmodem.bin 头部 ==="
TMP=/tmp/wcnmodem_decode.bin
sudo python3 - "$HEX" "$TMP" <<'PY'
import re,sys,struct
data=open(sys.argv[1]).read()
b=bytes(int(x,16) for x in re.findall(r'0x([0-9A-Fa-f]{2})',data))
open(sys.argv[2],'wb').write(b)
print("total bytes:",len(b))
magic=b[0:4]; ver=struct.unpack('<I',b[4:8])[0]; cnt=struct.unpack('<I',b[8:12])[0]
print("magic:",magic, "version:",ver, "img_count:",cnt)
off=12
for i in range(cnt):
    tag=b[off:off+4]; o=struct.unpack('<I',b[off+4:off+8])[0]; s=struct.unpack('<I',b[off+8:off+12])[0]
    print(f"  img[{i}] tag={tag!r} offset=0x{o:x} size=0x{s:x}")
    off+=12
PY
echo
echo "=== orangepi-build 中所有 wcnmodem* 文件 (不含我们生成的镜像) ==="
sudo find "$B" -iname 'wcnmodem*' 2>/dev/null | grep -v '/output/' | head -40
echo
echo "=== orangepi-build external/ 里的固件包 / firmware 安装脚本 ==="
sudo find "$B/external" -iname '*wcn*' -o -iname '*uwe*' -o -iname '*marlin*' 2>/dev/null | head -40
echo
echo "=== 搜索把固件拷到 /lib/firmware 的逻辑 (family/board 脚本) ==="
sudo grep -rn "wcnmodem\|uwe5622\|lib/firmware" "$B/external/cache/sources" 2>/dev/null | grep -i firmware | head -20
sudo grep -rln "wcnmodem" "$B" 2>/dev/null | grep -v '/output/' | grep -viE '\.hex$|\.bin$|\.c$|\.h$|\.o$|\.ko$' | head -30
} > "$OUT" 2>&1
echo wrote
