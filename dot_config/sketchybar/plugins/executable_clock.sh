#!/bin/sh

LC_TIME=en_US.UTF-8 label="$(date '+%d-%m-%Y  %I:%M%p' | sed 's/\.//g' | tr '[:lower:]' '[:upper:]')"
sketchybar --set "$NAME" label="$label"

