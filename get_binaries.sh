#!/bin/bash
set -e

# Define both target directories
TARGET_DIRS=(
    "/root/MonerOS/HotWalletOS/config/includes.chroot/usr/local/bin/binaries"
    "/root/MonerOS/ColdWalletOS/config/includes.chroot/usr/local/bin/binaries"
)

echo "=== Initializing Target Directories ==="
for DIR in "${TARGET_DIRS[@]}"; do
    mkdir -p "$DIR"
    echo "Verified path: $DIR"
done

# Temporary build directory
BUILD="/tmp/build-cli"
rm -rf "$BUILD"
mkdir -p "$BUILD"
cd "$BUILD"


########################################
# Monero CLI
########################################
echo "=== Monero CLI ==="
mkdir monero && cd monero

# latest version
#wget https://downloads.getmonero.org/cli/linux64 -O monero-cli.tar.bz2

# v0.18.5.1
wget --show-progress https://downloads.getmonero.org/cli/monero-linux-x64-v0.18.5.1.tar.bz2 -O monero-cli.tar.bz2

tar -xf monero-cli.tar.bz2

for DIR in "${TARGET_DIRS[@]}"; do
    cp monero-x86_64-linux-gnu-*/* "$DIR/"
done
cd ..

########################################
# Bitcoin Core
########################################
#echo "=== Bitcoin Core ==="
#mkdir bitcoin && cd bitcoin
#wget -q https://bitcoincore.org/bin/bitcoin-core-26.0/bitcoin-26.0-x86_64-linux-gnu.tar.gz
#tar -xf bitcoin-26.0-x86_64-linux-gnu.tar.gz

#for DIR in "${TARGET_DIRS[@]}"; do
#    cp bitcoin-26.0/bin/* "$DIR/"
#done
#cd ..

########################################
# Electrum CLI
########################################
#echo "=== Electrum CLI ==="
#mkdir electrum && cd electrum

#wget -q https://download.electrum.org/4.7.2/electrum-4.7.2-x86_64.AppImage -O electrum
#chmod +x electrum

#for DIR in "${TARGET_DIRS[@]}"; do
#    cp electrum "$DIR/electrum"
#done
#cd ..

########################################
# Eigenwallet Swap CLI
########################################
#echo "=== Eigenwallet Swap CLI ==="
#mkdir swap-cli && cd swap-cli

# Pin specific release version
#SWAP_VERSION="4.14.0"

# Download the x86_64 Linux binary tarball
#wget --show-progress "https://github.com/eigenwallet/core/releases/download/${SWAP_VERSION}/swap_${SWAP_VERSION}_Linux_x86_64.tar.gz" -O swap.tar.gz

#tar -xf swap.tar.gz

# Copy exclusively to HotWalletOS
#cp swap "${TARGET_DIRS[0]}/"

#cd ..




########################################
# Cleanup
########################################
echo "=== Cleaning up build directory ==="
rm -rf "$BUILD"

echo "=== DONE ==="