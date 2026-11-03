#!/bin/bash
set -e

# Define both target directories
TARGET_DIRS=(
    "$HOME/MonerOS/HotWalletOS/config/includes.chroot/usr/local/bin/binaries"
    "$HOME/MonerOS/ColdWalletOS/config/includes.chroot/usr/local/bin/binaries"
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
echo "=== Bitcoin Core ==="
mkdir bitcoin && cd bitcoin
wget https://bitcoincore.org/bin/bitcoin-core-26.0/bitcoin-26.0-x86_64-linux-gnu.tar.gz
tar -xf bitcoin-26.0-x86_64-linux-gnu.tar.gz

for DIR in "${TARGET_DIRS[@]}"; do
    cp bitcoin-26.0/bin/* "$DIR/"
done
cd ..


########################################
# Electrum CLI
########################################
echo "=== Electrum CLI ==="
mkdir electrum && cd electrum

wget https://download.electrum.org/4.7.2/electrum-4.7.2-x86_64.AppImage -O electrum
chmod +x electrum

# Copy to both HotWalletOS and ColdWalletOS
for DIR in "${TARGET_DIRS[@]}"; do
    cp electrum "$DIR/electrum"
done

cd ..

########################################
# Electrum Personal Server (HotWallet Only)
########################################
echo "=== Electrum Personal Server ==="
mkdir eps && cd eps

# Download the latest source code tarball directly
wget https://github.com/chris-belcher/electrum-personal-server/archive/refs/heads/master.tar.gz -O eps.tar.gz
tar -xf eps.tar.gz

# Flatten and place into HotWalletOS binaries path
mkdir -p "${TARGET_DIRS[0]}/eps"
cp -r electrum-personal-server-*/* "${TARGET_DIRS[0]}/eps/"
rm -f eps.tar.gz

cd ..


########################################
# BasicSwap DEX Source (For XMR <-> BTC)
########################################
echo "=== BasicSwap DEX Source ==="
mkdir basicswap-source && cd basicswap-source

# Clone the official repository so it's baked into HotWalletOS for manual setup later
git clone https://github.com/basicswap/basicswap.git

# Bundle it into the HotWalletOS binaries path (or a dedicated opt directory)
mkdir -p "${TARGET_DIRS[0]}/basicswap"
cp -r basicswap/* "${TARGET_DIRS[0]}/basicswap/"

cd ..




########################################
# Cleanup
########################################
echo "=== Cleaning up build directory ==="
rm -rf "$BUILD"

echo "=== DONE ==="