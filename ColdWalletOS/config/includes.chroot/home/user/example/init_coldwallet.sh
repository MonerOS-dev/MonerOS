#!/bin/bash

FOUND=0
CONTAINER_NAME="salleyport.vc"

# Scan only real partitions
PARTITIONS=$(lsblk -lnpo NAME,TYPE | awk '$2=="part"{print $1}')

echo "Scanning for VeraCrypt container file ($CONTAINER_NAME)..."
for part in $PARTITIONS; do
    MOUNTPOINT=$(mktemp -d)

    # Mount read-only or read-write (rw is fine)
    sudo mount "$part" "$MOUNTPOINT" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        if [ -f "$MOUNTPOINT/$CONTAINER_NAME" ]; then
            echo "Found VeraCrypt container on $part"

            echo -n "Enter password to unlock $CONTAINER_NAME: "
            read -s PASSWORD
            echo

            TARGET_FILE="$MOUNTPOINT/$CONTAINER_NAME"
            FINAL_MOUNT="/mnt/sallyport"
            sudo mkdir -p "$FINAL_MOUNT"

            veracrypt --text --non-interactive \
                --mount "$TARGET_FILE" \
                --password="$PASSWORD" \
                --pim=0 \
                --keyfiles="" \
                --protect-hidden=no \
                "$FINAL_MOUNT"

            if [ $? -eq 0 ]; then
                echo "Mounted encrypted volume at $FINAL_MOUNT"
                echo "Parent partition remains mounted at $MOUNTPOINT"
                exit 0
            else
                echo "Failed to mount VeraCrypt container."
                exit 1
            fi
        fi

        # If container not found, unmount the temp mount
        sudo umount "$MOUNTPOINT"
    fi

    rmdir "$MOUNTPOINT"
done

echo "No VeraCrypt container found."
echo

# List available disks (not partitions)
echo "Available disks:"
DISKS=$(lsblk -dnpo NAME,TYPE | awk '$2=="disk"{print $1}')
echo "$DISKS"
echo

# Ask user if they want to format/encrypt
read -p "Do you want to format and encrypt one of these disks with VeraCrypt? (y/N): " ANSWER

case "$ANSWER" in
    y|Y)
        read -p "Enter the disk to format (e.g., /dev/sda): " TARGET
        echo "You selected: $TARGET"

        echo "WARNING: This will ERASE ALL DATA on $TARGET"
        read -p "Type YES to continue: " REALLY

        if [ "$REALLY" != "YES" ]; then
            echo "Aborted."
            exit 1
        fi

        # Ask for password securely
        echo -n "Enter a password for the VeraCrypt volume: "
        read -s PASSWORD
        echo
        echo -n "Confirm password: "
        read -s PASSWORD2
        echo

        if [ "$PASSWORD" != "$PASSWORD2" ]; then
            echo "Passwords do not match."
            exit 1
        fi

        echo "Creating partition table..."
        sudo parted -s "$TARGET" mklabel gpt
        sudo parted -s "$TARGET" mkpart primary fat32 0% 100%

        PART="${TARGET}1"

        echo "Formatting $PART as FAT32..."
        sudo mkfs.vfat "$PART"

        echo "Mounting $PART..."
        MOUNTPOINT="/mnt/vc_disk"
        sudo mkdir -p "$MOUNTPOINT"
        sudo mount "$PART" "$MOUNTPOINT"

        echo "Creating VeraCrypt container file ($CONTAINER_NAME)..."
        veracrypt --text --non-interactive \
            --create "$MOUNTPOINT/$CONTAINER_NAME" \
            --password="$PASSWORD" \
            --pim=0 \
            --keyfiles="" \
            --filesystem=FAT \
            --volume-type=normal \
            --encryption=AES \
            --hash=SHA-512 \
            --size=100M \
            --quick

        echo "Mounting encrypted container..."
        FINAL_MOUNT="/mnt/sallyport"
        sudo mkdir -p "$FINAL_MOUNT"

        veracrypt --text --non-interactive \
            --mount "$MOUNTPOINT/$CONTAINER_NAME" \
            --password="$PASSWORD" \
            --pim=0 \
            --keyfiles="" \
            --protect-hidden=no \
            "$FINAL_MOUNT"

        echo "Encrypted volume mounted at $FINAL_MOUNT"
        echo "Parent partition remains mounted at $MOUNTPOINT"
        exit 0
        ;;

    *)
        echo "No action taken."
        exit 1
        ;;
esac
