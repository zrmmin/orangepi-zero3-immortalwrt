#!/usr/bin/env bash
echo "--- 活跃进程 (CPU 前8) ---"
ps -e -o pid,pcpu,comm --sort=-pcpu | head -9
echo "--- node 构建目录最新修改文件 ---"
ND=$(sudo find /home/zrm/build/immortalwrt/build_dir -maxdepth 3 -iname 'node-v*' -type d 2>/dev/null | head -1)
echo "ND=$ND"
if [ -n "$ND" ]; then
  echo "3分钟内更新的文件数: $(sudo find "$ND" -newermt '-3 minutes' -type f 2>/dev/null | wc -l)"
  echo "最近修改的几个文件:"
  sudo find "$ND" -type f -printf '%T+ %p\n' 2>/dev/null | sort -r | head -5
fi
