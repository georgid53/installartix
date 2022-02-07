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

printf "Chrooting into the new Artix system. Run the command below in order to automate everything else in the install: \nbash /tmp/chrooting.sh\n"
cp src/chrooting.sh /mnt/tmp/
artix-chroot /mnt /bin/bash
