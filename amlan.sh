#!/bin/bash
# ==============================================================================
# AMLAN FULL ARCH INSTALLER — FINAL (FIXED)
# UEFI • systemd-boot • Swap • NVIDIA 580xx • Epson Printer
# Auto reboot ONLY on success
# ==============================================================================

set -e
trap 'echo "❌ Installer failed at line $LINENO. No reboot."; exit 1' ERR

clear
echo "======================================================"
echo "   AMLAN FULL ARCH INSTALLER — FINAL (FIXED)"
echo "======================================================"

# ------------------------------------------------------
# USER INFO
# ------------------------------------------------------
read -p "Username: " USERNAME
read -s -p "User password: " USERPASS
echo
read -s -p "Root password: " ROOTPASS
echo

# ------------------------------------------------------
# INTERNET
# ------------------------------------------------------
ping -c 2 archlinux.org >/dev/null || {
  echo "❌ No internet. Run iwctl."
  exit 1
}

timedatectl set-ntp true
sed -i 's/^#ParallelDownloads.*/ParallelDownloads = 10/' /etc/pacman.conf

# ------------------------------------------------------
# CPU MICROCODE
# ------------------------------------------------------
CPU_VENDOR=$(grep -m1 vendor_id /proc/cpuinfo | awk '{print $3}')
UCODE=""
[[ "$CPU_VENDOR" == "GenuineIntel" ]] && UCODE="intel-ucode"
[[ "$CPU_VENDOR" == "AuthenticAMD" ]] && UCODE="amd-ucode"

GPU_PKGS="mesa libglvnd vulkan-icd-loader"

# ------------------------------------------------------
# KERNEL
# ------------------------------------------------------
echo "Kernel:"
echo "1) linux"
echo "2) linux-lts"
echo "3) linux-zen"
read -p "Choice: " k

case $k in
  1) KERNEL="linux" ;;
  2) KERNEL="linux-lts" ;;
  3) KERNEL="linux-zen" ;;
  *) exit 1 ;;
esac

# ------------------------------------------------------
# DESKTOP
# ------------------------------------------------------
echo "Desktop:"
echo "1) KDE Plasma"
echo "2) GNOME"
echo "3) XFCE"
echo "4) i3 (minimal)"
echo "5) None (CLI only)"
read -p "Choice: " d

case $d in
  1) DE_PKGS="plasma-meta konsole dolphin sddm"; DM="sddm" ;;
  2) DE_PKGS="gnome gnome-extra gdm"; DM="gdm" ;;
  3) DE_PKGS="xfce4 xfce4-goodies lightdm lightdm-gtk-greeter"; DM="lightdm" ;;
  4) DE_PKGS="i3-wm i3status dmenu xterm lightdm lightdm-gtk-greeter"; DM="lightdm" ;;
  5) DE_PKGS=""; DM="" ;;
  *) exit 1 ;;
esac

# ------------------------------------------------------
# PARTITIONING
# ------------------------------------------------------
lsblk
echo "Create EFI, ROOT, and SWAP partitions"
read -p "Press ENTER to open cfdisk..."
cfdisk
lsblk

read -p "EFI partition (e.g. /dev/sda1): " EFI
read -p "ROOT partition (e.g. /dev/sda2): " ROOT
read -p "SWAP partition (leave blank if none): " SWAP

mkfs.fat -F32 "$EFI"
mkfs.ext4 -F "$ROOT"

mount "$ROOT" /mnt
mkdir -p /mnt/boot
mount "$EFI" /mnt/boot

if [[ -n "$SWAP" ]]; then
  lsblk "$SWAP" >/dev/null || { echo "❌ Invalid swap device"; exit 1; }
  mkswap "$SWAP"
  swapon "$SWAP"
fi

# ------------------------------------------------------
# BASE INSTALL
# ------------------------------------------------------
pacstrap /mnt \
  base $KERNEL $UCODE linux-firmware \
  $GPU_PKGS sudo nano git networkmanager \
  $DE_PKGS firefox pipewire pipewire-pulse

genfstab -U /mnt > /mnt/etc/fstab
ROOT_UUID=$(blkid -s UUID -o value "$ROOT")

# ------------------------------------------------------
# CHROOT CONFIG
# ------------------------------------------------------
arch-chroot /mnt /bin/bash <<EOF
set -e

[[ -d /sys/firmware/efi ]] || {
  echo "❌ Not booted in UEFI mode"
  exit 1
}

ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
hwclock --systohc

sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

echo "arch" > /etc/hostname

systemctl enable NetworkManager
[[ -n "$DM" ]] && systemctl enable $DM

useradd -m -G wheel -s /bin/bash $USERNAME
echo "$USERNAME:$USERPASS" | chpasswd
echo "root:$ROOTPASS" | chpasswd

echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/wheel
chmod 440 /etc/sudoers.d/wheel

bootctl install
mkdir -p /boot/loader/entries

cat > /boot/loader/entries/arch.conf <<ENTRY
title   Arch Linux
linux   /vmlinuz-$KERNEL
initrd  /$UCODE.img
initrd  /initramfs-$KERNEL.img
options root=UUID=$ROOT_UUID rw quiet
ENTRY
EOF

# ------------------------------------------------------
# YAY + NVIDIA 580xx (FIXED HEADERS)
# ------------------------------------------------------
arch-chroot /mnt /bin/bash <<EOF
set -e
pacman -Syu --noconfirm base-devel ${KERNEL}-headers
su - $USERNAME -c "
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
rm -rf ~/yay
yay -S --noconfirm nvidia-580xx-dkms nvidia-580xx-settings
"
EOF

# ------------------------------------------------------
# PRINTER SETUP (EPSON)
# ------------------------------------------------------
arch-chroot /mnt /bin/bash <<EOF
set -e

pacman -S --needed --noconfirm \
  cups cups-filters ghostscript \
  foomatic-db foomatic-db-engine \
  system-config-printer

su - $USERNAME -c "
yay -S --needed --noconfirm \
  epson-inkjet-printer-202101w \
  epsonscan2 \
  epsonscan2-non-free-plugin \
  epson-printer-utility
"

systemctl enable --now cups

ln -sf \
/opt/epson-inkjet-printer-202101w/cups/lib/filter/epson_printer_filter \
/usr/lib/cups/filter/epson_printer_filter || true

usermod -aG lp $USERNAME
EOF

# ------------------------------------------------------
# FINISH
# ------------------------------------------------------
umount -R /mnt

echo "======================================================"
echo "✅ INSTALL SUCCESSFUL — REBOOTING"
echo "======================================================"

sleep 5
reboot
