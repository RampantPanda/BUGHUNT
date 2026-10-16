ip route show default | awk '{printf "IP %s\nvia %s\n", $9, $3}'
