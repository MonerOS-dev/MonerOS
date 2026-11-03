#!/usr/bin/env python3
import getpass
import hashlib
import json
import os
import subprocess
import sys


def parse_and_print_invoice(json_str):
  """Parses the JSON and formats fields with clean currency mapping."""
  try:
    data = json.loads(json_str)
    
    # Extract and normalize currency to BTC or XMR
    currency_raw = str(data.get("Currency", ""))
    if "BTC" in currency_raw.upper():
      currency = "BTC"
    elif "XMR" in currency_raw.upper():
      currency = "XMR"
    else:
      currency = currency_raw

    values = [
        currency,
        str(data.get("Address", "")),
        str(data.get("Amount", "")),
        str(data.get("Created", "")),
    ]
    sys.stdout.write(", ".join(values) + "\n")
  except json.JSONDecodeError:
    print("Error: Decrypted output is not valid JSON.")
    sys.exit(1)


def decrypt_file(file_path, password):
  if not os.path.exists(file_path):
    print(f"Error: File '{file_path}' not found.")
    sys.exit(1)

  with open(file_path, "rb") as f:
    header = f.read(8)

  # Check if it was encrypted using the Python/OpenSSL script (starts with "Salted__")
  if header == b"Salted__":
    cmd = [
        "openssl",
        "enc",
        "-d",
        "-aes-256-cbc",
        "-in",
        file_path,
        "-pass",
        f"pass:{password}",
    ]
    try:
      result = subprocess.run(
          cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, check=True
      )
      parse_and_print_invoice(result.stdout)
      return
    except subprocess.CalledProcessError:
      print("Decryption failed: Incorrect password or corrupt file.")
      sys.exit(1)

  # Otherwise, handle the Windows .NET batch file format (16-byte salt, 16-byte IV, PBKDF2-SHA256)
  with open(file_path, "rb") as f:
    salt = f.read(16)
    iv = f.read(16)
    ciphertext = f.read()

  if len(salt) != 16 or len(iv) != 16:
    print("Error: Invalid file format or corrupted header.")
    sys.exit(1)

  derived = hashlib.pbkdf2_hmac(
      "sha256", password.encode("utf-8"), salt, 10000, 48
  )
  key = derived[:32]
  iv_bytes = derived[32:]

  cmd = [
      "openssl",
      "enc",
      "-d",
      "-aes-256-cbc",
      "-K",
      key.hex(),
      "-iv",
      iv_bytes.hex(),
  ]
  try:
    process = subprocess.Popen(
        cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE
    )
    stdout, stderr = process.communicate(input=ciphertext)

    if process.returncode != 0:
      print("Decryption failed: Incorrect password or corrupt file.")
      sys.exit(1)

    parse_and_print_invoice(stdout.decode("utf-8"))

  except FileNotFoundError:
    print("Error: 'openssl' command not found on this system.")
    sys.exit(1)


if __name__ == "__main__":
  if len(sys.argv) < 2:
    print("Usage: python3 decrypt_invoice.py <path_to_enc_file> [password]")
    sys.exit(1)

  target_file = sys.argv[1]

  # Check if password was passed as a second argument
  if len(sys.argv) >= 3:
    pwd = sys.argv[2]
  else:
    pwd = getpass.getpass("Enter decryption password: ")

  decrypt_file(target_file, pwd)