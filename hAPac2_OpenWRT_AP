#!/bin/sh
# Скрипт превращает OpenWrt в точку доступа с статическим IP 172.16.0.10

echo "=== Отключаем DHCP и firewall ==="
/etc/init.d/dnsmasq stop
/etc/init.d/dnsmasq disable
/etc/init.d/firewall stop
/etc/init.d/firewall disable

echo "=== Удаляем старый WAN ==="
uci delete network.wan 2>/dev/null
uci delete network.wan6 2>/dev/null
uci commit network

echo "=== Настраиваем мост br-lan со всеми портами ==="
uci set network.lan.device='br-lan'
uci set network.lan.proto='static'
uci set network.lan.ipaddr='172.16.0.10'
uci set network.lan.netmask='255.255.255.0'
uci set network.@device[0].ports='lan1 lan2 lan3 lan4 wan'
uci commit network

echo "=== Перезапускаем сеть ==="
/etc/init.d/network restart

echo "=== Настройка завершена! ==="
echo "IP роутера: 172.16.0.10"
