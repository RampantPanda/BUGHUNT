#!/usr/bin/env bash
set -u
fuzzel_themenu() {
    fuzzel \
        --dmenu \
        --anchor=top-right \
        --x-margin=10 \
        --y-margin=40 \
        "$@"
}

menu() {
    printf '%s\n' "$@" |
        fuzzel_power --prompt="PROMPTIA > "
}

message() {
    printf '%s\n' "$1" |
        fuzzel_power --prompt="PROMPTIA (message) >>>>>>>>>>>> " >/dev/null
}
