#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# FIX 1: Initialize the tracking variable so the math at the end doesn't crash
FAIL_TOOLS=0

echo "=========================================="
echo "    UPDATEOS: AIR-GAP INTEGRITY TEST  "
echo "=========================================="

# 1. Check for Networking/Bluetooth Drivers
echo -e "\n[1/4] Checking Kernel Drivers..."
# Kernel check
NET_DRIVERS=$(find /lib/modules/$(uname -r)/kernel/drivers/net -type f 2>/dev/null | grep -v "loopback")
BT_DRIVERS=$(find /lib/modules/$(uname -r)/kernel/drivers/bluetooth -type f 2>/dev/null)

if [ -z "$NET_DRIVERS" ] && [ -z "$BT_DRIVERS" ]; then
    echo -e "${GREEN}PASS: No network/bluetooth drivers found.${NC}"
else
    echo -e "${RED}FAIL: Drivers still exist!${NC}"
    FAIL_TOOLS=$((FAIL_TOOLS + 1))
fi

# 2. Check for Hardware Firmware
echo -e "\n[2/4] Checking Hardware Firmware..."
if [ -z "$(ls -A /lib/firmware 2>/dev/null)" ]; then
    echo -e "${GREEN}PASS: /lib/firmware is empty.${NC}"
else
    echo -e "${RED}FAIL: Firmware blobs detected.${NC}"
    FAIL_TOOLS=$((FAIL_TOOLS + 1))
fi

# 3. Check for Prohibited Tools
echo -e "\n[3/4] Checking Prohibited Tools..."
TOOLS=("nmcli" "bluetoothctl" "wpa_supplicant" "apt" "dpkg" "ssh")

for tool in "${TOOLS[@]}"; do
    TOOL_PATH=$(command -v "$tool" 2>/dev/null)
    if [ -n "$TOOL_PATH" ]; then
        # Check size - if 0, it's neutralized
        T_SIZE=$(stat -c%s "$TOOL_PATH" 2>/dev/null || echo "0")
        
        # FIX 2: Check if neutralized OR if size is 0
        if "$tool" --version 2>&1 | grep -q "neutralized" || [ "$T_SIZE" -eq 0 ]; then
            echo -e "${GREEN}PASS: $tool is NEUTRALIZED (Size: ${T_SIZE}B).${NC}"
        else
            echo -e "${RED}FAIL: $tool is FUNCTIONAL! Size: $(du -h "$TOOL_PATH" | cut -f1)${NC}"
            FAIL_TOOLS=$((FAIL_TOOLS + 1))
        fi
    else
        echo -e "${GREEN}PASS: $tool not found.${NC}"
    fi
done

# 4. Check Network Interfaces
echo -e "\n[4/4] Checking Active Interfaces..."
INTERFACES=$(ls /sys/class/net)
BAD_IFACE=0
for iface in $INTERFACES; do
    if [ "$iface" != "lo" ]; then
        echo -e "${RED}WARNING: Interface $iface detected!${NC}"
        BAD_IFACE=$((BAD_IFACE + 1))
    fi
done

if [ $BAD_IFACE -eq 0 ]; then
    echo -e "${GREEN}PASS: Only Loopback interface exists.${NC}"
fi

# FINAL REPORTING
echo -e "\n=========================================="
# FIX 3: No more 'unary operator' error because variables are now guaranteed to be numbers
if [ $FAIL_TOOLS -eq 0 ] && [ $BAD_IFACE -eq 0 ]; then
    echo -e "          ${GREEN}SYSTEM INTEGRITY VERIFIED${NC}          "
else
    echo -e "          ${RED}SYSTEM COMPROMISED${NC}               "
fi
echo "=========================================="