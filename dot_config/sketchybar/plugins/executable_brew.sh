#!/bin/bash

source "$CONFIG_DIR/icons.sh"
source "$CONFIG_DIR/colors.sh"

COUNT="$(brew outdated | wc -l | tr -d ' ')"

COLOR=$WHITE

case "$COUNT" in
  0) COLOR=$GREEN; COUNT=􀆅  ICON=$BREW
  ;;
  [1-9]) COLOR=$YELLOW ICON=$BREW
  ;;
  1[0-9]) COLOR=$ORANGE ICON=$BREW
  ;;
  *) COLOR=$RED ICON=$BREW
  ;;
esac

sketchybar --set $NAME label=$COUNT icon=$ICON icon.color=$COLOR
