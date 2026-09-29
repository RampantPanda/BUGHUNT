#!/usr/bin/env bash

# ------------------------------------------------------------
# Nostromo gtklock status collector
# ------------------------------------------------------------

escape_markup() {
    sed \
        -e 's/&/\&amp;/g' \
        -e 's/</\&lt;/g' \
        -e 's/>/\&gt;/g'
}

field() {
    local name="$1"
    local value="$2"

    printf '<span foreground="#8d937f">%-30s</span><span foreground="#d2b45b">%s</span>\n' \
        "$name" "$value"
}

# ------------------------------------------------------------
# Time / date
# ------------------------------------------------------------

systemtime=$(date '+%H:%M:%S')
systemdate=$(date '+%Y-%m-%d')

# ------------------------------------------------------------
# Host
# ------------------------------------------------------------

hostname=$(
    hostname |
        tr '[:lower:]' '[:upper:]' |
        escape_markup
)

# ------------------------------------------------------------
# Uptime
# ------------------------------------------------------------

uptime_seconds=$(cut -d. -f1 /proc/uptime)

days=$(( uptime_seconds / 86400 ))
hours=$(( (uptime_seconds % 86400) / 3600 ))
minutes=$(( (uptime_seconds % 3600) / 60 ))

if (( days > 0 )); then
    uptime_text=$(printf '%d DAYS, %02d:%02d' "$days" "$hours" "$minutes")
else
    uptime_text=$(printf '%02d:%02d' "$hours" "$minutes")
fi

# ------------------------------------------------------------
# Last system update
# ------------------------------------------------------------

last_update_timestamp=$(
    grep '\[ALPM\] upgraded ' /var/log/pacman.log 2>/dev/null |
        tail -n1 |
        sed 's/^\[\([^]]*\)\].*/\1/'
)

if [[ -n "$last_update_timestamp" ]]; then

    last_update_epoch=$(date -d "$last_update_timestamp" +%s 2>/dev/null)
    now_epoch=$(date +%s)

    if [[ -n "$last_update_epoch" ]]; then
        update_days=$(( (now_epoch - last_update_epoch) / 86400 ))
    else
        update_days="?"
    fi
else
    update_days="?"
fi

# ------------------------------------------------------------
# Approximate installation date
# ------------------------------------------------------------

pacman_first_timestamp=""

for logfile in $(ls -tr /var/log/pacman.log* 2>/dev/null); do

    if [[ "$logfile" == *.gz ]]; then
        line=$(gzip -cd "$logfile" 2>/dev/null | head -n1)
    else
        line=$(head -n1 "$logfile" 2>/dev/null)
    fi

    if [[ "$line" =~ ^\[([^]]+)\] ]]; then
        pacman_first_timestamp="${BASH_REMATCH[1]}"
        break
    fi
done

if [[ -n "$pacman_first_timestamp" ]]; then
    install_date=$(date -d "$pacman_first_timestamp" '+%Y-%m-%d' 2>/dev/null)
else
    install_date="UNKNOWN"
fi

# ------------------------------------------------------------
# Network
# ------------------------------------------------------------

ssid=$(
    nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null |
        sed -n 's/^yes://p' |
        head -n1
)

if [[ -z "$ssid" ]]; then
    network="DISCONNECTED"
else
    network=$(
        printf '%s' "$ssid" |
            tr '[:lower:]' '[:upper:]' |
            escape_markup
    )
fi

# ------------------------------------------------------------
# Root filesystem free space
# ------------------------------------------------------------

disk_free=$(
    df -P / |
        awk 'NR == 2 {
            gsub("%","",$5)
            printf "%d%% FREE", 100-$5
        }'
)

# ------------------------------------------------------------
# Battery
# ------------------------------------------------------------

battery_dir=$(
    find /sys/class/power_supply \
        -maxdepth 1 \
        -type l \
        -name 'BAT*' \
        2>/dev/null |
        head -n1
)

if [[ -n "$battery_dir" ]]; then

    capacity=$(cat "$battery_dir/capacity" 2>/dev/null)

    status=$(
        cat "$battery_dir/status" 2>/dev/null |
            tr '[:lower:]' '[:upper:]'
    )

    battery="${capacity}% / ${status}"

else
    battery="NOT PRESENT"
fi

# ------------------------------------------------------------
# Output
# ------------------------------------------------------------

field "SYSTEMNAME"      		"$hostname"
field "SYSTEMTIME"     			"$systemtime"
field "SYSTEMDATE"      		"$systemdate"
field "UPTIME"					"$uptime_text"
if [[ "$update_days" =~ ^[0-9]+$ ]] && (( update_days > 10 )); then
    printf '<span foreground="#8d937f">%-18s</span><span foreground="#d34b42">%s DAYS</span>\n' \
        "SYSTEM UPDATE DATE" "$update_days"
else
    field "SYSTEM UPDATE DATE" "${update_days} DAYS"
fi
field "SYSTEM INSTALL DATE" "$install_date"
field "NETWORK"          "$network"
field "DISK STATUS"      "$disk_free"
field "BATTERY"          "$battery"
field "CREW"			 "EXPENDABLE"
