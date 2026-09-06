# **MonerOS**
**The Open-Source, Dual-OS Ecosystem for Sovereign Asset Management**

**MonerOS** is a free, open-source suite of operating systems engineered to provide a professional-grade security bridge for your digital assets. By decoupling transaction preparation from private key signing, MonerOS eliminates the vulnerabilities inherent in traditional "always-online" environments.

The ecosystem consists of two specialized nodes: **HotWalletOS** and **ColdWalletOS**.

You don't need to be an expert to setup your own security and privacy focused wallet. MonerOS does this by default. You don't need to know how to remove network cards, etc. **ColdWalletOS** can't see them.

---

## Demonstration Video (3x speed)
> **Note:** The only way to capture this process is via a capture card, which significantly reduces screen resolution. Actual system clarity is much better.

There are three things happening in this video:

1. Creating an unsigned transaction with HotWalletOS and shutting the system down.
2. Booting ColdWalletOS, signing the unsigned transaction, and shutting the system down.
3. Booting HotWalletOS again and submitting the signed transaction.

![MonerOS Demo](https://raw.githubusercontent.com/MonerOS-dev/MonerOS/main/MonerOS_demo.gif)

---

## Installation, User and Update Manuals
* **[Read the Installation Manual](https://github.com/MonerOS-dev/MonerOS/blob/main/Installation_Manual.pdf)**
* **[Read the User Manual](https://github.com/MonerOS-dev/MonerOS/blob/main/User_Manual.pdf)**
* **[Read the Update Manual](https://github.com/MonerOS-dev/MonerOS/blob/main/Update_Manual.pdf)**

## **The Power of Two: How It Works**

The MonerOS architecture relies on physical isolation to protect your wealth. Instead of trusting a single device, you use two independent environments:

1.  **HotWalletOS (The Gateway):** A hardened, internet-connected environment used to watch the blockchain, prepare transactions, and broadcast signed data.
2.  **ColdWalletOS (The Vault):** A strictly offline, air-gapped environment where your private keys live. It is used exclusively to sign the transactions prepared by the Hot node.

> *"True security comes from physical isolation. MonerOS ensures that your private keys never touch a network, providing peace of mind that even the most sophisticated malware cannot reach your assets."*

---

## **Key Features**

* **Hardware Independence:** Stop relying on expensive, closed-source proprietary hardware. MonerOS transforms any standard **amd64** architecture PC into a dedicated cryptographic vault.
* **True Air-Gapped Security:** ColdWalletOS virtually eliminates digital attack vectors by completely disabling all networking capabilities and software installation.
* **Hardened Attack Surface:** Both operating systems are "locked down." Software installation is disabled by default, ensuring a "clean" environment dedicated solely to transaction management.
* **Transparent & Auditable:** Being 100% open-source, the community can verify every line of code, ensuring there are no backdoors in your financial fortress.

---

## **Security Comparison**

| Feature | **ColdWalletOS** | **HotWalletOS** |
| :--- | :--- | :--- |
| **Connectivity** | **Disabled** (Air-gapped) | Restricted / Secure |
| **Software Installation** | **Disabled** | **Disabled** |
| **Primary Use** | Secure offline signing | Transaction prep & broadcasting |
| **Attack Surface** | Virtually Zero | Minimized |

---

## **Important: Beta Phase Notice**

**MonerOS is currently in Beta.** While we strive for maximum security, please be aware that the software is still under active development.

* **Community Contribution:** Real-world testing is vital to the evolution of this project. By using MonerOS now, you are helping us identify edge cases and harden the system for the entire community.

---

## **Bitcoin Support**

Bitcoin support is coming soon but will not be implemented until Monero has been stress tested. This is to ensure we can provide the utmost security, privacy and reliability to both Monero and Bitcoin.

---

## **Hardware Requirements**

**MonerOS** is designed to be lightweight and efficient. It can be deployed on most amd64 (64-bit) hardware, from older laptops to modern workstations. Self-Sync Nodes are best for maximum privacy but require significantly better hardware than Remote Nodes. Self-Sync Nodes also take days to be ready for use, whereas Remote Nodes are ready almost immediately.

### **1. ColdWalletOS (The Vault)**
* **CPU:** 2+ Cores
* **RAM:** 1GB+
* **Storage Space:** 4GB+
* **Storage Media:** Flash Drive, MicroSD, HDD, or SSD

### **2. HotWalletOS (The Gateway)**

| Requirement | **Option A: Remote Node** | **Option B: Self-Sync Node** |
| :--- | :--- | :--- |
| **Description** | Connects to an external node | Runs its own pruned blockchain node |
| **CPU** | 2+ Cores | 2+ Cores |
| **RAM** | 1GB+ | **8GB+** |
| **Storage Space** | 4GB+ | **250GB+** |
| **Storage Media** | Any (Flash/HDD/SSD) | **SSD ONLY** |

> **Note on Self-Sync:** A Solid State Drive (SSD) is strictly required for the Self-Sync option. Traditional Hard Drives (HDDs) cannot handle the I/O demands of blockchain synchronization.

---

## **Risks by node type**
<table>
  <tr>
    <th style="background-color: #000000; color: #ffffff; padding: 8px; border: 1px solid #ccc;">Data Point / Metadata Risk</th>
    <th style="background-color: #000000; color: #ffffff; padding: 8px; border: 1px solid #ccc;">Clearnet Node<br>(IP or .com address)</th>
    <th style="background-color: #000000; color: #ffffff; padding: 8px; border: 1px solid #ccc;">Tor Node<br>(.onion address)</th>
    <th style="background-color: #000000; color: #ffffff; padding: 8px; border: 1px solid #ccc;">Self-Sync<br>(Local node)</th>
  </tr>
  <tr>
    <td style="background-color: #FFFF00; color: #000000; padding: 8px; border: 1px solid #ccc;"><b>Your Real IP Address</b></td>
    <td style="background-color: #EE0000; color: #000000; padding: 8px; border: 1px solid #ccc;">Exposed</td>
    <td style="background-color: #47D459; color: #000000; padding: 8px; border: 1px solid #ccc;">Hidden</td>
    <td style="background-color: #47D459; color: #000000; padding: 8px; border: 1px solid #ccc;">Hidden</td>
  </tr>
  <tr>
    <td style="background-color: #FFFFFF; color: #000000; padding: 8px; border: 1px solid #ccc;"><b>View Key & Private Keys</b></td>
    <td style="background-color: #47D459; color: #000000; padding: 8px; border: 1px solid #ccc;">Hidden</td>
    <td style="background-color: #47D459; color: #000000; padding: 8px; border: 1px solid #ccc;">Hidden</td>
    <td style="background-color: #47D459; color: #000000; padding: 8px; border: 1px solid #ccc;">Hidden</td>
  </tr>
  <tr>
    <td style="background-color: #FFFFFF; color: #000000; padding: 8px; border: 1px solid #ccc;"><b>Imported Key Image Database</b></td>
    <td style="background-color: #47D459; color: #000000; padding: 8px; border: 1px solid #ccc;">Hidden</td>
    <td style="background-color: #47D459; color: #000000; padding: 8px; border: 1px solid #ccc;">Hidden</td>
    <td style="background-color: #47D459; color: #000000; padding: 8px; border: 1px solid #ccc;">Hidden</td>
  </tr>
  <tr>
    <td style="background-color: #FFFFFF; color: #000000; padding: 8px; border: 1px solid #ccc;"><b>Balances & Tx Amounts</b></td>
    <td style="background-color: #47D459; color: #000000; padding: 8px; border: 1px solid #ccc;">Hidden</td>
    <td style="background-color: #47D459; color: #000000; padding: 8px; border: 1px solid #ccc;">Hidden</td>
    <td style="background-color: #47D459; color: #000000; padding: 8px; border: 1px solid #ccc;">Hidden</td>
  </tr>
  <tr>
    <td style="background-color: #FFFFFF; color: #000000; padding: 8px; border: 1px solid #ccc;"><b>Sender & Receiver Addresses</b></td>
    <td style="background-color: #47D459; color: #000000; padding: 8px; border: 1px solid #ccc;">Hidden</td>
    <td style="background-color: #47D459; color: #000000; padding: 8px; border: 1px solid #ccc;">Hidden</td>
    <td style="background-color: #47D459; color: #000000; padding: 8px; border: 1px solid #ccc;">Hidden</td>
  </tr>
  <tr>
    <td style="background-color: #FFFF00; color: #000000; padding: 8px; border: 1px solid #ccc;"><b>Wallet Age / Restore Height</b></td>
    <td style="background-color: #EE0000; color: #000000; padding: 8px; border: 1px solid #ccc;">Exposed</td>
    <td style="background-color: #EE0000; color: #000000; padding: 8px; border: 1px solid #ccc;">Exposed</td>
    <td style="background-color: #47D459; color: #000000; padding: 8px; border: 1px solid #ccc;">Hidden</td>
  </tr>
  <tr>
    <td style="background-color: #FFFF00; color: #000000; padding: 8px; border: 1px solid #ccc;"><b>Sync Schedule & Uptime</b></td>
    <td style="background-color: #EE0000; color: #000000; padding: 8px; border: 1px solid #ccc;">Exposed</td>
    <td style="background-color: #EE0000; color: #000000; padding: 8px; border: 1px solid #ccc;">Exposed</td>
    <td style="background-color: #47D459; color: #000000; padding: 8px; border: 1px solid #ccc;">Hidden</td>
  </tr>
  <tr>
    <td style="background-color: #FFFF00; color: #000000; padding: 8px; border: 1px solid #ccc;"><b>Transaction Origin (IP Linkage)</b></td>
    <td style="background-color: #EE0000; color: #000000; padding: 8px; border: 1px solid #ccc;">Exposed</td>
    <td style="background-color: #47D459; color: #000000; padding: 8px; border: 1px solid #ccc;">Hidden</td>
    <td style="background-color: #47D459; color: #000000; padding: 8px; border: 1px solid #ccc;">Hidden</td>
  </tr>
  <tr>
    <td style="background-color: #FFFF00; color: #000000; padding: 8px; border: 1px solid #ccc;"><b>Block Withholding Risk (Eclipse)</b></td>
    <td style="background-color: #EE0000; color: #000000; padding: 8px; border: 1px solid #ccc;">Vulnerable</td>
    <td style="background-color: #EE0000; color: #000000; padding: 8px; border: 1px solid #ccc;">Vulnerable</td>
    <td style="background-color: #47D459; color: #000000; padding: 8px; border: 1px solid #ccc;">None</td>
  </tr>
  <tr>
    <td style="background-color: #FFFF00; color: #000000; padding: 8px; border: 1px solid #ccc;"><b>Transaction Censorship Risk</b></td>
    <td style="background-color: #EE0000; color: #000000; padding: 8px; border: 1px solid #ccc;">Vulnerable</td>
    <td style="background-color: #EE0000; color: #000000; padding: 8px; border: 1px solid #ccc;">Vulnerable</td>
    <td style="background-color: #47D459; color: #000000; padding: 8px; border: 1px solid #ccc;">None</td>
  </tr>
</table>

---

## **Coming Soon**

- Bitcoin Support
- Atomic Swap Support (XMR-BTC & BTC-XMR)
- arm64 support (including rpi4 & rpi5)
