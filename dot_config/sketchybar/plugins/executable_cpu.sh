#!/usr/bin/env bash

CPU=$(top -l 2 -n 0 | grep "CPU usage" | tail -1 | awk '{print $3}' | tr -d '%' | cut -d. -f1)

if [[ -z "$CPU" ]]; then
    CPU=0
fi

if (( CPU < 50 )); then
    COLOR=0xffa6da95     # green
elif (( CPU < 80 )); then
    COLOR=0xffeed49f     # yellow
else
    COLOR=0xffed8796     # red
fi


sketchybar --set "$NAME" \
    label="${CPU}%" \
    icon.color="$COLOR" \
    label.color="$COLOR"
