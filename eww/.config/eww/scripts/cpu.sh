#!/usr/bin/env bash

read -r cpu user nice system idle iowait irq softirq steal _ < /proc/stat

prev_idle=$((idle + iowait))
prev_total=$((user + nice + system + idle + iowait + irq + softirq + steal))

sleep 0.5

read -r cpu user nice system idle iowait irq softirq steal _ < /proc/stat

idle_now=$((idle + iowait))
total_now=$((user + nice + system + idle + iowait + irq + softirq + steal))

idle_delta=$((idle_now - prev_idle))
total_delta=$((total_now - prev_total))

usage=$((100 * (total_delta - idle_delta) / total_delta))

printf 'CPU %d \n' "$usage"
