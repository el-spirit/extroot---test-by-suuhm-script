#!/bin/sh
#
# OpenWrt Seamless Wi-Fi Roaming for 2 Routers
# R1 = DHCP, R2 = AP
#

SSID="ChikaWiFi"
PASSWORD="irdiS0066"
COUNTRY="RU"

# ----------------------------
# Интерактивный выбор типа роутера
# ----------------------------
echo "Выберите тип роутера для настройки:"
echo "1) R1 - основной роутер с DHCP"
echo "2) R2 - второстепенный роутер в режиме AP"
read -p "Введите 1 или 2: " ROUTER_CHOICE

if [ "$ROUTER_CHOICE" = "1" ]; then
    ROUTER_TYPE="R1"
elif [ "$ROUTER_CHOICE" = "2" ]; then
    ROUTER_TYPE="R2"
else
    echo "Неверный выбор! Выход..."
    exit 1
fi

# ----------------------------
# Проверка пакетов wpad
# ----------------------------
echo "[*] Проверяем wpad для поддержки 802.11r/k/v..."
INSTALLED_WPAD=$(opkg list-installed | grep -E "wpad(-basic)?(-mbedtls)?(-openssl)?(-wolfssl)?|wpad-mini")

if [ -n "$INSTALLED_WPAD" ]; then
    echo "[*] Найдено установленное wpad: $INSTALLED_WPAD"
    echo "[*] Удаляем урезанные версии..."
    opkg remove -y wpad-basic wpad-basic-mbedtls wpad-basic-openssl wpad-basic-wolfssl wpad-mini
fi

echo "[*] Устанавливаем полный wpad..."
opkg update
opkg install -y wpad

# ----------------------------
# Настройка Wi-Fi
# ----------------------------
echo "[*] Configuring $ROUTER_TYPE Wi-Fi..."

# Настройка каналов и NASID
if [ "$ROUTER_TYPE" = "R1" ]; then
    RADIO0_CH=1    # 2.4GHz
    RADIO1_CH=36   # 5GHz
    NASID_24="ChikaWiFi_24G_R1"
    NASID_5="ChikaWiFi_5G_R1"
else
    RADIO0_CH=6
    RADIO1_CH=44
    NASID_24="ChikaWiFi_24G_R2"
    NASID_5="ChikaWiFi_5G_R2"
fi

# 2.4GHz
uci set wireless.radio0.disabled='0'
uci set wireless.radio0.country="$COUNTRY"
uci set wireless.radio0.channel="$RADIO0_CH"
uci set wireless.@wifi-iface[0].device='radio0'
uci set wireless.@wifi-iface[0].network='lan'
uci set wireless.@wifi-iface[0].mode='ap'
uci set wireless.@wifi-iface[0].ssid="$SSID"
uci set wireless.@wifi-iface[0].encryption='psk2'
uci set wireless.@wifi-iface[0].key="$PASSWORD"
uci set wireless.@wifi-iface[0].ieee80211r='1'
uci set wireless.@wifi-iface[0].ft_over_ds='1'
uci set wireless.@wifi-iface[0].ft_psk_generate_local='1'
uci set wireless.@wifi-iface[0].ieee80211k='1'
uci set wireless.@wifi-iface[0].ieee80211v='1'
uci set wireless.@wifi-iface[0].nasid="$NASID_24"

# 5GHz
uci set wireless.radio1.disabled='0'
uci set wireless.radio1.country="$COUNTRY"
uci set wireless.radio1.channel="$RADIO1_CH"
uci set wireless.@wifi-iface[1].device='radio1'
uci set wireless.@wifi-iface[1].network='lan'
uci set wireless.@wifi-iface[1].mode='ap'
uci set wireless.@wifi-iface[1].ssid="$SSID"
uci set wireless.@wifi-iface[1].encryption='psk2'
uci set wireless.@wifi-iface[1].key="$PASSWORD"
uci set wireless.@wifi-iface[1].ieee80211r='1'
uci set wireless.@wifi-iface[1].ft_over_ds='1'
uci set wireless.@wifi-iface[1].ft_psk_generate_local='1'
uci set wireless.@wifi-iface[1].ieee80211k='1'
uci set wireless.@wifi-iface[1].ieee80211v='1'
uci set wireless.@wifi-iface[1].nasid="$NASID_5"

# ----------------------------
# Применение
# ----------------------------
echo "[*] Committing Wi-Fi configuration..."
uci commit wireless

echo "[*] Reloading Wi-Fi..."
wifi reload

echo "[*] Wi-Fi setup complete for $ROUTER_TYPE!"
echo "SSID: $SSID"
echo "Password: $PASSWORD"
echo "2.4GHz NASID: $NASID_24, Channel: $RADIO0_CH"
echo "5GHz NASID: $NASID_5, Channel: $RADIO1_CH"
