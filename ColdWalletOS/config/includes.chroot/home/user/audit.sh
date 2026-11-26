#!/usr/bin/env bash
set -u

PASS=0
FAIL=0
WARN=0

pass() { echo "[PASS] $1"; PASS=$((PASS + 1)); }
fail() { echo "[FAIL] $1"; FAIL=$((FAIL + 1)); }
warn() { echo "[WARN] $1"; WARN=$((WARN + 1)); }

echo "========================================================"
echo " ColdWalletOS Air-Gap & Build Hardening Audit"
echo "========================================================"

# 1. Check active network interfaces (only 'lo' should exist)
echo ""
echo "--- [1] Network Interfaces ---"
NON_LO_IFACES=$(ip -o link show | awk -F': ' '{print $2}' | grep -v '^lo$' || true)
if [ -z "$NON_LO_IFACES" ]; then
    pass "Only loopback (lo) interface exists."
else
    fail "Non-loopback interfaces detected: $NON_LO_IFACES"
fi

# 2. Check loaded kernel modules for networking, Wi-Fi, Bluetooth, NFC, or USB tethering
echo ""
echo "--- [2] Loaded Kernel Modules ---"
BAD_MODS=$(lsmod | awk 'NR>1 {print $1}' | grep -iE '^(wifi|wlan|iwl|ath|rtw|rtl|brcm|mt76|cfg80211|mac80211|bluetooth|btusb|bnep|rfcomm|nfc|e1000|r8169|igb|ixgbe|tg3|rndis_host|cdc_ether|usbnet)' || true)
if [ -z "$BAD_MODS" ]; then
    pass "Zero wireless, Bluetooth, Ethernet, or USB-net modules loaded."
else
    fail "Active network/radio modules loaded: $(echo "$BAD_MODS" | tr '\n' ' ')"
fi

# 3. Check on-disk kernel module tree (/lib/modules)
echo ""
echo "--- [3] On-Disk Kernel Modules (/lib/modules) ---"
DISK_NET_MODS=$(find /lib/modules -type f \( -path '*/drivers/net/*' -o -path '*/drivers/bluetooth/*' -o -path '*/net/wireless/*' -o -path '*/net/mac80211/*' -o -path '*/net/bluetooth/*' \) 2>/dev/null || true)
if [ -z "$DISK_NET_MODS" ]; then
    pass "No network/wireless/Bluetooth .ko files found in /lib/modules."
else
    COUNT=$(echo "$DISK_NET_MODS" | wc -l)
    fail "Found $COUNT module files matching network/wireless/Bluetooth paths in /lib/modules."
    echo "$DISK_NET_MODS"
fi

# 4. Check initrd.img for leftover network drivers (if live media is accessible)
echo ""
echo "--- [4] Initial RAM Disk (initrd) ---"
INITRD_PATH=$(find /run/live/medium /lib/live/mount/medium /live/medium -maxdepth 3 -name 'initrd*' 2>/dev/null | head -n 1 || true)
if [ -n "$INITRD_PATH" ] && command -v lsinitramfs >/dev/null 2>&1; then
    INITRD_NET=$(lsinitramfs "$INITRD_PATH" 2>/dev/null | grep -iE 'drivers/net/|drivers/bluetooth/|net/wireless/|net/mac80211/|net/bluetooth/' || true)
    if [ -z "$INITRD_NET" ]; then
        pass "No network/wireless/Bluetooth drivers packed inside $(basename "$INITRD_PATH")."
    else
        COUNT=$(echo "$INITRD_NET" | wc -l)
        fail "Found $COUNT network/wireless drivers inside $(basename "$INITRD_PATH")."
    fi
else
    warn "Could not inspect initrd (either path not mounted or lsinitramfs not installed)."
fi

# 5. Check wireless/Bluetooth firmware blobs
echo ""
echo "--- [5] Wireless & Bluetooth Firmware ---"
FW_BLOBS=$(find /lib/firmware -maxdepth 2 \( -iname '*iwlwifi*' -o -iname '*ath*' -o -iname '*rtlwifi*' -o -iname '*rtw88*' -o -iname '*rtw89*' -o -iname '*brcm*' -o -iname '*ibt*' \) 2>/dev/null || true)
if [ -z "$FW_BLOBS" ]; then
    pass "No Wi-Fi or Bluetooth firmware blobs present in /lib/firmware."
else
    fail "Wireless/Bluetooth firmware blobs remain in /lib/firmware."
fi

# 6. Check network services & open sockets
echo ""
echo "--- [6] Network Daemons & Listening Sockets ---"
ACTIVE_DAEMONS=""
for svc in networking NetworkManager wpa_supplicant bluetooth avahi-daemon ModemManager systemd-networkd systemd-resolved ssh sshd; do
    if systemctl is-active --quiet "$svc" 2>/dev/null; then
        ACTIVE_DAEMONS="$ACTIVE_DAEMONS $svc"
    fi
done
if [ -z "$ACTIVE_DAEMONS" ]; then
    pass "All network/radio systemd services are inactive, masked, or removed."
else
    fail "Active network services found:$ACTIVE_DAEMONS"
fi

OPEN_SOCKETS=$(ss -tulnp 2>/dev/null | tail -n +2 || true)
if [ -z "$OPEN_SOCKETS" ]; then
    pass "Zero listening TCP/UDP sockets open."
else
    fail "Listening sockets detected: $OPEN_SOCKETS"
fi

# 7. Check stripped package managers & transfer tools (curl excluded: used locally for 127.0.0.1 wallet RPC)
echo ""
echo "--- [7] Package Managers & Transfer Tools ---"
SURVIVING_TOOLS=""
for bin in apt apt-get dpkg pip pip3 wget nc netcat nmcli bluetoothctl wpa_supplicant; do
    BIN_PATH=$(command -v "$bin" 2>/dev/null || true)
    if [ -n "$BIN_PATH" ] && [ -x "$BIN_PATH" ]; then
        SURVIVING_TOOLS="$SURVIVING_TOOLS $bin($BIN_PATH)"
    fi
done
if [ -z "$SURVIVING_TOOLS" ]; then
    pass "Package managers and extra transfer tools are stripped or non-executable."
else
    warn "Executable tools still present:$SURVIVING_TOOLS"
fi

echo ""
echo "========================================================"
echo " SUMMARY:  PASS: $PASS   |   FAIL: $FAIL   |   WARN: $WARN"
echo "========================================================"

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
exit 0