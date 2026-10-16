#!/usr/bin/env bash

server="pekka@oxbacka"

stats=$(
    ssh \
      -o BatchMode=yes \
      -o ConnectTimeout=2 \
      "$server" \
      'printf "%s %s\n" "$(docker ps -q | wc -l)" "$(docker ps -aq | wc -l)"' \
      2>/dev/null
)

if [[ -z "$stats" ]]; then
    printf "DOCKER OFFL\n"
    exit
fi

read -r running total <<< "$stats"

printf "DOCKER %s/%s\n" "$running" "$total"
