Minimal Arch Installer
======================

A minimal, automated Arch Linux installer focused on clarity, control, and zero bloat.

This script installs Arch Linux with:
- UEFI + GRUB
- Btrfs (compressed)
- zram swap
- Open-source graphics drivers only
- PipeWire audio
- Bluetooth
- NetworkManager
- Optional desktop environment or server-only setup

Nothing extra. Nothing hidden.


Features
--------

- Single Linux kernel (standard linux)
- GRUB bootloader (OS probing disabled)
- Btrfs root with zstd compression
- zram swap (4 GB, no disk swap partition)
- Open-source Mesa/Vulkan drivers
- Fast mirrors (India, China, Singapore)
- User-selected timezone (region + city)
- Desktop options:
  - KDE Plasma
  - GNOME
  - XFCE
  - LXQt
  - Niri
  - Hyprland
  - Server only (no GUI)


Disk Layout
-----------

The selected disk is fully erased.

Partitions:
- EFI: 1 GB, FAT32
- Root: remaining space, Btrfs

Btrfs configuration:
- Subvolume: @
- Mount options: compress=zstd


Installed Packages
------------------

Base system:
- base
- linux
- linux-firmware
- sudo
- grub
- networkmanager

Filesystem and memory:
- btrfs-progs
- zram-generator

Graphics (open source):
- mesa
- libglvnd
- vulkan-icd-loader

Audio:
- pipewire
- pipewire-alsa
- pipewire-pulse
- pipewire-jack
- wireplumber

Bluetooth:
- bluez
- bluez-utils


Not Installed (By Design)
-------------------------

- No AUR or yay
- No proprietary drivers
- No printers
- No microcode guessing
- No os-prober
- No swap partition
- No unnecessary services
- No Xorg unless required by the chosen desktop


Requirements
------------

- Booted in UEFI mode
- Active internet connection
- Run from Arch Linux ISO
- Correct disk selection (data loss is permanent)


Usage
-----

1. Boot into the Arch ISO (UEFI)
2. Connect to the internet
3. Make the script executable:
   chmod +x install.sh
4. Run the installer:
   ./install.sh
5. Follow the prompts
6. System reboots automatically on success


Notes
-----

- Time synchronization uses systemd-timesyncd
- Timezone is selected manually (Region/City)
- NetworkManager and Bluetooth are enabled by default
- A display manager is enabled only if a desktop is installed


Philosophy
----------

Arch is treated as an operating system, not a lifestyle.

You choose:
- Disk
- Timezone
- Desktop

The script handles the rest quietly and predictably.
