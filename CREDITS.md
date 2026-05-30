# 上游组件、版本与许可 (Credits, versions & licenses)

本项目是"构建配方",最终产物由以下上游组件组成。请在分发镜像时一并提供本文件。

| 组件 | 角色 | 来源 | 许可 |
|---|---|---|---|
| ImmortalWrt | rootfs / 包系统 | https://github.com/immortalwrt/immortalwrt | GPL-2.0(各包含自身许可) |
| OpenWrt | 上游基座 | https://github.com/openwrt/openwrt | GPL-2.0 |
| LuCI | Web 界面 | https://github.com/openwrt/luci | Apache-2.0 / 部分 MIT |
| Linux kernel (OrangePi vendor 6.1.31) | 内核 | https://github.com/orangepi-xunlong/linux-orangepi | GPL-2.0 |
| `sprdwl_ng` / `uwe5622_bsp_sdio` | UWE5622 Wi-Fi 驱动 | OrangePi vendor kernel(out-of-tree) | GPL-2.0 |
| U-Boot (orangepi) | 引导 | https://github.com/orangepi-xunlong/u-boot-orangepi | GPL-2.0 |
| OpenClash | 代理 | https://github.com/vernesong/OpenClash | GPL-3.0 |
| packit / ophub 打包 | 镜像打包 | https://github.com/ophub/amlogic-s9xxx-armbian | 见其仓库 |

## 专有 / 可再分发 blob(不随本仓库分发)

| 文件 | 内容 | 来源 | 说明 |
|---|---|---|---|
| `wcnmodem.bin` | Marlin3L-AB Wi-Fi/BT 固件 | https://github.com/orangepi-xunlong/firmware | Unisoc 专有,可再分发;请从官方源获取 |
| `wifi_2355b001_1ant.ini` / `_2ant.ini` | RF 校准/配置 | OrangePi vendor 资源 | 同上 |

> 这些文件**未包含在本仓库**(见 `.gitignore`)。如分发镜像,请遵守其各自的再分发条款,
> 并在发布说明中注明出处。

## 本项目自身

- `build-scripts/`、文档:GPL-2.0。
- `package/luci-app-zero3ap/`:Apache-2.0。
