#!/usr/bin/env bash

awk '{
    printf "%.2f\n", $1 / 86400
}' /proc/uptime
