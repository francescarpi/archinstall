#!/bin/bash

echo "Instal·lació Dell Inspiron 5567"
echo
echo "0) Sortir"
echo "1) Particionat i instalació bàsica."
echo "   La taula de particions ha d'estar creada."
echo "   500M: EFI System"
echo "   Resto: Linux filesystem"
echo "2) Boot, zona horaria, locale, usuari, etc"
echo "3) Instal·lació de KDE"
echo
read -p "Selecciona opció: " OPCIO

if [ "$OPCIO" = "1" ]; then
    echo
    timedatectl set-ntp true
    read -p "Indica disc de destí. Exemple /dev/sdb: " DISC
    mkfs.vfat -F32 ${DISC}1
    mkfs.ext4 ${DISC}2
    cryptsetup -s 512 luksFormat ${DISC}2
    cryptsetup luksOpen ${DISC}2 rootfs
    mkfs.ext4 /dev/mapper/rootfs
    mount /dev/mapper/rootfs /mnt
    mkdir /mnt/boot
    mount ${DISC}1 /mnt/boot
    curl -s 'https://www.archlinux.org/mirrorlist/?country=ES&protocol=http&protocol=https&ip_version=4&use_mirror_status=on' | sed -e 's/#Server/Server/g' > /etc/pacman.d/mirrorlist
    pacstrap /mnt base linux linux-firmware systemd-swap vim zsh sudo networkmanager htop git python-virtualenvwrapper which base-devel mlocate
    genfstab -L /mnt | sed -e 's/relatime/relatime,noatime/g' > /mnt/etc/fstab
    cp install.sh /mnt/
    arch-chroot /mnt
fi

if [ "$OPCIO" = "2" ]; then
    echo
    sed -i 's/swapfc_enabled=0/swapfc_enabled=1/g' /etc/systemd/swap.conf
    systemctl enable systemd-swap
    ln -sf /usr/share/zoneinfo/Europe/Madrid /etc/localtime
    hwclock --systohc
    sed -i 's/#es_ES.UTF/es_ES.UTF/g' /etc/locale.gen
    locale-gen
    echo "LANG=es_ES.UTF-8" > /etc/locale.conf
    echo "KEYMAP=es" > /etc/vconsole.conf
    echo "laptop" > /etc/hostname
    echo '127.0.0.1 localhost' > /etc/hosts
    echo '::1 localhost' >> /etc/hosts
    echo '127.0.1.1 laptop.localdomain laptop' >> /etc/hosts
    systemctl enable NetworkManager.service
    echo 'options iwlmvm power_scheme=1' > /etc/modprobe.d/iwlmvm.conf
    echo 'options iwlwifi bt_coex_active=Y swcrypto=1 i18n_disable=1' > /etc/modprobe.d/iwlwifi.conf
    passwd
    useradd -m -G wheel,users,audio,sys,network,power,lp -s /bin/zsh farpi
    passwd farpi
    sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' /etc/sudoers
    sed -i 's/#Colo/Colo/g' /etc/pacman.conf
    sed -i 's/(base udev autodetect modconf block filesystems keyboard fsck)/(base udev keyboard autodetect modconf block encrypt filesystems fsck)/g' /etc/mkinitcpio.conf
    bootctl install
    mkinitcpio -p linux
    echo 'title Arch Linux' > /boot/loader/entries/arch.conf
    echo 'linux /vmlinuz-linux' >> /boot/loader/entries/arch.conf
    echo 'initrd /initramfs-linux.img' >> /boot/loader/entries/arch.conf
    echo 'options cryptdevice=/dev/sda2:rootfs root=/dev/mapper/rootfs rw quiet splash' >> /boot/loader/entries/arch.conf
    echo 'default arch' > /boot/loader/loader.conf
    echo 'timeout 3' >> /boot/loader/loader.conf
    echo 'blacklist pcspkr' > /etc/modprobe.d/nobeep.conf
fi

if [ "$OPCIO" = "3" ]; then
    echo
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
    sudo pacman -S plasma sddm dolphin konsole flameshot chromium telegram-desktop openssh ark packagekit-qt5
    sudo systemctl enable sddm
fi
