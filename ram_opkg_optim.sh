#!/bin/sh
# Скрипт для полной файловой буферизации и хранения в RAM

echo "=== Настройка VFS cache и swappiness ==="
# Увеличиваем удержание кэша в RAM
echo 50 > /proc/sys/vm/vfs_cache_pressure
# Минимальное использование swap
echo 0 > /proc/sys/vm/swappiness

echo "=== Перенос логов в RAM ==="
uci set system.@system[0].log_file='/tmp/system.log'
uci commit system
/etc/init.d/log restart

echo "=== Настройка opkg для скачивания в RAM ==="
# Проверяем наличие /tmp/opkg-download
if [ ! -d /tmp/opkg-download ]; then
    mkdir -p /tmp/opkg-download
fi

# Создаём сервис для автосоздания каталога при старте
cat << 'EOF' > /etc/init.d/opkgtmp
#!/bin/sh /etc/rc.common
START=11

start() {
    mkdir -p /tmp/opkg-download
}
EOF

chmod +x /etc/init.d/opkgtmp
/etc/init.d/opkgtmp enable
/etc/init.d/opkgtmp restart

# Настраиваем opkg
OPKG_CONF="/etc/opkg.conf"
# Добавляем или заменяем строку tmp_dir
grep -q "^option tmp_dir" $OPKG_CONF && \
    sed -i "s|^option tmp_dir.*|option tmp_dir /tmp/opkg-download|" $OPKG_CONF || \
    echo "option tmp_dir /tmp/opkg-download" >> $OPKG_CONF

# Проверяем, что установка идёт в корень
grep -q "^dest root /$" $OPKG_CONF || echo "dest root /" >> $OPKG_CONF

echo "=== Обновляем список пакетов ==="
opkg update

# -------------------------------------------------
# POSIX-compliant OpenWrt ZRAM + LuCI Setup Script
# -------------------------------------------------

# --- Настройки ---
ZRAM_DEVICES=1             # количество zram устройств
ZRAM_SIZE_PERCENT=50       # размер zram в % от RAM
SWAP_PRIORITY=100          # приоритет swap
ZRAM_DEVICE="/dev/zram0"

echo "[*] Обновляем пакеты..."
opkg update
opkg install kmod-zram || echo "[*] kmod-zram уже установлен"

# --- Настройка ZRAM ---
echo "[*] Настраиваем ZRAM..."

# Отключаем существующий swap и сбрасываем zram
if [ -e "$ZRAM_DEVICE" ]; then
    swapoff "$ZRAM_DEVICE" 2>/dev/null
    echo 0 > /sys/block/zram0/reset
fi

# Определяем размер ZRAM в байтах
TOTAL_RAM=$(awk '/MemTotal/ {print $2}' /proc/meminfo)   # в KB
ZRAM_SIZE=$(( TOTAL_RAM * ZRAM_SIZE_PERCENT / 100 * 1024 )) # в байтах

swapoff /dev/zram0
echo 0 > /sys/block/zram0/reset

# Настраиваем размер
echo "$ZRAM_SIZE" > /sys/block/zram0/disksize

# Форматируем как swap и включаем
mkswap "$ZRAM_DEVICE"
swapon -p "$SWAP_PRIORITY" "$ZRAM_DEVICE"

# --- Проверка ---
echo "[*] Проверка swap:"
cat /proc/swaps
free -h

echo "[*] ZRAM настроен: ${ZRAM_SIZE_PERCENT}% от RAM"

# --- Автозагрузка при старте ---
RC_LOCAL="/etc/rc.local"
if ! grep -q "setup_zram.sh" "$RC_LOCAL"; then
    echo "[*] Добавляем запуск скрипта при старте..."
    sed -i -e '$i /root/setup_zram.sh\n' "$RC_LOCAL"
fi

echo "ZRAM настроен: ${ZRAM_SIZE_PERCENT}% от RAM"

echo "=== Скрипт завершён ==="
echo "Файловый кэш усилен, логи в RAM, opkg скачивает пакеты в /tmp/opkg-download (RAM)"
