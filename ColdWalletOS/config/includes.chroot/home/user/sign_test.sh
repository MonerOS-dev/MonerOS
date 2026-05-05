#!/bin/bash

# --- Configuration ---
WALLET="/mnt/vault/monero/48Bt33chDG7Kv5uxihd7gWXoKgzKsmLCJ1cpUNtmjqDGHkTAbzX3vwQRNXWmka39PCfjiW5vyJZCPWrmCmFewXzyD3AyNGk/wallet"
PASSWORD="Falcon19**"
OUTDIR="/mnt/sallyport/watch_monero/48Bt33chDG7Kv5uxihd7gWXoKgzKsmLCJ1cpUNtmjqDGHkTAbzX3vwQRNXWmka39PCfjiW5vyJZCPWrmCmFewXzyD3AyNGk"

# File paths
OUTPUTS_IN="$OUTDIR/outputs.bin"
UNSIGNED_TX="$OUTDIR/unsigned_tx_1750950343"
SIGNED_TX_FINAL="$OUTDIR/signed_tx_1750950343"
KEY_IMAGES_OUT="$OUTDIR/key_images.bin"

# --- Expect Script ---
expect <<EOF
# Set a generous timeout for file I/O
set timeout 60
spawn monero-wallet-cli --wallet-file "$WALLET" --offline

# 1. Open Wallet
expect "Wallet password:"
send "$PASSWORD\r"

# 2. Import Outputs
expect -re ".*]:"
send "import_outputs $OUTPUTS_IN\r"
expect "Wallet password:"
send "$PASSWORD\r"

# 3. Sign Transfer
expect -re ".*]:"
send "sign_transfer $UNSIGNED_TX\r"
expect "Wallet password:"
send "$PASSWORD\r"

# Match the long confirmation string - just looking for "Is this okay?" 
expect "Is this okay?*"
send "y\r"

# 4. Export Key Images
expect -re ".*]:"
send "export_key_images $KEY_IMAGES_OUT\r"
expect "Wallet password:"
send "$PASSWORD\r"

# 5. Exit
expect -re ".*]:"
send "exit\r"
expect eof
EOF

# --- Post-Processing ---
# Monero defaults to saving in the current working directory
if [ -f "signed_monero_tx" ] && [ -f "$KEY_IMAGES_OUT" ]; then
    mv "signed_monero_tx" "$SIGNED_TX_FINAL"
    echo "------------------------------------------"
    echo "SUCCESS!"
    echo "Signed TX: $SIGNED_TX_FINAL"
    echo "Key Images: $KEY_IMAGES_OUT"
    echo "------------------------------------------"
else
    echo "ERROR: One or more files were NOT created."
    [ ! -f "signed_monero_tx" ] && echo "Missing: signed_monero_tx"
    [ ! -f "$KEY_IMAGES_OUT" ] && echo "Missing: $KEY_IMAGES_OUT"
    exit 1
fi