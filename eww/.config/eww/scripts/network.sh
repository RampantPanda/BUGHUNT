#!/usr/bin/env bash

iface=$(ip route | awk '/default/ {print $5; exit}')

if [[ -z "$iface" ]]; then
    printf "NET OFFLINE\n"
    exit
fi

ip=$(ip -4 addr show "$iface" |
    awk '/inet / {sub(/\/.*/, "", $2); print $2; exit}')

type=$(cat "/sys/class/net/$iface/type" 2>/dev/null)

if [[ "$iface" == wl* ]]; then
    ssid=$(nmcli -t -f ACTIVE,SSID dev wifi |
        awk -F: '$1=="yes" {print $2; exit}')

    printf "WIFI %s | %s\n" "$ssid" "$ip"
else
    printf "ETH %s | %s\n" "$iface" "$ip"
fi
