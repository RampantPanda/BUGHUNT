#!/usr/bin/env bash

free -m | awk '
/Swap:/ {
    total = $2
    used  = $3
}
END {
    if (total > 0)
        printf "%.0f%%\n", (used / total) * 100
    else
        print "0%"
}
'
