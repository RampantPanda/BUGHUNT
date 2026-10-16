#!/usr/bin/env bash

printf 'FAILED SYSTEMD UNITS\n\n'
systemctl --failed --no-pager

printf '\nFAILED USER UNITS\n\n'
systemctl --user --failed --no-pager

printf '\n'
read -rp 'Press Enter to close...'
