#!/bin/bash

echo "=== ColdWalletOS CLI Tool Check ==="

check() {
    NAME="$1"
    CMD="$2"

    echo -n "[*] $NAME: "

    if command -v $CMD >/dev/null 2>&1; then
        # Try --version and take only the first line
        VER=$($CMD --version 2>/dev/null | head -n 1)

        # If empty, try "version"
        if [ -z "$VER" ]; then
            VER=$($CMD version 2>/dev/null | head -n 1)
        fi

        # Fallback
        if [ -z "$VER" ]; then
            VER="OK"
        fi

        echo "OK - $VER"
    else
        echo "NOT FOUND"
    fi
}

check "Bitcoin Core"      "bitcoin-cli"
check "Litecoin"          "litecoin-cli"
check "Dogecoin"          "dogecoin-cli"
check "Monero CLI"        "monero-wallet-cli"
check "Avalanche CLI"     "avalanche"
check "Electrum CLI"      "electrum"

echo -n "[*] Ethers CLI: "
if command -v ethers >/dev/null 2>&1; then
    ETHERS_PKG="/usr/local/lib/ethers/node_modules/@ethersproject/cli/package.json"

    if [ -f "$ETHERS_PKG" ]; then
        ETHERS_VER=$(grep '"version"' "$ETHERS_PKG" | head -n 1 | cut -d '"' -f 4)
        echo "OK - ethers $ETHERS_VER"
    else
        echo "OK - version unknown"
    fi
else
    echo "NOT FOUND"
fi

echo "=== Done ==="
