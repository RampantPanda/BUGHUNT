free -h | grep Mem | awk 'NR==1 {printf "RAM %s / %s\n", $2, $7 }'
