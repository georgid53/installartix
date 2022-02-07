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

