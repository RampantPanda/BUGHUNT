#!/usr/bin/env bash

read -r total used <<< "$(free -m | awk '/Swap:/ {print $2, $3}')"

(( used == 0 )) && exit 0

printf "SWAP %sM/%sM\n" "$used" "$total"
