#!/bin/bash
# ==============================================================================
# AMLAN CLEAN ARCH INSTALLER (LIMINE + SAFE GPU)
# No NVIDIA. No DKMS. Clean baseline.
# ==============================================================================

set -e
trap 'echo "❌ Error on line $LINENO"; exit 1' ERR

clear
echo "======================================================"
echo "   AMLAN CLEAN ARCH INSTALLER"
echo "   Bootloader : LIMINE (UEFI)"
echo "   GPU        : Open-source only"
echo "======================================================"

# ------------------------------------------------------
# 1. INTERNET CHECK
# ------------------------------------------------------
echo "[+] Checking internet..."
ping -c 2 archlinux.org >/dev/null || {
  echo "❌ No internet. Run iwctl first."
  exit 1
}

# ------------------------------------------------------
# 2. TIME & PACMAN
# ------------------------------------------------------
timedatectl set-ntp true

sed -i \
  -e 's/^#ParallelDownloads.*/ParallelDownloads = 10/' \
  -e 's/^ParallelDownloads.*/ParallelDownloads = 10/' \
  /etc/pacman.conf

# ------------------------------------------------------
# 3. CPU MICROCODE
# ------------------------------------------------------
CPU_VENDOR=$(grep -m1 vendor_id /proc/cpuinfo | awk '{print $3}')
UCODE=""
[[ "$CPU_VENDOR" == "GenuineIntel" ]] && UCODE="intel-ucode"
[[ "$CPU_VENDOR" == "AuthenticAMD" ]] && UCODE="amd-ucode"

# ------------------------------------------------------
# 4. SAFE GPU STACK (NO NVIDIA)
# ------------------------------------------------------
GPU_PKGS="mesa libglvnd vulkan-icd-loader"

# ------------------------------------------------------
# 5. KERNEL SELECTION
# ------------------------------------------------------
echo "Choose kernel:"
echo "1) linux"
echo "2) linux-lts"
echo "3) linux-zen"
read -p "Selection: " k

case $k in
  1) KERNEL="linux" ;;
  2) KERNEL="linux-lts" ;;
  3) KERNEL="linux-zen" ;;
  *) echo "❌ Invalid choice"; exit 1 ;;
esac

# ------------------------------------------------------
# 6. DESKTOP SELECTION
# ------------------------------------------------------
echo "Choose desktop:"
echo "1) KDE Plasma"
echo "2) GNOME"
echo "3) XFCE"
read -p "Selection: " d

case $d in
  1) DE_PKGS="plasma-meta konsole dolphin sddm"; DM="sddm" ;;
  2) DE_PKGS="gnome gnome-extra gdm"; DM="gdm" ;;
  3) DE_PKGS="xfce4 xfce4-goodies lightdm lightdm-gtk-greeter"; DM="lightdm" ;;
  *) echo "❌ Invalid choice"; exit 1 ;;
esac

# ------------------------------------------------------
# 7. PARTITIONING
# ------------------------------------------------------
lsblk
echo
echo "Create:"
echo " - EFI  (FAT32, ~300–512M)"
echo " - ROOT (ext4)"
read -p "Press ENTER to open cfdisk..."
cfdisk
lsblk

read -p "EFI partition (e.g. /dev/sda1): " EFI
read -p "ROOT partition (e.g. /dev/sda2): " ROOT

[[ "$EFI" == "$ROOT" ]] && { echo "❌ EFI and ROOT cannot be same"; exit 1; }

# ------------------------------------------------------
# 8. FORMAT & MOUNT
# ------------------------------------------------------
mkfs.fat -F32 "$EFI"
mkfs.ext4 -F "$ROOT"

mount "$ROOT" /mnt
mkdir -p /mnt/boot
mount "$EFI" /mnt/boot

# ------------------------------------------------------
# 9. BASE INSTALL (NO ESR HERE)
# ------------------------------------------------------
pacstrap /mnt \
  base \
  $KERNEL \
  $UCODE \
  linux-firmware \
  $GPU_PKGS \
  sudo nano git networkmanager \
  $DE_PKGS \
  firefox \
  pipewire pipewire-pulse \
  limine efibootmgr

genfstab -U /mnt > /mnt/etc/fstab

# ------------------------------------------------------
# 10. SYSTEM CONFIG
# ------------------------------------------------------
read -p "Hostname: " HOSTNAME
read -p "Username: " USERNAME
read -p "Timezone (Asia/Kolkata): " TZ

arch-chroot /mnt /bin/bash <<EOF
set -e

ln -sf /usr/share/zoneinfo/$TZ /etc/localtime
hwclock --systohc

sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

echo "$HOSTNAME" > /etc/hostname

systemctl enable NetworkManager
systemctl enable $DM

useradd -m -G wheel -s /bin/bash $USERNAME
echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/10-wheel
chmod 440 /etc/sudoers.d/10-wheel

# ---------------- LIMINE ----------------
limine-install /boot

cat > /boot/limine.cfg <<LIMINE
timeout: 5
default_entry: 1

:Arch Linux
    protocol: linux
    kernel_path: boot:///vmlinuz-$KERNEL
    initrd_path: boot:///initramfs-$KERNEL.img
    cmdline: root=$ROOT rw quiet
LIMINE

EOF

# ------------------------------------------------------
# 11. PASSWORDS
# ------------------------------------------------------
arch-chroot /mnt passwd
arch-chroot /mnt passwd $USERNAME

# ------------------------------------------------------
# 12. YAY + FIREFOX ESR
# ------------------------------------------------------
arch-chroot /mnt /bin/bash <<EOF
set -e
pacman -S --needed --noconfirm base-devel
su - $USERNAME -c "
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
yay -S --noconfirm firefox-esr
sudo pacman -Rns --noconfirm firefox
"
EOF

umount -R /mnt

echo "======================================================"
echo "✅ INSTALL COMPLETE"
echo "Reboot and enjoy CLEAN Arch."
echo "======================================================"
