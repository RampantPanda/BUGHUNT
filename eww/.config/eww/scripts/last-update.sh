#!/usr/bin/env bash

date_string=$(
    grep '\[ALPM\] upgraded ' /var/log/pacman.log |
    tail -1 |
    sed -n 's/^\[\([^]]*\)\].*/\1/p'
)

[[ -z "$date_string" ]] && exit 0

last=$(date -d "$date_string" +%s)
now=$(date +%s)

days=$(( (now - last) / 86400 ))

printf "%s\n" "$days"
