# GPL 对应源码义务 (Written Offer for Corresponding Source)

如果你在 GitHub Releases 等渠道**分发本项目编译好的镜像**(`*.img` / `*.img.gz`),
该镜像包含 Linux 内核、BusyBox、ImmortalWrt 等 **GPL-2.0** 软件。按 GPL-2.0 第 3 条,
你必须向接收者提供与二进制**完全对应的源代码**(Complete Corresponding Source),
或一份有效的书面承诺。本文件即用于满足该义务,请按发布时的实际情况填写并保留。

## 1. 精确锁定的上游版本(发布时必须填写实际 commit)

> 在出镜像的那次构建后,用 `git -C <repo> rev-parse HEAD` 记录各上游仓库的精确 commit。

| 组件 | 仓库 URL | 分支/Tag | Commit |
|---|---|---|---|
| ImmortalWrt | https://github.com/immortalwrt/immortalwrt | `master` | `6efdfa7a1fd7491a74deba9b2726bf61332d8c82` |
| orangepi-build(拉取下列内核/U-Boot) | https://github.com/orangepi-xunlong/orangepi-build | `master` | `7f776a2` |
| Linux kernel | (由 orangepi-build 拉取)`orange-pi-6.1-sun50iw9` | 6.1.31-sun50iw9 | 见 orangepi-build 对应锁定 |
| U-Boot | (由 orangepi-build 拉取) | `v2024.01` (orangepi) | 见 orangepi-build 对应锁定 |
| OpenClash | https://github.com/vernesong/OpenClash | 经 ImmortalWrt feed 锁定 | 随上述 ImmortalWrt commit |

发布镜像:`openwrt_h618_zero3_immortalwrt_k6.1.31-sun50iw9.img.gz`
SHA256:`31e7ca341b06fa329ac6a79c888f0bc7a277be02923de520f2423ee1aa25fc05`

## 2. 构建配置

- ImmortalWrt `.config` / `diffconfig`:请在 Release 附件里附上(`make diffconfig > config.seed`)。
- 内核 `.config`:同样附上。
- 本仓库 `build-scripts/` 即完整的构建步骤记录。

## 3. 书面承诺(随镜像一并提供)

> 任何收到本镜像二进制的人,均可在镜像发布后 **3 年内**,通过本仓库 Issue 或
> 邮件向维护者索取与该镜像完全对应的源代码;维护者将以不超过物理介质成本的费用提供,
> 或提供等效的下载链接。上游源码也可按上表 URL + commit 自行获取。

## 4. 专有固件

镜像内的 `wcnmodem.bin` / `wifi_2355b001_*.ini` 为 Unisoc/OrangePi 专有可再分发固件,
**不受 GPL 覆盖**,来源见 `CREDITS.md`。分发时请遵守其各自条款。

---

最省心的合规方式:**只发布本仓库(配方 + 源码),不发布镜像二进制**。
本文件适用于你确实想发镜像 Release 的情况。
