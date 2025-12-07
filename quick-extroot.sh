#!/bin/sh
#
# --------------------------------
# openwrt : quick-extroot v0.2a fixed
# -------------------------------
# (c) 2021 suuhm, adapted 2025
#

__DEV="/dev/sda"

# Проверка устройства
_check_device() {
    if [ -b "$1" ]; then
        echo "[*] Device $1 found"
        __DEV="$1"
    else
        echo "[!!] ERROR: Device $1 not found!"
        exit 1
    fi
}

# Создание extroot
_set_xedroot() {
    echo "[*] Installing dependencies..."
    opkg update
    opkg install block-mount kmod-fs-ext4 kmod-usb-storage kmod-usb-ohci kmod-usb-uhci e2fsprogs fdisk

    if [ $? -ne 0 ]; then
        echo "[!!] ERROR: opkg failed"
        exit 1
    fi

    # Определение устройства
    if [ -z "$1" ]; then
        echo "--------------------- LIST OF DEVICES ---------------------"
        fdisk -l | grep -e '^Disk.*sd' | awk '{print "  "$2 }'
        echo "-----------------------------------------------------------"
        echo -n "Enter device without number (e.g. /dev/sda) [$__DEV]: "
        read CH_DEV
        if [ -z "$CH_DEV" ]; then
            CH_DEV="$__DEV"
        fi
    else
        CH_DEV="$1"
    fi
    _check_device "$CH_DEV"

    echo "[*] WARNING! All data on $CH_DEV will be destroyed! Continue? (y/n)"
    read yn
    if [ "$yn" != "y" ]; then
        echo "[*] Exiting..."
        exit 0
    fi

    # Очистка старых разделов и создание MBR
    echo "[*] Wiping old partitions..."
    dd if=/dev/zero of="$CH_DEV" bs=512 count=2048 conv=fsync

    echo "[*] Creating new ext4 partition..."
    echo ",,83,*" | sfdisk "$CH_DEV" --wipe=always
    if [ $? -ne 0 ]; then
        echo "[!!] Failed to create partition table"
        exit 1
    fi

    XTDEVICE="${CH_DEV}1"

    echo "[*] Formatting partition $XTDEVICE as ext4..."
    mkfs.ext4 -F -L extroot "$XTDEVICE"

    # Копирование текущего overlay
    echo "[*] Copying current overlay..."
    mkdir -p /tmp/cproot /mnt/extroot
    mount --bind /overlay /tmp/cproot
    mount "$XTDEVICE" /mnt/extroot
    tar -C /tmp/cproot -cf - . | tar -C /mnt/extroot -xf -
    umount /tmp/cproot /mnt/extroot

    # Настройка fstab
    UUID=$(blkid -s UUID -o value "$XTDEVICE")
    if [ -z "$UUID" ]; then
        echo "[!!] Failed to get UUID for $XTDEVICE"
        exit 1
    fi

    uci -q delete fstab.overlay
    uci set fstab.overlay="mount"
    uci set fstab.overlay.uuid="$UUID"
    uci set fstab.overlay.target="/overlay"
    uci set fstab.overlay.options="rw,noatime,data=writeback"
    uci commit fstab

    echo "[*] Extroot setup complete. Reboot required!"
    echo "*****************************************"
    sleep 3
    reboot
}

# MAIN
echo "_________________________________________________"
echo "- QUICK - EXTROOT OPENWRT v0.2a fixed -"
echo "_________________________________________________"
echo

if [ "$1" = "--create-extroot" ]; then
    _set_xedroot "$2"
    exit 0
elif [ "$1" = "--create-swap" ]; then
    echo "[*] Swap creation not modified"
    exit 0
elif [ "$1" = "--set-opkg2er" ]; then
    echo "[*] opkg2er not modified"
    exit 0
elif [ "$1" = "--fixup-extroot" ]; then
    echo "[*] fixup-extroot not modified"
    exit 0
else
    echo
    echo "Usage: $0 <OPTIONS> [DEV]"
    echo "Options:"
    echo "  --create-extroot <dev>"
    echo "  --create-swap <dev>"
    echo "  --set-opkg2er"
    echo "  --fixup-extroot <dev>"
    exit 1
fi
