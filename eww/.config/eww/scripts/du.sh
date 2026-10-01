#!/usr/bin/env bash
df -BG | awk 'NR ==2 {
        printf "DISK > %s / %s \n", $4, $2
        }'
