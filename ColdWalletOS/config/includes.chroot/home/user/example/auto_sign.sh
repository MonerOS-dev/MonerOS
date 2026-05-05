#!/bin/bash
set -e

WALLET_MNT="/wallet"
WALLET_MAPPER="wallet_crypt"
COLD_WALLET="$WALLET_MNT/cold.wallet"

SALLY_MNT="/sally"
UNSIGNED_DIR="$SALLY_MNT/unsigned"
SIGNED_DIR="$SALLY_MNT/signed"

echo "[ColdWalletOS] Starting sally-port auto-sign."

# -------------------------------
# 1. Ensure /wallet is mounted
# -------------------------------
if ! mountpoint -q "$WALLET_MNT"; then
    echo "[ColdWalletOS] /wallet not mounted, attempting to open and mount..."

    BOOTDEV=$(lsblk -no pkname "$(findmnt -no SOURCE /run/live/medium)" | head -n 1)
    if [ -z "$BOOTDEV" ]; then
        echo "[ColdWalletOS] ERROR: Could not detect boot device."
        exit 1
    fi

    PERSIST="/dev/${BOOTDEV}2"

    if ! sudo cryptsetup isLuks "$PERSIST" >/dev/null 2>&1; then
        echo "[ColdWalletOS] ERROR: $PERSIST is not a LUKS device."
        echo "Run init_wallet.sh first."
        exit 1
    fi

    sudo cryptsetup open "$PERSIST" "$WALLET_MAPPER"

    if ! grep -q "$WALLET_MNT" /etc/fstab; then
        echo "/dev/mapper/$WALLET_MAPPER $WALLET_MNT ext4 defaults 0 2" \
            | sudo tee -a /etc/fstab >/dev/null
    fi

    sudo mount "$WALLET_MNT"
fi

if [ ! -f "$COLD_WALLET" ]; then
    echo "[ColdWalletOS] ERROR: Cold wallet not found at $COLD_WALLET"
    exit 1
fi

# -------------------------------
# 2. Ensure sally port is mounted (VeraCrypt)
# -------------------------------
if ! mountpoint -q "$SALLY_MNT"; then
    echo "[ColdWalletOS] Sally port not mounted."
    echo "[ColdWalletOS] Attempting to detect and mount VeraCrypt sally port..."

    # Find non-boot partition as candidate (simple heuristic)
    BOOTDEV=$(lsblk -no pkname "$(findmnt -no SOURCE /run/live/medium)" | head -n 1)
    CANDIDATE=$(lsblk -pn -o NAME,TYPE | awk '$2=="part"{print $1}' | grep -v "${BOOTDEV}2" | head -n 1)

    if [ -z "$CANDIDATE" ]; then
        echo "[ColdWalletOS] ERROR: Could not detect external sally port partition."
        exit 1
    fi

    sudo mkdir -p "$SALLY_MNT"
    veracrypt --text --mount "$CANDIDATE" "$SALLY_MNT"
fi

sudo mkdir -p "$UNSIGNED_DIR" "$SIGNED_DIR"

# -------------------------------
# 3. Find unsigned transactions
# -------------------------------
shopt -s nullglob
UNSIGNED_TXS=("$UNSIGNED_DIR"/*.unsigned)

if [ ${#UNSIGNED_TXS[@]} -eq 0 ]; then
    echo "[ColdWalletOS] No unsigned transactions found in $UNSIGNED_DIR."
    exit 0
fi

echo "[ColdWalletOS] Found ${#UNSIGNED_TXS[@]} unsigned transaction(s)."

# -------------------------------
# 4. Ask about donation (once)
# -------------------------------
echo
read -r -p "Would you like to donate 1% to the developer? (y/n) " DONATE

DONATE_FLAG=""
if [[ "$DONATE" =~ ^[Yy]$ ]]; then
    DONATE_ADDRESS="YOUR_DONATION_ADDRESS_HERE"
    DONATE_FLAG="--donate-address $DONATE_ADDRESS --donate-amount 1%"
    echo "[ColdWalletOS] Donation enabled (1%)."
else
    echo "[ColdWalletOS] Donation disabled."
fi

# -------------------------------
# 5. Sign each transaction
# -------------------------------
for TX in "${UNSIGNED_TXS[@]}"; do
    BASENAME=$(basename "$TX" .unsigned)
    OUTFILE="$SIGNED_DIR/${BASENAME}.signed"

    echo "[ColdWalletOS] Signing $TX -> $OUTFILE"

    monero-wallet-cli \
        --wallet-file "$COLD_WALLET" \
        --password "" \
        --command "sign_transfer $TX $OUTFILE $DONATE_FLAG"

    echo "[ColdWalletOS] Signed: $OUTFILE"
    rm -f "$TX"
done

echo
echo "[ColdWalletOS] All transactions signed."
echo "[ColdWalletOS] Signed files are in: $SIGNED_DIR"
echo "[ColdWalletOS] Done."
