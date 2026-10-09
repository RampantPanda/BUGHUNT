#!/usr/bin/env bash

line=$(nmcli | grep -m1 '^proton0:')

if [[ -n "$line" ]]; then
    awk '{printf "WRGD > %s\n", $5}' <<< "$line"
else
    printf "WRGD NA\n"
fi
