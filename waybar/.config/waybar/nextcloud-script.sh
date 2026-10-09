#!/usr/bin/env bash

# What is the nextcloud item:

item=$(
    busctl --user get-property \
        org.kde.StatusNotifierWatcher \
        /StatusNotifierWatcher \
        org.kde.StatusNotifierWatcher \
        RegisteredStatusNotifierItems 2>/dev/null |
    grep -o ':[0-9.]\+/StatusNotifierItem' |
    while read -r candidate; do
        service="${candidate%/StatusNotifierItem}"

        id=$(
            busctl --user get-property \
                "$service" \
                /StatusNotifierItem \
                org.kde.StatusNotifierItem \
                Id 2>/dev/null |
            sed 's/^s "//; s/"$//'
        )

        if [[ "$id" == "Nextcloud" ]]; then
            printf '%s\n' "$candidate"
            break
        fi
    done
)

# No tray item -> client unavailable/offline
if [[ -z "$item" ]]; then
    printf '{"text":"OFFL","class":"error","tooltip":"Nextcloud client unavailable"}\n'
    exit 0
fi

service="${item%/StatusNotifierItem}"

raw=$(
    busctl --user get-property \
        "$service" \
        /StatusNotifierItem \
        org.kde.StatusNotifierItem \
        ToolTip 2>/dev/null
)

# Extract the actual tooltip message from output like:
# (sa(iiay)ss) "" 0 "Oxbacka: Last sync was successful." ""
message=$(
    printf '%s\n' "$raw" |
        sed -n 's/.*0 "\(.*\)" ""$/\1/p' |
        sed 's/[[:space:]]*$//'
)

case "$message" in

    *"Last sync was successful."*)
        printf '{"text":"SNCD","class":"synced","tooltip":"%s"}\n' "$message"
        ;;

    *"Syncing "*)
        printf '{"text":"SYNC","class":"syncing","tooltip":"%s"}\n' "$message"
        ;;

    *"Waiting to start syncing."*)
        printf '{"text":"SYNC","class":"syncing","tooltip":"%s"}\n' "$message"
        ;;

    "Account synchronization is disabled")
        printf '{"text":"PSED","class":"paused","tooltip":"%s"}\n' "$message"
        ;;

    *"offline"*|*"Offline"*)
        printf '{"text":"OFFL","class":"error","tooltip":"%s"}\n' "$message"
        ;;

    *":")
        printf '{"text":"ERR","class":"error","tooltip":"Nextcloud sync error"}\n'
        ;;

    "")
        printf '{"text":"ERR","class":"error","tooltip":"Nextcloud returned no status"}\n'
        ;;

    *)
        printf '{"text":"ERR","class":"error","tooltip":"%s"}\n' "$message"
        ;;
esac
