#!/usr/bin/env bash
set -Eeuo pipefail

# This script runs as an unprivileged user on an Ubuntu 20.04 CI container.
WORK="$GITHUB_WORKSPACE/work"
OUT="$GITHUB_WORKSPACE/artifacts"
SRC="$WORK/immortalwrt"
mkdir -p "$WORK" "$OUT"

echo "::group::Checkout known MT7981 source"
git clone --depth 1 --branch openwrt-21.02 \
  https://github.com/hanwckf/immortalwrt-mt798x.git "$SRC"
cd "$SRC"
git rev-parse HEAD | tee "$OUT/upstream-commit.txt"
echo "::endgroup::"

echo "::group::Install package feeds"
./scripts/feeds update -a
./scripts/feeds install -a
echo "::endgroup::"

echo "::group::Add OpenClash feed package"
git clone --depth 1 https://github.com/vernesong/OpenClash.git "$WORK/openclash"
cp -a "$WORK/openclash/luci-app-openclash" package/luci-app-openclash
git -C "$WORK/openclash" rev-parse HEAD | tee "$OUT/openclash-commit.txt"
echo "::endgroup::"

echo "::group::Configure only IK-Q3000 and required packages"
cp defconfig/mt7981-ax3000.config .config

# The upstream default builds several devices. Explicitly select only IK-Q3000.
while IFS= read -r config_line; do
  symbol=$(printf '%s' "$config_line" | cut -d= -f1 | cut -c8-)
  ./scripts/config -d "$symbol"
done < <(grep '^CONFIG_TARGET_DEVICE_mediatek_mt7981_DEVICE_.*=y$' .config || true)

./scripts/config -e TARGET_MULTI_PROFILE
./scripts/config -e TARGET_DEVICE_mediatek_mt7981_DEVICE_ikuai_q3000

# dnsmasq-full replaces the simpler dnsmasq.
./scripts/config -d PACKAGE_dnsmasq
for pkg in \
  luci luci-compat luci-app-openclash \
  dnsmasq-full bash curl ca-bundle ip-full \
  ruby ruby-yaml unzip \
  iptables ipset iptables-mod-tproxy iptables-mod-extra \
  kmod-tun kmod-ipt-tproxy kmod-ipt-nat kmod-inet-diag; do
  ./scripts/config -e "PACKAGE_$pkg"
done

make defconfig

# Fail rather than upload an image if key flags are unavailable in this checkout.
for flag in \
  CONFIG_TARGET_DEVICE_mediatek_mt7981_DEVICE_ikuai_q3000=y \
  CONFIG_PACKAGE_luci-app-openclash=y \
  CONFIG_PACKAGE_kmod-tun=y \
  CONFIG_PACKAGE_kmod-ipt-tproxy=y \
  CONFIG_PACKAGE_iptables-mod-tproxy=y \
  CONFIG_PACKAGE_dnsmasq-full=y; do
  if ! grep -Fxq "$flag" .config; then
    echo "::error::Required build configuration missing: $flag"
    exit 1
  fi
done

cp .config "$OUT/final-build.config"
echo "::endgroup::"

echo "::group::Build firmware"
make download -j4 V=s
make -j"$(nproc)" V=s
echo "::endgroup::"

echo "::group::Collect only Q3000 images"
find bin/targets/mediatek/mt7981 -maxdepth 1 -type f -name '*ikuai_q3000*' -print
find bin/targets/mediatek/mt7981 -maxdepth 1 -type f \
  \( -name '*ikuai_q3000*factory.bin' -o -name '*ikuai_q3000*sysupgrade.bin' \) \
  -exec cp -v {} "$OUT/" \;
cd "$OUT"
sha256sum ./*.bin > SHA256SUMS
ls -lh
echo "::endgroup::"
