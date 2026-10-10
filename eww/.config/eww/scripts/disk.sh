#!/usr/bin/env bash

mount="$1"

df --output=pcent "$mount" | tail -1 | tr -d ' '
