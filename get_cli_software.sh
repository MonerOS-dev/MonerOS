#!/bin/bash
set -e

# Define both target directories
TARGET_DIRS=(
    "/root/MonerOS_Project/HotWalletOS/config/includes.chroot/usr/local/bin"
    "/root/MonerOS_Project/ColdWalletOS/config/includes.chroot/usr/local/bin"
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
# Monero CLI
########################################
echo "=== Monero CLI ==="
mkdir monero && cd monero
wget -q https://downloads.getmonero.org/cli/linux64 -O monero-cli.tar.bz2
tar -xf monero-cli.tar.bz2

for DIR in "${TARGET_DIRS[@]}"; do
    cp monero-x86_64-linux-gnu-*/* "$DIR/"
done
cd ..

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
# Cleanup
########################################
echo "=== Cleaning up build directory ==="
rm -rf "$BUILD"

echo "=== DONE ==="