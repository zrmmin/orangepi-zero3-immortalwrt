#!/usr/bin/env bash
ND=/home/zrm/build/immortalwrt/build_dir/target-aarch64_generic_musl/node-v22.22.2
echo "--- node 编译已用时(目录创建至今) ---"
START=$(sudo stat -c %Y "$ND" 2>/dev/null)
NOW=$(date +%s)
echo "约 $(( (NOW-START)/60 )) 分钟"
echo "--- 当前在编什么(最近修改文件路径关键词) ---"
sudo find "$ND/out" -type f -name '*.o' -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -3 | sed 's#.*/obj.target/##'
echo "--- 已生成 .o 总数 ---"
sudo find "$ND/out" -name '*.o' 2>/dev/null | wc -l
echo "--- 是否到 mksnapshot / 链接阶段 ---"
sudo find "$ND/out/Release" -maxdepth 1 -name 'mksnapshot' -o -maxdepth 1 -name 'node' 2>/dev/null
ls -la "$ND/out/Release/node" 2>/dev/null && echo 'node二进制已出现(接近完成)' || echo 'node二进制尚未链接'
