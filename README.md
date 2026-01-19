# Archinstall

A **personal Arch Linux installer script** tailored specifically for my hardware and workflow.

⚠️ **IMPORTANT WARNING**  
This script is **NOT universal**.

It is written for:
- My laptop hardware
- UEFI systems only
- NVIDIA legacy (580xx) GPUs
- Epson printers
- My preferred desktop environments and defaults

Running this script **as-is on other machines may break your system, wipe disks, or fail to boot**.

---

## What this script does

- Installs Arch Linux in **UEFI mode** using `systemd-boot`
- Supports **swap partition**
- Installs one of the following desktops:
  - KDE Plasma
  - GNOME
  - XFCE
  - i3 (minimal)
  - Or CLI-only
- Sets up:
  - Networking (NetworkManager)
  - Audio (PipeWire)
  - User + root accounts
- Installs **NVIDIA 580xx DKMS drivers**
- Installs **Epson printer & scanner drivers**
- Automatically reboots **only if installation succeeds**

---

## What this script assumes

- You are booted in **UEFI mode**
- You understand **disk partitioning**
- You have already created:
  - EFI partition (FAT32)
  - Root partition (ext4)
  - Optional swap partition
- You know what you are doing

This script **will format partitions you provide**.  
There is **no confirmation prompt**.

---

## Intended use

This repository exists for:
- Personal backup
- Reproducibility
- Learning
- Reference

If you want to use it on your system:
1. **READ THE SCRIPT**
2. Modify hardware-specific sections
3. Remove NVIDIA / printer blocks if not applicable
4. Test in a VM first

---

## Disclaimer

I am **not responsible** for:
- Data loss
- Boot failures
- Broken installs
- Emotional damage caused by Arch Linux

Use at your own risk.
