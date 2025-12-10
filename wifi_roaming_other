#!/bin/sh
#
# OpenWrt Seamless Wi-Fi Roaming for 2 Routers
# R1 = DHCP, R2 = AP
#

SSID="Cudy"
PASSWORD="88888888"
COUNTRY="RU"

# ----------------------------
# Интерактивный выбор роутера
# ----------------------------
echo "Выберите тип роутера для настройки:"
echo "1) R1 - основной роутер с DHCP"
echo "2) R2 - второстепенный роутер в режиме AP"
read -r ROUTER_CHOICE

case "$ROUTER_CHOICE" in
    1) ROUTER_TYPE="R1" ;;
    2) ROUTER_TYPE="R2" ;;
    *)
        echo "Неверный выбор! Выход..."
        exit 1
        ;;
esac

echo "[*] Configuring $ROUTER_TYPE Wi-Fi..."

# ----------------------------
# Проверка и установка wpad
# ----------------------------
echo "[*] Проверяем wpad для поддержки 802.11r/k/v..."
WPAD_INSTALLED=$(opkg list-installed | grep wpad)
if echo "$WPAD_INSTALLED" | grep -qE "wpad-basic|wpad-mini"; then
    echo "[*] Удаляем урезанные версии..."
    opkg remove wpad-basic wpad-basic-mbedtls wpad-mini 2>/dev/null
fi

echo "[*] Устанавливаем полный wpad..."
opkg update
opkg install wpad

# ----------------------------
# Настройка каналов и NASID
# ----------------------------
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

# ----------------------------
# Настройка Wi-Fi 2.4GHz
# ----------------------------
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

# ----------------------------
# Настройка Wi-Fi 5GHz
# ----------------------------
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
# Применение настроек
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
