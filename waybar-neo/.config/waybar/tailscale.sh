#!/usr/bin/env bash

set -u

case "${1:-status}" in
    toggle)
        state=$(tailscale status --json 2>/dev/null |
            jq -r '.BackendState // "Stopped"')

        if [[ "$state" == "Running" ]]; then
            tailscale down
        else
            tailscale up
        fi
        exit $?
        ;;
esac

# Get Tailscale IPv4 address
ip=$(tailscale ip -4 2>/dev/null || true)

# Verify Tailscale is actually connected
state=$(tailscale status --json 2>/dev/null |
    jq -r '.BackendState // "Stopped"')

if [[ "$state" == "Running" && -n "$ip" ]]; then
    jq -nc --arg ip "$ip" '{
        text: "󰌘",
        tooltip: ("TAILSCALE CONNECTED\nIP: " + $ip),
        class: "connected"
    }'
else
    jq -nc --arg state "$state" '{
        text: "󰌘",
        tooltip: ("TAILSCALE OFFLINE\nState: " + $state),
        class: "disconnected"
    }'
fi
