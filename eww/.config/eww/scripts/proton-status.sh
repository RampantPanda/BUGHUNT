#!/usr/bin/env bash

line=$(nmcli | grep -m1 '^proton0:')

if [[ -n "$line" ]]; then
    awk '{printf "%s\n", $5}' <<< "$line"
else
    printf " NA\n"
fi
