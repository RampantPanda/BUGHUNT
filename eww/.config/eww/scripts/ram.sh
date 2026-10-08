#!/usr/bin/env bash

awk '
/MemTotal:/     { total=$2 }
/MemAvailable:/ { avail=$2 }
END {
    used = total - avail
    printf "%.0f % \n", (used / total) * 100
}
' /proc/meminfo
