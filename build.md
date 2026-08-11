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

# Get updated monero binary (optional)
bash $HOME/MonerOS/get_cli_software.sh

# Compile HotWalletOS
bash $HOME/MonerOS/build-HotWalletOS.sh
# Compiled file will be at: $HOME/MonerOS_Output/HotWalletOS.img

# Compile ColdWalletOS
bash $HOME/MonerOS/build-ColdWalletOS.sh
# Compiled file will be at: $HOME/MonerOS_Output/ColdWalletOS.img

# Compile UpdateOS (optional)
bash $HOME/MonerOS/build-UpdateOS.sh
# Compiled file will be at: $HOME/MonerOS_Output/UpdateOS.img