#!/bin/bash
set -e

clear
echo "=== MINIMAL ARCH HYPRLAND INSTALLER (COMPLETE) ==="

# --------------------------------------------------
# USER INPUT
# --------------------------------------------------
read -p "Target disk (e.g. /dev/nvme0n1): " DISK
read -p "Username: " USERNAME
read -s -p "User password: " USERPASS
echo
read -s -p "Root password: " ROOTPASS
echo

echo "Select timezone region (e.g. Asia, Europe):"
ls /usr/share/zoneinfo
read -p "Region: " TZ_REGION

echo "Select city (e.g. Kolkata, Berlin):"
ls /usr/share/zoneinfo/$TZ_REGION
read -p "City: " TZ_CITY

TIMEZONE="$TZ_REGION/$TZ_CITY"

timedatectl set-ntp true

# --------------------------------------------------
# MIRRORS
# --------------------------------------------------
cat > /etc/pacman.d/mirrorlist <<EOF
Server = https://mirror.kumi.systems/archlinux/\$repo/os/\$arch
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/\$repo/os/\$arch
Server = https://mirror.nus.edu.sg/archlinux/\$repo/os/\$arch
EOF

# --------------------------------------------------
# DISK SETUP
# --------------------------------------------------
wipefs -af "$DISK"
sgdisk -Z "$DISK"
sgdisk -n 1:0:+1G -t 1:ef00 "$DISK"
sgdisk -n 2:0:0   -t 2:8300 "$DISK"

EFI="${DISK}p1"
ROOT="${DISK}p2"

mkfs.fat -F32 "$EFI"
mkfs.btrfs -f "$ROOT"

mount "$ROOT" /mnt
btrfs subvolume create /mnt/@
umount /mnt

mount -o compress=zstd,subvol=@ "$ROOT" /mnt
mkdir -p /mnt/boot
mount "$EFI" /mnt/boot

# --------------------------------------------------
# BASE + HYPRLAND STACK
# --------------------------------------------------
pacstrap /mnt \
base linux linux-firmware linux-headers grub sudo \
networkmanager \
btrfs-progs zram-generator \
mesa libglvnd vulkan-icd-loader libdrm libinput \
wayland wayland-protocols \
hyprland wlroots xwayland \
xdg-desktop-portal xdg-desktop-portal-hyprland \
pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber \
dbus polkit seatd \
bluez bluez-utils \
xdg-user-dirs xdg-utils \
grim slurp wl-clipboard brightnessctl playerctl pamixer \
foot swaybg \
git base-devel \
noto-fonts noto-fonts-emoji ttf-font-awesome

genfstab -U /mnt > /mnt/etc/fstab

# --------------------------------------------------
# CHROOT CONFIGURATION
# --------------------------------------------------
arch-chroot /mnt <<EOF
set -e

ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "arch" > /etc/hostname

systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable seatd

cat > /etc/systemd/zram-generator.conf <<ZRAM
[zram0]
zram-size = 4G
compression-algorithm = zstd
ZRAM

useradd -m -G wheel,seat $USERNAME
echo "$USERNAME:$USERPASS" | chpasswd
echo "root:$ROOTPASS" | chpasswd
echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/wheel

# --------------------------------------------------
# BOOTLOADER
# --------------------------------------------------
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
sed -i 's/^GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX="rootflags=subvol=@ quiet"/' /etc/default/grub
sed -i 's/^#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=true/' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

# --------------------------------------------------
# INSTALL YAY (USER)
# --------------------------------------------------
su - $USERNAME <<'USER'
set -e
cd /tmp
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
cd ~
rm -rf /tmp/yay
USER

# --------------------------------------------------
# PRINTER + NVIDIA
# --------------------------------------------------
su - $USERNAME <<'USER'
set -e

sudo pacman -S --needed --noconfirm \
cups cups-filters ghostscript \
foomatic-db foomatic-db-engine system-config-printer

yay -S --needed --noconfirm \
epson-inkjet-printer-202101w \
epsonscan2 \
epsonscan2-non-free-plugin \
epson-printer-utility

sudo systemctl enable --now cups

sudo ln -sf \
/opt/epson-inkjet-printer-202101w/cups/lib/filter/epson_printer_filter \
/usr/lib/cups/filter/epson_printer_filter

sudo usermod -aG lp \$USER

yay -S --needed --noconfirm \
nvidia-535xx-utils \
nvidia-535xx-dkms \
nvidia-535xx-settings

sudo mkinitcpio -P

# --------------------------------------------------
# HYPRLAND DOTS
# --------------------------------------------------
cd ~/.cache
git clone https://github.com/end-4/dots-hyprland
cd dots-hyprland
chmod +x setup
./setup install
USER
EOF

# --------------------------------------------------
# FINISH
# --------------------------------------------------
umount -R /mnt
echo "=== INSTALL COMPLETE — REBOOTING ==="
sleep 5
reboot
