# Install Dependencies
sudo apt update && sudo apt install -y \
    git \
    live-build \
    debootstrap \
    xorriso \
    grub-efi-ia32-bin \
    grub-efi-amd64-bin \
    grub-pc-bin \
    mtools \
    dosfstools \
    exfatprogs \
    squashfs-tools \
    imagemagick \
    isolinux \
    syslinux \
    syslinux-common
    
# Clone Repository
git clone https://github.com/MonerOS-dev/MonerOS.git