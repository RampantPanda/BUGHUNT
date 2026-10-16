#!/usr/bin/env bash

bat=$(find /sys/class/power_supply -maxdepth 1 -name 'BAT*' | head -1)

[[ -z "$bat" ]] && exit 0

capacity=$(cat "$bat/capacity")
status=$(cat "$bat/status")

case "$status" in
    Charging)     state="CHRG" ;;
    Discharging)  state="DSGH" ;;
    Full)         state="FULL" ;;
    *)            state="$status" ;;
esac

printf "%s %s%%\n" "$state" "$capacity"
