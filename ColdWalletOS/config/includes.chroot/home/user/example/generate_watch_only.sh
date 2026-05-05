#!/bin/bash
set -e

WALLET_DIR="/wallet"
COLD_WALLET="$WALLET_DIR/cold.wallet"

SALLY_DIR="/sally"
WATCH_ONLY="$SALLY_DIR/watch_only.wallet"

echo "[ColdWalletOS] Checking for watch-only wallet..."

# Ensure cold wallet exists
if [ ! -f "$COLD_WALLET" ]; then
    echo "[ColdWalletOS] ERROR: No cold wallet found at $COLD_WALLET"
    echo "Create a cold wallet first using monero-wallet-cli."
    exit 1
fi

# Ensure sally port is mounted
if ! mountpoint -q "$SALLY_DIR"; then
    echo "[ColdWalletOS] ERROR: Sally port not mounted at $SALLY_DIR"
    echo "Unlock and mount the VeraCrypt sally port first."
    exit 1
fi

# If watch-only wallet already exists, skip
if [ -f "$WATCH_ONLY" ]; then
    echo "[ColdWalletOS] Watch-only wallet already exists at $WATCH_ONLY"
    exit 0
fi

echo "[ColdWalletOS] Creating watch-only wallet on sally port..."

# Extract view key
VIEW_KEY=$(monero-wallet-cli --wallet-file "$COLD_WALLET" --password "" --command "viewkey" \
    | grep "View key" | awk '{print $3}')

# Extract primary address
ADDRESS=$(monero-wallet-cli --wallet-file "$COLD_WALLET" --password "" --command "address" \
    | head -n 1 | awk '{print $2}')

# Create watch-only wallet on the sally port
monero-wallet-cli \
    --generate-from-view-key "$WATCH_ONLY" \
    --address "$ADDRESS" \
    --view-key "$VIEW_KEY" \
    --password "" \
    --restore-height 0

echo "[ColdWalletOS] Watch-only wallet created at $WATCH_ONLY"
echo "[ColdWalletOS] You can now open this wallet on Windows/macOS/Linux using Monero GUI/CLI."
