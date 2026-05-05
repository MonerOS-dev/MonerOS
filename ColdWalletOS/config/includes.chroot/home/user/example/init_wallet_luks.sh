#!/bin/bash
set -e

echo "[ColdWalletOS] Initializing system..."

if [ -z "$1" ]; then
    echo "Usage: $0 /dev/sdX"
    echo "       (external drive to be wiped and used as VeraCrypt sally port)"
    exit 1
fi

EXT_DEV="$1"
EXT_MNT="/sally"

WALLET_MNT="/wallet"
WALLET_MAPPER="wallet_crypt"

echo "[ColdWalletOS] External device selected: $EXT_DEV"
echo "WARNING: This device will be COMPLETELY WIPED and turned into a VeraCrypt volume."
read -r -p "Type YES to continue: " CONFIRM

if [ "$CONFIRM" != "YES" ]; then
    echo "[ColdWalletOS] Aborted."
    exit 1
fi

# ---------------------------------------------------------
# 1. Initialize internal /wallet LUKS (boot USB)
# ---------------------------------------------------------

echo "[ColdWalletOS] Setting up internal encrypted /wallet..."

sudo mkdir -p "$WALLET_MNT"

# Detect boot device by tracing squashfs backing store
ROOTFS_SRC=$(findmnt -t squashfs -no SOURCE 2>/dev/null | head -n 1)

if [ -z "$ROOTFS_SRC" ]; then
    echo "[ColdWalletOS] ERROR: Could not locate squashfs rootfs source."
    exit 1
fi

BOOTDEV=$(lsblk -no pkname "$ROOTFS_SRC" 2>/dev/null || true)

if [ -z "$BOOTDEV" ]; then
    echo "[ColdWalletOS] ERROR: Could not detect boot device."
    exit 1
fi

DEV="/dev/$BOOTDEV"
PERSIST="${DEV}2"

echo "[ColdWalletOS] Boot device detected: $DEV"

# Create partition 2 if missing (GPT-safe)
if ! lsblk -no NAME "$PERSIST" >/dev/null 2>&1; then
    echo "[ColdWalletOS] Creating partition 2 on $DEV..."
    sudo sfdisk "$DEV" <<EOF
label: gpt
device: $DEV
unit: sectors

${DEV}2 : type=8300
EOF
    sleep 2
fi

# Initialize LUKS if needed
if ! sudo cryptsetup isLuks "$PERSIST" >/dev/null 2>&1; then
    echo "[ColdWalletOS] Initializing LUKS on $PERSIST..."
    sudo cryptsetup luksFormat "$PERSIST"
fi

echo "[ColdWalletOS] Opening internal LUKS container..."
sudo cryptsetup open "$PERSIST" "$WALLET_MAPPER"

# Create ext4 if missing
if ! blkid "/dev/mapper/$WALLET_MAPPER" >/dev/null 2>&1; then
    echo "[ColdWalletOS] Creating ext4 filesystem..."
    sudo mkfs.ext4 -F "/dev/mapper/$WALLET_MAPPER"
fi

# Add to fstab if missing
if ! grep -q "$WALLET_MNT" /etc/fstab; then
    echo "/dev/mapper/$WALLET_MAPPER $WALLET_MNT ext4 defaults 0 2" \
        | sudo tee -a /etc/fstab >/dev/null
fi

echo "[ColdWalletOS] Mounting /wallet..."
sudo mount "$WALLET_MNT"

echo "[ColdWalletOS] Internal encrypted wallet ready at $WALLET_MNT."

# ---------------------------------------------------------
# 2. Initialize EXTERNAL VeraCrypt SALLY PORT
# ---------------------------------------------------------

echo "[ColdWalletOS] Setting up external VeraCrypt sally port on $EXT_DEV..."

# Wipe partition table
sudo wipefs -a "$EXT_DEV"
sudo sfdisk "$EXT_DEV" <<EOF
label: gpt
device: $EXT_DEV
unit: sectors

${EXT_DEV}1 : type=8300
EOF

sleep 2

EXT_PART="${EXT_DEV}1"

# Create VeraCrypt volume (user will be prompted for password)
echo "[ColdWalletOS] Creating VeraCrypt volume on $EXT_PART..."
veracrypt --text --create "$EXT_PART" \
    --volume-type=normal \
    --encryption=AES \
    --hash=SHA-512 \
    --filesystem=none \
    --pim=0 \
    --non-interactive=no

# Mount VeraCrypt volume
sudo mkdir -p "$EXT_MNT"
echo "[ColdWalletOS] Mounting VeraCrypt sally port at $EXT_MNT..."
veracrypt --text --mount "$EXT_PART" "$EXT_MNT"

# Create folders
sudo mkdir -p "$EXT_MNT/unsigned"
sudo mkdir -p "$EXT_MNT/signed"

echo "[ColdWalletOS] External VeraCrypt sally port ready at $EXT_MNT."
echo "[ColdWalletOS] Use this device for importing unsigned and exporting signed transactions."
echo "[ColdWalletOS] Initialization complete."
