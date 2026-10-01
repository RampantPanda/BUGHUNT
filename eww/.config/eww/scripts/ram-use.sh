free -h --giga | grep Mem | awk 'NR==1 {printf "RAM > %s / %s\n", $7, $2 }'
