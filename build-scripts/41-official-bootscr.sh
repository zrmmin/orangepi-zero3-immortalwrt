#!/usr/bin/env bash
set -uo pipefail
IMG=/home/zrm/build/official/official.img
LD=$(sudo losetup -f -P --show "$IMG")
B=$(mktemp -d)
sudo mount "${LD}p1" "$B"
echo "=== 官方 boot.scr (去64字节uImage头) ==="
sudo dd if="$B/boot.scr" bs=1 skip=72 2>/dev/null | strings -n 3
echo
echo "=== boot.scr 全 strings ==="
sudo strings -n 4 "$B/boot.scr"
echo
echo "=== dtb 标识 ==="
sudo strings "$B/dtb" | grep -iE 'orangepi|zero3|sun50i-h618' | head -3
sudo umount "$B"; sudo losetup -d "$LD"; rmdir "$B"
echo DONE
