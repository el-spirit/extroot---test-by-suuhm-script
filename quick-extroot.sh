#!/bin/sh
#
# --------------------------------
# openwrt : quick-extroot v0.2a full fix
# -------------------------------
# (c) 2021 suuhm, adapted 2025
#

__DEV="/dev/sda"

# -----------------------
# Проверка устройства
# -----------------------
_check_device() {
    if [ -b "$1" ]; then
        echo "[*] Device $1 found"
        __DEV="$1"
    else
        echo "[!!] ERROR: Device $1 not found!"
        exit 1
    fi
}

# -----------------------
# Создание extroot
# -----------------------
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

    # Подтверждение удаления данных
    if [ "$1" = "--create-extroot" ]; then
        yn="y"
    else
        echo "[*] WARNING! All data on $CH_DEV will be destroyed! Continue? (y/n)"
        read yn
    fi

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

    # Настройка fstab с использованием block info
    UUID=$(block info "$XTDEVICE" | grep -o -e "UUID=[^ ]*" | cut -d= -f2)
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

    echo "[*] Extroot setup complete."
    echo "*****************************************"
}

# -----------------------
# Создание swap-файла
# -----------------------
_set_swap() {
    if [ -z "$1" ]; then
        FS=$(free -m | awk '/Mem:/ {print $2}')
        NS=$(($FS / 1024 * 4))
        echo "[*] Creating swap file of $NS MB on /usr/lib/extroot.swap"
        dd if=/dev/zero of=/usr/lib/extroot.swap bs=1M count=$NS
        mkswap /usr/lib/extroot.swap

        uci -q delete fstab.swap
        uci set fstab.swap="swap"
        uci set fstab.swap.device="/usr/lib/extroot.swap"
        uci commit fstab
        /etc/init.d/fstab boot
    else
        _check_device "$1"
        mkswap "$1"

        uci -q delete fstab.swap
        uci set fstab.swap="swap"
        uci set fstab.swap.device="$1"
        uci commit fstab
        /etc/init.d/fstab boot
    fi

    echo "[*] Swap setup complete!"
    cat /proc/swaps
}

# -----------------------
# Перенос opkg-lists на extroot
# -----------------------
_set_opkg2er() {
    sed -i -e "/^lists_dir\s/s:/var/opkg-lists$:/usr/lib/opkg/lists:" /etc/opkg.conf
    opkg update
    echo "[*] opkg lists redirected to extroot"
}

# -----------------------
# Fixup extroot (переподключение)
# -----------------------
_fixup_extroot() {
    if [ -z "$1" ]; then
        echo "[*] No device specified for fixup"
        exit 1
    fi
    _check_device "$1"

    XTDEVICE="${1}1"
    UUID=$(block info "$XTDEVICE" | grep -o -e "UUID=[^ ]*" | cut -d= -f2)
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

    echo "[*] Fixup extroot complete."
}

# -----------------------
# MAIN
# -----------------------
echo "_________________________________________________"
echo "- QUICK - EXTROOT OPENWRT v0.2a full fix -"
echo "_________________________________________________"
echo

case "$1" in
    --create-extroot)
        _set_xedroot "$2"
        echo "[*] Rebooting in 5 seconds..."
        sleep 5
        reboot
        ;;
    --create-swap)
        _set_swap "$2"
        ;;
    --set-opkg2er)
        _set_opkg2er
        ;;
    --fixup-extroot)
        _fixup_extroot "$2"
        ;;
    *)
        echo
        echo "Usage: $0 <OPTIONS> [DEV]"
        echo "Options:"
        echo "  --create-extroot <dev>"
        echo "  --create-swap <dev or empty for auto>"
        echo "  --set-opkg2er"
        echo "  --fixup-extroot <dev>"
        exit 1
        ;;
esac
