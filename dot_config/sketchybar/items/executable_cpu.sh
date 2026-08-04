#!/bin/bash

cpu=(
  icon=
  icon.font="Symbols Nerd Font:Regular:14.0"
  label=?
  padding_right=10
  script="$PLUGIN_DIR/cpu.sh"
  update_freq=5
)

sketchybar  --add item cpu right   \
           --set cpu "${cpu[@]}" \
           --subscribe cpu system_woke


