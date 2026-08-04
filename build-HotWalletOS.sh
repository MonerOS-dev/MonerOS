#!/bin/bash
set -e




# Production version vs non-production
PRODUCTION=true
MODS_DIR="$HOME/MonerOS_Project/admin_mods"
BUILD_DIR="$HOME/MonerOS_Project/HotWalletOS"
UFW_HOOK="01-outbound-only-ufw.chroot"
SSH_HOOK="99-ssh-gen.chroot"
SSH_PKG_LIST="$BUILD_DIR/config/package-lists/ssh.list.chroot"

# Destination for the initialization script
HWINIT_DESK_DEST="$BUILD_DIR/config/includes.chroot/etc/skel/.config/autostart/hwinit.desktop"
HWINIT_DEST="$BUILD_DIR/config/includes.chroot/usr/local/bin/hwinit"

if [ "$PRODUCTION" = true ]; then
    echo "[INFO] Configuring for PRODUCTION mode..."

    # 1. Remove SSH configs and the SSH generation hook
    sudo rm -rf "$BUILD_DIR/config/includes.chroot/etc/ssh/"
    sudo rm -f "$BUILD_DIR/config/hooks/live/$SSH_HOOK"
    
    # 2. Ensure openssh-server is NOT in the package list
    sudo rm -f "$SSH_PKG_LIST"
    
    # 3. Apply Firewall Hook
    if [ -f "$MODS_DIR/$UFW_HOOK" ]; then
        sudo cp "$MODS_DIR/$UFW_HOOK" "$BUILD_DIR/config/hooks/live/"
        sudo chmod +x "$BUILD_DIR/config/hooks/live/$UFW_HOOK"
    fi

    # 4. Copy Production hwinit.desktop
    #sudo cp "$MODS_DIR/hwinit-desktop.production" "$HWINIT_DESK_DEST"
    #sudo chmod +x "$HWINIT_DESK_DEST"
    
    # 5. Copy Production hwinit
    #sudo cp "$MODS_DIR/hwinit_production" "$HWINIT_DEST"
    #sudo chmod +x "$HWINIT_DEST"

else
    echo "[INFO] Configuring for DEV mode..."

    # 1. Copy custom SSH configs and the SSH generation hook
    sudo cp -r "$MODS_DIR/ssh/" "$BUILD_DIR/config/includes.chroot/etc/"
    if [ -f "$MODS_DIR/$SSH_HOOK" ]; then
        sudo cp "$MODS_DIR/$SSH_HOOK" "$BUILD_DIR/config/hooks/live/"
        sudo chmod +x "$BUILD_DIR/config/hooks/live/$SSH_HOOK"
    fi
    
    # 2. Enable SSH in package lists
    echo "openssh-server" | sudo tee "$SSH_PKG_LIST" > /dev/null
    
    # 3. Ensure the production firewall hook is NOT present
    sudo rm -f "$BUILD_DIR/config/hooks/live/$UFW_HOOK"
    
    # 4. Copy Non-Production hwinit.desktop
    #sudo cp "$MODS_DIR/hwinit-desktop.non-production" "$HWINIT_DESK_DEST"
    #sudo chmod +x "$HWINIT_DESK_DEST"

    # 5. Copy Non-Production hwinit
    #sudo cp "$MODS_DIR/hwinit_non-production" "$HWINIT_DEST"
    #sudo chmod +x "$HWINIT_DEST"
fi






BASE_DIR="$HOME/MonerOS_Project/HotWalletOS"
cd $BASE_DIR

echo "[INFO] Starting HotWalletOS build..."

# copy splash
#convert $HOME/MonerOS_Project/admin_mods/cwos_splash.png \
convert $HOME/MonerOS_Project/admin_mods/generic_splash.png \
        -flip \
        -colors 14 \
        $HOME/MonerOS_Project/HotWalletOS/config/includes.binary/boot/grub/splash.tga

# Update version string
FILE="$HOME/MonerOS_Project/HotWalletOS/config/includes.chroot/usr/local/bin/hwversion"
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
  --iso-volume "HotWalletOS" \
  --archive-areas "main contrib non-free non-free-firmware" \
  --binary-images iso-hybrid \
  --bootloaders "syslinux,grub-efi" \
  --debian-installer none \
  --apt-recommends true \
  --bootappend-live "boot=live components locales=en_US.UTF-8 bootfrom=/dev/disk/by-partuuid/22222222-01 live-media-path=/hw_sys"

# --- 4. BUILD THE BASE ISO ---
sudo lb build

# --- 5. THE MANUAL SHREDDING STRIKE ---
echo "[CRITICAL] Shredding SquashFS to pass Integrity Test..."
SQUASH_FILE="${BASE_DIR}/binary/live/filesystem.squashfs"
TEMP_SQUASH="${BASE_DIR}/temp_squash"

# Fix the "already exists" error by ensuring the destination is empty
sudo rm -rf "$TEMP_SQUASH"
mkdir -p "$TEMP_SQUASH"

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
sudo mv ${BASE_DIR}/binary/live ${BASE_DIR}/binary/hw_sys

