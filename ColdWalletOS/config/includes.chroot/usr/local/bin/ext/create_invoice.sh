#!/usr/bin/env python3
import getpass
import json
import os
import subprocess
import sys
import time

currency = "Bitcoin (BTC)"
address = ""
amount = ""
password = ""

gui_available = True
try:
    import tkinter as tk
    from tkinter import messagebox, ttk
    root = tk.Tk()
    root.destroy()
except Exception:
    gui_available = False

if gui_available:
    import tkinter as tk
    from tkinter import messagebox, ttk

    class InvoiceApp:
        def __init__(self):
            self.root = tk.Tk()
            self.root.title("Create Crypto Invoice")
            self.root.geometry("520x320")
            self.root.resizable(False, False)
            
            self.currency_var = tk.StringVar(value="Bitcoin (BTC)")

            tk.Label(self.root, text="Payment Type:").place(x=20, y=20, width=160, height=20)
            self.cmb = ttk.Combobox(self.root, textvariable=self.currency_var, values=["Bitcoin (BTC)", "Monero (XMR)"], state="readonly")
            self.cmb.place(x=190, y=20, width=290, height=25)

            tk.Label(self.root, text="Pay to Address:").place(x=20, y=70, width=160, height=20)
            self.txt_addr = tk.Entry(self.root)
            self.txt_addr.place(x=190, y=70, width=290, height=25)

            tk.Label(self.root, text="Payment Amount (BTC/XMR):").place(x=20, y=120, width=160, height=20)
            self.txt_amt = tk.Entry(self.root)
            self.txt_amt.place(x=190, y=120, width=290, height=25)

            tk.Label(self.root, text="Password:").place(x=20, y=170, width=160, height=20)
            self.txt_pwd = tk.Entry(self.root, show="*")
            self.txt_pwd.place(x=190, y=170, width=290, height=25)

            self.btn = tk.Button(self.root, text="Generate Secure Invoice", command=self.submit)
            self.btn.place(x=190, y=220, width=290, height=35)

            self.root.bind("<Return>", lambda event: self.submit())
            self.result = None
            self.root.mainloop()

        def submit(self):
            a = self.txt_addr.get().strip()
            am = self.txt_amt.get().strip()
            p = self.txt_pwd.get()
            if not a or not am or not p:
                messagebox.showerror("Validation Error", "Please fill in all fields including the password.")
                return
            self.result = {
                "currency": self.currency_var.get(),
                "address": a,
                "amount": am,
                "password": p
            }
            self.root.destroy()

    app = InvoiceApp()
    if not app.result:
        sys.exit(0)
    currency = app.result["currency"]
    address = app.result["address"]
    amount = app.result["amount"]
    password = app.result["password"]
else:
    print("=== Create Crypto Invoice (Terminal Mode) ===")
    print("1. Bitcoin (BTC)")
    print("2. Monero (XMR)")
    choice = input("Select currency [1/2] (default 1): ").strip()
    if choice == "2":
        currency = "Monero (XMR)"
    
    address = input("Enter wallet address: ").strip()
    amount = input("Enter amount: ").strip()
    password = getpass.getpass("Enter encryption password: ")

    if not address or not amount or not password:
        print("Error: All fields are required.")
        sys.exit(1)

timestamp = int(time.time())
invoice_dir = os.path.join(os.getcwd(), "invoices")
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
    cmd = ["openssl", "enc", "-aes-256-cbc", "-salt", "-in", json_path, "-out", enc_path, "-pass", f"pass:{password}"]
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
    os.remove(json_path)
    msg = f"Encrypted invoice created successfully at:\n{enc_path}"
    if gui_available:
        messagebox.showinfo("Success", msg)
    else:
        print(msg)
except Exception as e:
    if os.path.exists(json_path):
        os.remove(json_path)
    err_msg = f"Encryption failed: {e}"
    if gui_available:
        messagebox.showerror("Error", err_msg)
    else:
        print(err_msg)
    sys.exit(1)