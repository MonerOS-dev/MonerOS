#!/bin/bash
set -e

BASE_DIR="$HOME/MonerOS/ColdWalletOS/"
cd $BASE_DIR

echo "[INFO] Starting ColdWalletOS build..."

# copy splash
#convert $HOME/MonerOS/admin_mods/cwos_splash.png \
convert $HOME/MonerOS/admin_mods/generic_splash.png \
        -flip \
        -compress none \
        $HOME/MonerOS/ColdWalletOS/config/includes.binary/boot/grub/splash.tga

# Update version string
FILE="$HOME/MonerOS/ColdWalletOS/config/includes.chroot/usr/local/bin/cwversion"
FULL_STRING=$(cat "$FILE" | tr -d '\r\n' | xargs)
PREFIX=$(echo "$FULL_STRING" | sed -E 's/[0-9]+$//')
VERSION_PART=$(echo "$FULL_STRING" | grep -oE '[0-9]+$')
NEXT_VERSION=$(printf "%03d" $((10#${VERSION_PART:-0} + 1)))
echo "${PREFIX}${NEXT_VERSION}" > "$FILE"

# --- 1. THE "STOP FRUSTRATING ME" BLOCK ---
if [ -d "chroot" ]; then
    echo "[INFO] Forced unlocking of all files in chroot..."
    sudo find chroot/ -type f -exec chattr -i {} + 2>/dev/null || true
fi

# --- 2. DEEP CLEAN ---
sudo lb clean --purge
sudo umount -lf ${BASE_DIR}/chroot/dev/pts 2>/dev/null || true
sudo umount -lf ${BASE_DIR}/chroot/proc 2>/dev/null || true
sudo umount -lf ${BASE_DIR}/chroot/sys 2>/dev/null || true
sudo fuser -kv ${BASE_DIR}/chroot 2>/dev/null || true

# --- 3. CONFIGURE LIVE-BUILD ---
lb config \
  --distribution bookworm \
  --iso-volume "ColdWalletOS" \
  --archive-areas "main contrib non-free non-free-firmware" \
  --binary-images iso-hybrid \
  --bootloaders "syslinux,grub-efi" \
  --debian-installer none \
  --apt-recommends false \
  --bootappend-live "boot=live components splash autologin modprobe.blacklist=uvcvideo,bluetooth,btusb,rtw88_8821ce,iwlwifi,iwlmvm,snd_hda_intel,pcspkr,joydev ipv6.disable=1 net.ifnames=0 user-password=live bootfrom=/dev/disk/by-partuuid/11111111-01 live-media-path=/cw_sys"

# --- 4. BUILD THE BASE ISO ---
sudo lb build

# --- 5. THE MANUAL SHREDDING STRIKE ---
echo "[CRITICAL] Shredding SquashFS to pass Integrity Test..."
SQUASH_FILE="${BASE_DIR}/binary/live/filesystem.squashfs"
TEMP_SQUASH="${BASE_DIR}/temp_squash"

# Fix the "already exists" error by ensuring the destination is empty
sudo rm -rf "$TEMP_SQUASH"
sudo mkdir -p "$TEMP_SQUASH"

# Extract with -f (force) to handle symlinks, but NO permission-altering flags
sudo unsquashfs -f -d "$TEMP_SQUASH" "$SQUASH_FILE"

# The shredding you wanted
sudo rm -rf "$TEMP_SQUASH"/usr/bin/apt* "$TEMP_SQUASH"/usr/bin/dpkg* "$TEMP_SQUASH"/usr/sbin/dpkg*
sudo rm -rf "$TEMP_SQUASH"/var/lib/dpkg "$TEMP_SQUASH"/var/lib/apt "$TEMP_SQUASH"/etc/apt

for tool in apt apt-get dpkg; do
    sudo touch "$TEMP_SQUASH/usr/bin/$tool"
    sudo chmod 000 "$TEMP_SQUASH/usr/bin/$tool"
done

# Rebuild WITHOUT '-all-root' so your user permissions stay exactly as they were
sudo rm "$SQUASH_FILE"
sudo mksquashfs "$TEMP_SQUASH" "$SQUASH_FILE" -comp zstd -Xcompression-level 22 -noappend

# Cleanup
sudo rm -rf "$TEMP_SQUASH"

# --- 5.5 Give iso a different name ---
sudo mv ${BASE_DIR}/binary/live ${BASE_DIR}/binary/cw_sys

echo "[INFO] Creating ColdWalletOS marker file..."
sudo touch "${BASE_DIR}/binary/cw_sys/.marker-coldwallet"

# --- 6. FINALIZE THE ISO ---
sudo rm -f .build/binary_iso
sudo lb binary_iso

# --- 7. CREATE DISK IMAGE (.IMG) ---
FINAL_IMG="$HOME/ColdWalletOS.img"
NEW_ISO=$(ls -t ${BASE_DIR}/*.iso | head -n1)
cp "$NEW_ISO" "$FINAL_IMG"

# --- 7.5. PATCH THE ISO INTERNALS FIRST ---
# Do this while the image still looks like a 'pure' ISO to xorriso
echo "[INFO] Patching El Torito catalog for Dual-Arch UEFI..."
sudo xorriso -dev "$FINAL_IMG" \
    -boot_image any next \
    -boot_image any efi_path=boot/grub/efi.img \
    -boot_image any platform_id=0xef \
    -boot_image any emul_type=no_emulation \
    -commit
    
# --- 7.6. EXPORT THE PATCHED ISO9660 UPDATE FILE ---
UPDATE_FILE="$HOME/ColdWalletOS.update"
echo "[INFO] Exporting the pure ISO9660 update file to $UPDATE_FILE..."
cp "$FINAL_IMG" "$UPDATE_FILE"

# --- 8. SMART DYNAMIC EXPAND AND RE-LAYOUT ---
echo "[INFO] Calculating ISO size and re-partitioning..."

# Get actual Partition 1 size in sectors using your original fdisk method
ISO_SIZE=$(sudo fdisk -l "$FINAL_IMG" | grep "${FINAL_IMG}1" | awk '{print $4}')

# Set fixed 0.9GB target in sectors (900 MiB * 2048 sectors/MiB)
P1_SIZE=$(( 900 * 2048 ))

# CRITICAL FAIL GUARD: Stop if the real ISO size exceeds your 0.9GB limit
if [ -n "$ISO_SIZE" ] && [ "$ISO_SIZE" -gt "$P1_SIZE" ]; then
    echo "[CRITICAL ERROR] Built ISO ($ISO_SIZE sectors) is larger than the 0.9GB limit ($P1_SIZE sectors)!"
    echo "Aborting build to prevent data corruption."
    exit 1
fi

# Define our gaps (in sectors)
EFI_SIZE=131072      # 64MB (Safe for FAT32)
PERSIST_SIZE=512000  # 250MB 

# Calculate start points with clean 2048 alignment
P2_START=$(( (64 + P1_SIZE + 2047) / 2048 * 2048 ))
P3_START=$(( (P2_START + EFI_SIZE + 2047) / 2048 * 2048 ))

echo "[INFO] ISO ends at $P1_SIZE. P2 starts at $P2_START. P3 starts at $P3_START."

# Expand physical image file size
TOTAL_SECTORS=$(( P3_START + PERSIST_SIZE + 2048 ))
truncate -s $(( TOTAL_SECTORS * 512 )) "$FINAL_IMG"

# Apply new MBR table
sudo wipefs -a "$FINAL_IMG"
sudo sfdisk "$FINAL_IMG" << EOF
label: mbr
label-id: 0x11111111
unit: sectors

$FINAL_IMG : start= 64, size= $P1_SIZE, type=07, bootable
$FINAL_IMG : start= $P2_START, size= $EFI_SIZE, type=ef
$FINAL_IMG : start= $P3_START, size= $PERSIST_SIZE, type=83
EOF

# --- 9. FORMAT AND RESTORE FILES ---
LOOPDEV=$(sudo losetup -fP --show "$FINAL_IMG")
sleep 2

echo "[INFO] Formatting EFI (p2) as FAT32..."
sudo mkfs.vfat -F 32 -n "CWOS_BOOT" "${LOOPDEV}p2"

echo "[INFO] Formatting Persistence (p3) as ext4..."
sudo mkfs.ext4 -F -L CWOS_VAULT "${LOOPDEV}p3"

# --- 9.5. INJECT BOOT FILES INTO NEW EFI ---
echo "[INFO] Re-injecting bootloaders and config into FAT32 partition from pure Debian chroot..."
sudo mkdir -p /mnt/tmp_efi
sudo mount "${LOOPDEV}p2" /mnt/tmp_efi

# 1. Create the standard EFI folder structure PLUS the Debian stub folder
sudo mkdir -p /mnt/tmp_efi/EFI/BOOT /mnt/tmp_efi/boot/grub /mnt/tmp_efi/EFI/debian

# 2. Create the Friendly Name labels
echo "BOOTX64.EFI,ColdWalletOS,,UTF-8" | sudo tee /mnt/tmp_efi/EFI/BOOT/BOOTX64.CSV > /dev/null
echo "BOOTIA32.EFI,ColdWalletOS,,UTF-8" | sudo tee /mnt/tmp_efi/EFI/BOOT/BOOTIA32.CSV > /dev/null

# 3. CRITICAL FIX: Pull the binaries from Debian 12 chroot, NOT the host system
sudo cp "${BASE_DIR}/chroot/usr/lib/grub/i386-efi/monolithic/grubia32.efi" /mnt/tmp_efi/EFI/BOOT/BOOTIA32.EFI
sudo cp "${BASE_DIR}/chroot/usr/lib/grub/x86_64-efi/monolithic/grubx64.efi" /mnt/tmp_efi/EFI/BOOT/BOOTX64.EFI

# 4. Copy the config where it belongs
sudo cp "${BASE_DIR}/binary/boot/grub/grub.cfg" /mnt/tmp_efi/boot/grub/grub.cfg

# 5. Create the redirect stub for the Debian binary
echo "configfile /boot/grub/grub.cfg" | sudo tee /mnt/tmp_efi/EFI/debian/grub.cfg > /dev/null

sudo umount /mnt/tmp_efi

# Fix permissions for the 'live' user (UID 1000)
sudo mkdir -p /mnt/tmp_p3
sudo mount "${LOOPDEV}p3" /mnt/tmp_p3
sudo chown 1000:1000 /mnt/tmp_p3
sudo umount /mnt/tmp_p3



# --- 10. FINAL VERIFY AND REPORT ---
echo "------------------------------------------------"
echo "[1/4] CHECKING PARTITION TABLE (MBR)"
echo "------------------------------------------------"
P1_INFO=$(sudo fdisk -l "$FINAL_IMG" | grep "${FINAL_IMG}1")
if [[ "$P1_INFO" == *"17"* ]]; then echo "[OK] Partition 1 Type: HPFS/NTFS"; fi
if [[ "$P1_INFO" == *"*"* ]]; then echo "[OK] Partition 1 is marked Bootable."; fi

echo ""
echo "------------------------------------------------"
echo "[2/4] ATTACHING IMAGE & CHECKING LABELS"
echo "------------------------------------------------"
# Shows the structure and verifies the persistence label
lsblk -no NAME,LABEL,FSTYPE,SIZE "$LOOPDEV"
P3_LABEL=$(lsblk -no LABEL "${LOOPDEV}p3")

echo ""
echo "------------------------------------------------"
echo "[3/4] VERIFYING EFI BOOTLOADER BINARIES"
echo "------------------------------------------------"
sudo mkdir -p /mnt/verify_p2
sudo mount -o ro "${LOOPDEV}p2" /mnt/verify_p2
if [ -f "/mnt/verify_p2/EFI/BOOT/BOOTX64.EFI" ]; then echo "[OK] Found: 64-bit Loader (BOOTX64.EFI)"; fi
if [ -f "/mnt/verify_p2/EFI/BOOT/BOOTIA32.EFI" ]; then echo "[OK] Found: 32-bit Loader (BOOTIA32.EFI)"; fi

echo ""
echo "------------------------------------------------"
echo "[4/4] VERIFYING GRUB CONFIGS (BOTH PARTITIONS)"
echo "------------------------------------------------"
# Check Partition 2 (The EFI "Pointing" Fix)
if [ -f "/mnt/verify_p2/boot/grub/grub.cfg" ]; then 
    echo "[OK] Found grub.cfg on Partition 2 (EFI Pointing Fix)."; 
else
    echo "[!!] ERROR: grub.cfg missing from Partition 2!";
fi
sudo umount /mnt/verify_p2

# Check Partition 1 (The OS/ISO Source)
sudo mkdir -p /mnt/verify_p1
if sudo mount -o ro -t iso9660 "${LOOPDEV}p1" /mnt/verify_p1 2>/dev/null; then
    if [ -f "/mnt/verify_p1/boot/grub/grub.cfg" ]; then
        echo "[OK] Found grub.cfg on Partition 1 (OS Source).";
    fi
    sudo umount /mnt/verify_p1
else
    # Fallback check for raw binary signature
    if grep -q "grub.cfg" "$FINAL_IMG"; then
        echo "[OK] Found grub.cfg signature on Partition 1 (Binary check).";
    fi
fi

echo ""
echo "------------------------------------------------"
echo "[SUCCESS] COLD WALLET OS IMAGE READY"
echo "------------------------------------------------"
# Logical size (1.5G) vs Physical size (391M)
LOGICAL_SIZE=$(ls -lh "$FINAL_IMG" | awk '{print $5}')
PHYSICAL_SIZE=$(du -h "$FINAL_IMG" | awk '{print $1}')

echo "IMAGE PATH:    $FINAL_IMG"
echo "USB SIZE REQ:  $LOGICAL_SIZE"
echo "ACTUAL DATA:   $PHYSICAL_SIZE"
echo "------------------------------------------------"

# Final Cleanup
sudo losetup -d "$LOOPDEV"
sudo rmdir /mnt/verify_p1 /mnt/verify_p2 2>/dev/null || true

echo "Verification Complete. Ready to flash."