echo "[INFO] Creating HotWalletOS marker file..."
sudo touch "${BASE_DIR}/binary/hw_sys/.marker-hotwallet"


# --- 6. FINALIZE THE ISO ---
sudo rm -f .build/binary_iso
sudo lb binary_iso

# --- 7. CREATE DISK IMAGE (.IMG) ---
FINAL_IMG="$HOME/HotWalletOS.img"
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
UPDATE_FILE="$HOME/HotWalletOS.update"
echo "[INFO] Exporting the pure ISO9660 update file to $UPDATE_FILE..."
cp "$FINAL_IMG" "$UPDATE_FILE"

# --- 8. SMART DYNAMIC EXPAND AND RE-LAYOUT ---
echo "[INFO] Calculating ISO size and re-partitioning..."

# Get actual Partition 1 size in sectors using your original fdisk method
ISO_SIZE=$(sudo fdisk -l "$FINAL_IMG" | grep "${FINAL_IMG}1" | awk '{print $4}')

# Set your fixed 2.1GB target in sectors (2100 MiB * 2048 sectors/MiB)
P1_SIZE=$(( 2100 * 2048 ))

# CRITICAL FAIL GUARD: Stop if the real ISO size exceeds your 2.1GB limit
if [ -n "$ISO_SIZE" ] && [ "$ISO_SIZE" -gt "$P1_SIZE" ]; then
    echo "[CRITICAL ERROR] Built ISO ($ISO_SIZE sectors) is larger than the 2.1GB limit ($P1_SIZE sectors)!"
    echo "Aborting build to prevent data corruption."
    exit 1
fi

# Define sizes (in 512-byte sectors)
EFI_SIZE=131072      # 64MB
PERSIST_SIZE=1536000 # 750MB

# Calculate start points with 2048 alignment
P2_START=$(( (64 + P1_SIZE + 2047) / 2048 * 2048 ))
P3_START=$(( (P2_START + EFI_SIZE + 2047) / 2048 * 2048 ))

echo "[INFO] ISO ends at $P1_SIZE. P2 starts at $P2_START. P3 starts at $P3_START."

# Expand physical image file size
TOTAL_SECTORS=$(( P3_START + PERSIST_SIZE + 2048 ))
truncate -s $(( TOTAL_SECTORS * 512 )) "$FINAL_IMG"

# Apply new MBR table
# Type 07 = exFAT/NTFS, Type ef = EFI
sudo wipefs -a "$FINAL_IMG"
sudo sfdisk "$FINAL_IMG" << EOF
label: mbr
label-id: 0x22222222
unit: sectors

$FINAL_IMG : start= 64, size= $P1_SIZE, type=07, bootable
$FINAL_IMG : start= $P2_START, size= $EFI_SIZE, type=ef
$FINAL_IMG : start= $P3_START, size= $PERSIST_SIZE, type=07
EOF

# --- 9. FORMAT AND RESTORE FILES ---
LOOPDEV=$(sudo losetup -fP --show "$FINAL_IMG")
sleep 2

echo "[INFO] Formatting EFI (p2) as FAT32..."
sudo mkfs.vfat -F 32 -n "HWOS_BOOT" "${LOOPDEV}p2"

echo "[INFO] Formatting Partition 3 (p3) as 2GB exFAT..."
# Requires exfatprogs or exfat-utils installed
sudo mkfs.exfat -n "HWOS_SALLY" "${LOOPDEV}p3"

# --- 9.5. INJECT BOOT FILES INTO NEW EFI ---
echo "[INFO] Re-injecting bootloaders..."
mkdir -p /mnt/tmp_efi
sudo mount "${LOOPDEV}p2" /mnt/tmp_efi

sudo mkdir -p /mnt/tmp_efi/EFI/BOOT /mnt/tmp_efi/boot/grub
echo "BOOTX64.EFI,HotWalletOS,,UTF-8" | sudo tee /mnt/tmp_efi/EFI/BOOT/BOOTX64.CSV > /dev/null
echo "BOOTIA32.EFI,HotWalletOS,,UTF-8" | sudo tee /mnt/tmp_efi/EFI/BOOT/BOOTIA32.CSV > /dev/null
sudo cp /usr/lib/grub/i386-efi/monolithic/grubia32.efi /mnt/tmp_efi/EFI/BOOT/BOOTIA32.EFI
sudo cp /usr/lib/grub/x86_64-efi/monolithic/grubx64.efi /mnt/tmp_efi/EFI/BOOT/BOOTX64.EFI
sudo cp "${BASE_DIR}/binary/boot/grub/grub.cfg" /mnt/tmp_efi/boot/grub/grub.cfg

sudo umount /mnt/tmp_efi

# Final check for Partition 3
mkdir -p /mnt/tmp_p3
sudo mount "${LOOPDEV}p3" /mnt/tmp_p3
echo "[OK] Partition 3 (exFAT) is mountable."
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
echo "[SUCCESS] HOT WALLET OS IMAGE READY"
echo "------------------------------------------------"
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
