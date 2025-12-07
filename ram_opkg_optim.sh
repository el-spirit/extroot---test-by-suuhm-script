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

# -----------------------------
# OpenWrt ZRAM Setup Script
# -----------------------------

# Параметры
ZRAM_DEVICES=1               # количество zram устройств
ZRAM_SIZE_PERCENT=50         # размер zram в процентах от ОЗУ
SWAP_PRIORITY=100            # приоритет swap
SWAP_FILE=/dev/zram0

# Установка пакета zram (если не установлен)
opkg update
opkg install kmod-zram || echo "kmod-zram уже установлен"

# Отключаем текущий swap на zram (если есть)
swapoff ${SWAP_FILE} 2>/dev/null
echo 0 > /sys/block/zram0/reset

# Определяем размер в байтах
TOTAL_RAM=$(grep MemTotal /proc/meminfo | awk '{print $2}') # в KB
ZRAM_SIZE=$((TOTAL_RAM * ZRAM_SIZE_PERCENT / 100 * 1024))   # перевод в байты

# Настройка zram
echo $ZRAM_SIZE > /sys/block/zram0/disksize

# Форматируем под swap
mkswap ${SWAP_FILE}
swapon -p ${SWAP_PRIORITY} ${SWAP_FILE}

# Проверка
swapon -s
free -h

echo "ZRAM настроен: ${ZRAM_SIZE_PERCENT}% от RAM"

echo "=== Скрипт завершён ==="
echo "Файловый кэш усилен, логи в RAM, opkg скачивает пакеты в /tmp/opkg-download (RAM)"
