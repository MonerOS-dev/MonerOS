#!/usr/bin/env python3
import getpass
import json
import os
import subprocess
import sys
import time

print("=== Create Crypto Invoice (Terminal Mode) ===")
print("1. Bitcoin (BTC)")
print("2. Monero (XMR)")
choice = input("Select currency [1/2] (default 1): ").strip()

currency = "Monero (XMR)" if choice == "2" else "Bitcoin (BTC)"

address = input("Pay To address: ").strip()

ticker = "XMR" if choice == "2" else "BTC"
amount = input(f"Payment Amount ({ticker}): ").strip()

password = getpass.getpass("Master Password: ")

if not address or not amount or not password:
    print("Error: All fields are required.")
    sys.exit(1)

timestamp = int(time.time())
invoice_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "invoices")
os.makedirs(invoice_dir, exist_ok=True)

json_path = os.path.join(invoice_dir, f"{timestamp}.json")
data = {
    "Currency": currency,
    "Address": address,
    "Amount": amount,
    "Created": time.strftime("%Y-%m-%d %H:%M:%S", time.gmtime(timestamp))
}

with open(json_path, "w") as f:
    json.dump(data, f, indent=4)

enc_path = os.path.join(invoice_dir, f"{timestamp}.enc")

try:
    cmd = [
        "openssl", "enc", "-aes-256-cbc", "-salt", 
        "-in", json_path, "-out", enc_path, 
        "-pass", f"pass:{password}"
    ]
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
    os.remove(json_path)
    print(f"\n[+] Encrypted invoice created successfully at:\n{enc_path}")
except Exception as e:
    if os.path.exists(json_path):
        os.remove(json_path)
    print(f"\n[-] Encryption failed: {e}", file=sys.stderr)
    sys.exit(1)