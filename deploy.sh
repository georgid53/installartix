#!/bin/sh

# Artix Installation Script (after partitioning the disks manually)

# PARTITIONING

# With a BIOS Scheme since doing for a UEFI one rn for me is a waste of time

printf "Have you checked the internet connection and loaded the correct keymap? (y/n) " && read start1
if [ $start1 != 'y' ] && [ $start1 != 'yes' ]; then printf "Do that first, then run this script."; exit; fi

printf "Do you have a swap partition? (y/n) "
read ans1

if [ $ans1 != "n" ] && [ $ans1 != "no" ]; then 
    printf "Name of disk?\n"
    read disk
    printf "Swap partition number?\n"
    read swap_part
    printf "Root partition number?\n"
    read root_part
    mkfs.ext4 -L ROOT /dev/$disk$root_part
    mkswap -L SWAP /dev/$disk$swap_part
else
    printf "Root partition number?\n"
    read root_part
    mkfs.ext4 -L ROOT /dev/$disk$root_part
fi

printf "Done creating filesystems.\n"

# Mounting

if [ $ans1 != 'y' ] && [ $ans1 != 'yes'  ]; then
    printf "Now mounting the partitions.\n"
    mount /dev/disk/by-label/ROOT /mnt
else
    swapon /dev/disk/by-label/SWAP
    mount /dev/disk/by-label/ROOT /mnt
    mkdir -p /mnt/boot
    mkdir -p /mnt/home
fi

printf "Done mounting the partitions.\n"

# Base system install

printf "Now installing the base system for the OS.\n"

basestrap /mnt base base-devel openrc elogind-openrc
printf "Are you on a Intel or AMD CPU? (i/a) " && read cpu
if [ $cpu = 'a' ] || [ $cpu = 'amd' ] || [ $cpu = 'AMD' ]; then  
    basestrap /mnt linux linux-firmware amd-ucode vim
else
    basestrap /mnt linux linux-firmware intel-ucode vim
fi

printf "\nDone installing the base system.\n"

# Fstab

printf "Creating /etc/fstab.\n"
fstabgen -U /mnt >> /mnt/etc/fstab

# Chroot

printf "Chrooting into the new Artix system.\n"
artix-chroot /mnt /bin/bash

# System clock

printf "Enter timezone (template - 'Region/City'): " && read tzone
printf "\nConfiguring date and time.\n"
ln -sf /usr/share/zoneinfo/$tzone /etc/localtime
hwclock --systohc

# Locales

printf "\nEnter locale you want to use (country/language abbreviation): " && read alocale
sed '%s/\#us/us/g' /etc/locale.gen | sed '%s/\#${alocale}/${alocale}/g' > /etc/locale.gen
printf "Generating locales.\n"
locale-gen

# Boot loader

printf "Installing grub and creating a configuration file.\n"
pacman -S os-prober grub efibootmgr
grub-install /dev/$disk
grub-mkconfifg -o /boot/grub/grub.cfg

# User add

printf "Set the root password: " && passwd
printf "Name of the new user: " && read username
printf "\nCreating new user."
useradd -m $username
usermod -aG wheel,storage,audio,video $username
printf "Set the password for ${username} user: " && passwd $username

# Network

printf "Set the hostname: " && read myhostname
printf "Creating hostname file and configuring /etc/hosts.\n"
echo $myhostname >> /etc/hostname
echo "127.0.0.1     localhost\n::1      localhost\n127.0.1.1        ${myhostname}.localdomain ${myhostname}" >> /etc/hosts
echo "hostname='${myhostname}'" > /etc/conf.d/hostname

printf "Installing dhcp client\n"
pacman -S dhcpcd
rc-update add dhcpcd default
printf "Insalling wpa_supplicant\n"
pacman -S wpa_supplicant
rc-update add wpa_supplicant default

printf "Installing connman network manager\n"
pacman -S connman-openrc connman-gtk
rc-update add connmand default

# Extra tools

printf "Do you want to install some extra tools (e.g. doas,git,cronie) (y/n) " && read ans2

if [ $ans2 = 'y' ] || [ $ans2 = 'yes'  ]; then
    pacman -S doas git cronie-openrc
    rc-update add cronie default
else
    printf "\nThank you for using this script!"
    exit
fi        

printf "\nThank you for using this script!"
exit

