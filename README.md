# **Backgroud**
I built this project because I am a firm believer in Privacy, in all sense of the word. The beautiful thing about Monero is that it behaves like cash. In a world where most currency transactions are digital, privacy and security are increasingly scarce. If I send you money over an unamed app, it's tracked. If I send you Bitcoin, it's tracked. If I hand you cash, there is no record. Monero functions the same way as cash, but digitally. When setup correctly, there is no real record. Before creating this, I realized there is no good way for the average person to set up a wallet in a truly secure and private way. There is no good way for the average person to transfer Monero in a truly private and secure way. If you don't have the skills to physically remove network hardware from your PC, or don't have a spare PC to remove them from, your keys are not TRULY protected. Aside from that, are you sure you know how to propely configure everything when ready to send a transaction? MonerOS was created to ensure complete privacy and security for even the most novice user. I don't claim to be an expert in the field, but what I've created is much more secure and private than the average person, and you don't need a solid technology background in order to use it properly. The key is that since it's an operating system, we can completely disable its ability to even recognize network hardware when needed. It is bootable on a USB drive so that when you unplug it, there is no record left on your PC. No expensive cold wallets where information is often leaked, and you can't see all the code. Don't even get me started on using exchanges. All code here is open source and just takes a couple spare flash drives. We can't see your keys. Nobody can see your keys. That point is verifiable in the code. It's probably not perfect, but it's better than what the average person is using.

# **MonerOS**
**The Open-Source, Dual-OS Ecosystem for Sovereign Asset Management**

**MonerOS** is a free, open-source suite of operating systems engineered to provide a professional-grade security bridge for your digital assets. By decoupling transaction preparation from private key signing, MonerOS eliminates the vulnerabilities inherent in traditional "always-online" environments.

The ecosystem consists of two specialized nodes: **HotWalletOS** and **ColdWalletOS**.

You don't need to be an expert to setup your own security and privacy focused wallet. MonerOS does this by default. You don't need to know how to remove network cards, etc. **ColdWalletOS** can't see them.

---

## Installation and User Manual
* **[Read the Installation Manual](https://sourceforge.net/p/moneros/code/ci/main/tree/MonerOS_Installation_Manual.pdf?format=raw)**
* **[Read the User Manual](https://sourceforge.net/p/moneros/code/ci/main/tree/MonerOS_User_Manual.pdf?format=raw)**

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

**MonerOS** is designed to be lightweight and efficient. It can be deployed on most amd64 (64-bit) hardware, from older laptops to modern workstations. Self-Sync Nodes are best for maximum privacy but require significantly better hardware than Remote Nodes. Self-Sync Nodes also take days to be ready for use, whereas Remote Nodes are ready immediately.

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