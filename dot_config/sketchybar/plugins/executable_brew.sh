#!/bin/bash

source "$CONFIG_DIR/colors.sh"

COUNT="$(brew outdated | wc -l | tr -d ' ')"

COLOR=$RED

case "$COUNT" in
  [1-9]|1[0-2]) COLOR=$YELLOW ;;
  1[3-9]|2[0-5]) COLOR=$YELLOW ;;
  0) COLOR=$GREEN; COUNT=􀆅 ;;
esac

sketchybar --set $NAME label=$COUNT icon.color=$COLOR
