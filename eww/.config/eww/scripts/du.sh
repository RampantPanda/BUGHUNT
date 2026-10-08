#!/usr/bin/env bash

df -BG / | awk '
    NR == 2 {
        used_pct = $5
        gsub(/G/, "", used_pct)
        printf "ROOT %s\n", used_pct
    }
'
