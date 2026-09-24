#!/usr/bin/env bash

if ! pgrep -x gtklock >/dev/null; then
    gtklock --daemonize
fi
