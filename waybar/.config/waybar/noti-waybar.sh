#!/usr/bin/env bash

swaync-client -swb | while IFS= read -r line; do
    # Ignore empty lines
    [[ -z "$line" ]] && continue

    class=$(printf '%s\n' "$line" | jq -r '.class')
    count=$(printf '%s\n' "$line" | jq -r '.text')

    case "$class" in
        notification)
            text="!!!"
            tooltip="SYSTEM MESSAGES AVAILABLE: $count"
            ;;
        none)
            text="000"
            tooltip="NO SYSTEM MESSAGES. SYSTEM STANDBY."
            ;;
        dnd-notification)
            text="-!-"
            tooltip="SYSTEM MESSAGES AVAILABLE: $count"
            ;;
        dnd-none)
            text="---"
            tooltip="SYSTEM MESSAGES DISABLED"
            ;;
        *)
            text="???"
            tooltip="SYSTEM MESSAGE SYSTEM ERROR"
            ;;
    esac

    printf '%s\n' "$line" |
        jq -c \
    --arg text "$text" \
    --arg tooltip "$tooltip" \
    '.text = $text | .tooltip = $tooltip'
done
