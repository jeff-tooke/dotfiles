#!/bin/bash

source "$CONFIG_DIR/colors.sh"

COUNT="$(brew outdated | wc -l | tr -d ' ')"

COLOR=$RED

case "$COUNT" in
  [1-9]) COLOR=$YELLOW ;;
  1[0-9]) COLOR=$ORANGE;;
  *) COLOR=$RED;;
  0) COLOR=$GREEN; COUNT=􀆅 ;;
esac

sketchybar --set $NAME label=$COUNT icon.color=$COLOR
