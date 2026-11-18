# IK-Q3000 ImmortalWrt + OpenClash

GitHub Actions 固件编译仓库，目标机型：**iKuai IK-Q3000（MediaTek MT7981）**。

此仓库基于 [hanwckf/immortalwrt-mt798x](https://github.com/hanwckf/immortalwrt-mt798x) 的 `openwrt-21.02` 分支，使用 **Q3000 专用配置**，把 OpenClash、TUN / TProxy 和 IPv4 透明代理相关模块编译进系统。

## 使用方式

1. 进入 **Actions → Build IK-Q3000 firmware → Run workflow**，选择 `main` 开始。
2. 编译成功后，打开对应 Workflow Run → **Artifacts** 下载压缩包。
3. 产物里只应使用 **`ikuai_q3000`** 对应的 `factory.bin` 或 `sysupgrade.bin`，不要刷其他 MT7981 机型。
4. **刷写前核实引导程序支持的镜像格式、分区布局和文件大小**。Actions 通过表示编译成功，不代表已在设备实机测试。
5. 刷机后进入 LuCI 的 **服务 → OpenClash**；Mihomo 核心及订阅按 OpenClash 界面提示安装和配置。若未随固件集成核心，需要联网后下载。

## 构建说明

- Ubuntu 20.04 容器内作为非 root 用户编译，适配较旧 MT798x 源码环境。
- 固件包含：`luci-app-openclash`、`kmod-tun`、`kmod-ipt-tproxy`、`iptables-mod-tproxy`、`iptables-mod-extra`、`dnsmasq-full` 等。
- 默认不包含任何代理订阅、账号或凭据。
- 日志和产物以 GitHub Actions 为准，编译失败时从失败步骤调整。

> 首个版本是 **构建实验版**。已知能够启动的旧 ImmortalWrt 固件建议作为恢复基准保留。不要因为看到 `factory.bin` 就假定它能在所有 IK U-Boot 版本直接刷写。
