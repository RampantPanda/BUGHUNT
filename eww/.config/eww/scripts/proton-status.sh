#!/usr/bin/env bash
nmcli | grep proton  | awk 'NR ==1 {printf "WRGD: %s\n", $5}' 
