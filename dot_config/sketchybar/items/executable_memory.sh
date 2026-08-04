
#!/bin/bash

memory=(
  icon=
  icon.font="Symbols Nerd Font:Regular:14.0"
  label=?
  padding_right=10
  script="$PLUGIN_DIR/memory.sh"
  update_freq=5
)

sketchybar  --add item memory right   \
           --set memory "${memory[@]}" \
           --subscribe memory system_woke


