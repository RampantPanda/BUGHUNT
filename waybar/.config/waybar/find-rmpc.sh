#!/usr/bin/env bash

id="$(
    mmsg get all-clients |
    jq -r '.. | objects | select(.title? == "rmpc") | .id?' |
    head -n1
)"

if [[ -n "$id" && "$id" != "null" ]]; then
    mmsg dispatch focusid client,"$id"
fi
