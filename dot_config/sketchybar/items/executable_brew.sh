#!/bin/bash

brew=(
  icon=􀐛
  label=?
  padding_right=10
  script="$PLUGIN_DIR/brew.sh"
  update_freq=300
)

sketchybar  --add item brew right   \
           --set brew "${brew[@]}" \
           --subscribe brew system_woke


