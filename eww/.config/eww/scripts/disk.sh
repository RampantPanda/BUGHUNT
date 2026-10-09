#!/usr/bin/env bash

mount="$1"
label="$2"

used=$(df -BG --output=used "$mount" | tail -1 | tr -dc '0-9')
avail=$(df -BG --output=avail "$mount" | tail -1 | tr -dc '0-9')

printf "%s %sG/%sG\n" "$label" "$used" "$avail"
