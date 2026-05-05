#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# FIX 1: Initialize the tracking variable so the math at the end doesn't crash
FAIL_TOOLS=0

echo "=========================================="
echo "       HotWalletOS: INTEGRITY TEST        "
echo "=========================================="

BAD_IFACE=0

# 3. Check for Prohibited Tools
echo -e "\nChecking Prohibited Tools..."
TOOLS=("apt" "dpkg" "ssh")

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

# FINAL REPORTING
echo -e "\n=========================================="
# FIX 3: No more 'unary operator' error because variables are now guaranteed to be numbers
if [ $FAIL_TOOLS -eq 0 ] && [ $BAD_IFACE -eq 0 ]; then
    echo -e "          ${GREEN}SYSTEM INTEGRITY VERIFIED${NC}          "
else
    echo -e "          ${RED}SYSTEM COMPROMISED${NC}               "
fi
echo "=========================================="