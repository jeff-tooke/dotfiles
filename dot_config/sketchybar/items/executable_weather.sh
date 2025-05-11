#!/bin/bash

source "$CONFIG_DIR/colors.sh"

weather=(
  padding_right=7
  script="$PLUGIN_DIR/weather.sh"
  update_freq=600
)

sketchybar --add item weather right \
           --set weather "${weather[@]}" \
           --subscribe weather system_woke
