# ImmortalWrt for Orange Pi Zero3 (H618) with onboard UWE5622 Wi-Fi

> A reproducible build recipe that runs **ImmortalWrt** on the **Orange Pi Zero3 (H618, 2GB)**
> with the **onboard UWE5622 (Cdtech 20U5622) Wi-Fi working as an AP**, OpenClash, LuCI, SSH,
> and dual-WAN failover (Ethernet + USB tethering).

中文说明见下。This repo ships the **build recipe and source only** — no proprietary blobs.

---

## 这是什么

香橙派 Zero3(全志 H618,2GB 版本)运行 ImmortalWrt 的**可复现构建配方**,重点解决了
**板载 UWE5622(丝印 Cdtech 20U5622)无线网卡作为 AP 热点**的可用性问题,并内置:

- OpenClash
- LuCI Web 界面 + i18n 中文
- SSH / SFTP / git(便于 Cursor 远程连接)
- 板载 Wi-Fi AP(自研 `luci-app-zero3ap` 管理,见下)
- 双 WAN:以太网口(`eth0`,metric 10)+ 手机 USB 共享(`usb0`,metric 20)自动切换

## 为什么是"自研 luci-app"而不是原生无线页

板载芯片用的是 Unisoc 的 **`sprdwl_ng` fullmac** 驱动(vendor out-of-tree)。
实测 OpenWrt 原生 `wifi-scripts` 的 `nl80211` 自动探测(`10-wifi-detect` hotplug)
会让该驱动**直接卡死整个系统**(串口无响应)。

因此本项目放弃 netifd 接管无线,改为:

- **独立 `hostapd`** 跑 AP(稳定),配置由 `/etc/config/zero3ap` 生成;
- 自研 **`luci-app-zero3ap`** 在 LuCI 里改 SSID / 密码 / 信道,"保存并应用"自动重启 AP;
- `br-lan` 必须设 `option bridge_empty '1'`,否则空网桥开机拿不到 IP、DHCP 不工作。

> 这是针对该 fullmac 驱动 bug 的 **workaround**,不是上游推荐做法。
> 详见 [是否能合并进官方](#关于上游合并)。

## 硬件

| 项目 | 值 |
|---|---|
| 板卡 | Orange Pi Zero3 |
| SoC | Allwinner H618 (sun50iw9, Cortex-A53) |
| 内存 | 2GB |
| Wi-Fi/BT | Unisoc UWE5622 (Marlin3L-AB), 丝印 Cdtech 20U5622 |
| 内核 | OrangePi vendor kernel 6.1.31 |

## 构建概览

构建是 **混合流水线**(脚本在 `build-scripts/`,需 Ubuntu 22.04 / WSL2):

1. OrangePi vendor 内核 6.1.31 编译(含 `sprdwl_ng`)→ 见 `10/13/22`;
2. ImmortalWrt rootfs 编译(OpenClash/LuCI/SSH 等包)→ 见 `14/54/57`;
3. 用 packit 把内核 + rootfs 打成可烧录镜像 → 见 `23/24/25`;
4. 注入固件/INI、修复启动、配置网络与 AP → 见 `68/72/73/82/83`。

> 脚本里含大量调试/勘察脚本(编号穿插),关键脚本见上。它们带有作者环境的绝对路径
> (`/home/zrm/...`),复现时请按需修改。

### 固件 blob(重要 / 合规)

`wcnmodem.bin`(Marlin3L-AB 原始固件)与 `wifi_2355b001_*.ini`(RF 校准)是
**Unisoc/OrangePi 的专有可再分发文件,本仓库不包含**。请从官方源获取:

- https://github.com/orangepi-xunlong/firmware

放置路径见 `build-scripts/73-final-wifi-ap.sh`。

## 自研包:`package/luci-app-zero3ap`

一个标准 OpenWrt/LuCI 包(Apache-2.0),可直接放进任意 OpenWrt/ImmortalWrt 源码树:

```sh
cp -r package/luci-app-zero3ap <openwrt>/package/
cd <openwrt>
make package/luci-app-zero3ap/compile V=s
```

## 烧录 / 使用

- 默认 AP:SSID `OrangePi-Zero3`,密码 `12345678`(请在 LuCI 里改掉)。
- LuCI:`网络 → 板载 AP (WiFi)`。
- 场景切换(以太网上行 / 手机 USB 上行):双 WAN 自动按 metric 故障切换,插谁用谁。

## 关于上游合并

**这套构建脚本不适合直接 PR 进 ImmortalWrt 官方**(属于个人构建编排)。真正上游需要:
规范的 sunxi/cortexa53 板级支持(DTS/profile)+ 把 UWE5622 驱动打成 kmod 包,
而最大障碍是该 fullmac 驱动与 netifd 的兼容性。本仓库定位为**社区可复现配方**。

唯一较"干净、可被复用"的产物是 `package/luci-app-zero3ap`。

## 许可

- 顶层(构建脚本、文档):**GPL-2.0**,见 [`LICENSE`](LICENSE)。
- `package/luci-app-zero3ap`:**Apache-2.0**,见该目录下 `LICENSE`(与 LuCI 一致)。
- 上游组件版本/出处/许可见 [`CREDITS.md`](CREDITS.md)。
- 若你分发编译好的镜像(GPL 二进制),对应源码义务见 [`SOURCES.md`](SOURCES.md)。

## 致谢

ImmortalWrt、OpenWrt、LuCI、OrangePi(Xunlong)、Allwinner、Unisoc 及相关社区。
