Minimal Arch Installer
A fully automated, minimal Arch Linux installer focused on clarity, control, and zero bloat.
This script installs Arch Linux with:
UEFI + GRUB
Btrfs (compressed)
zram swap
Open-source graphics drivers
PipeWire audio
Bluetooth
NetworkManager
Optional desktop environment or server-only setup
Nothing extra. Nothing hidden.
Features
Single Linux kernel (no LTS / Zen)
GRUB only (OS probing disabled)
Btrfs root with zstd compression
zram swap (4 GB, no disk swap)
Open-source drivers only
Fast mirrors (India, China, Singapore)
User-selected timezone
Desktop choice:
KDE Plasma
GNOME
XFCE
LXQt
Niri
Hyprland
Server only (no GUI)
Disk Layout
The target disk is fully erased and repartitioned:
Partition
Size
Type
EFI
1 GB
FAT32
Root
Rest of disk
Btrfs
Btrfs layout:
Subvolume: @
Mount options: compress=zstd
What Gets Installed
Base system
base
linux
linux-firmware
sudo
networkmanager
grub
Filesystem & memory
btrfs-progs
zram-generator
Graphics (open source)
mesa
libglvnd
vulkan-icd-loader
Audio
PipeWire stack:
pipewire
pipewire-alsa
pipewire-pulse
pipewire-jack
wireplumber
Bluetooth
bluez
bluez-utils
What Is Not Installed (By Design)
No AUR / yay
No proprietary drivers
No printers
No microcode guessing
No os-prober
No extra services
No swap partition
No Xorg unless required by the desktop
Requirements
Booted in UEFI mode
Active internet connection
Run from Arch ISO
Correct disk name (data loss is permanent)
Usage
Boot Arch ISO (UEFI)
Connect to internet
Make script executable:


       chmod +x Archinstall.sh
Run
       ./Archinstall.sh
Follow prompts
System reboots when finished
Notes
Time synchronization uses systemd-timesyncd
Timezone is selected manually (Region / City)
NetworkManager and Bluetooth are enabled by default
Display manager is enabled only if a desktop is installed
Philosophy
This installer treats Arch as an operating system, not a personality trait.
You choose:
Disk
Timezone
Desktop
The script does the rest—quietly, predictably, and without opinions.
If you want:
Encryption
Snapshots
Separate /home
Wayland-only builds
Server hardening
Those belong in another script.
