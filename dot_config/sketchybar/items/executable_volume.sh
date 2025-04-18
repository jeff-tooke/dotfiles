#!/bin/sh

volume_slider=(
  script="$PLUGIN_DIR/volume.sh"
  updates=on
  label.drawing=off
  icon.drawing=off
  slider.highlight_color=$MACCHIATO_BLUE
  slider.background.height=5
  slider.background.corner_radius=3
  slider.background.color=$LABEL_COLOR
  slider.knob=􀀁
  slider.knob.drawing=on
)

volume_icon=(
  click_script="$PLUGIN_DIR/volume_click.sh"
  padding_left=10
  icon=$VOLUME_100
  icon.width=0
  icon.align=left
  icon.color=$GREY
  icon.font="$FONT:Bold:16.0"
  label.width=25
  label.align=left
  label.font="$FONT:Bold:16.0"
)

status_bracket=(
  background.color=$BAR_COLOR
  background.border_color=$BAR_COLOR
)

sketchybar --add slider volume right            \
           --set volume "${volume_slider[@]}"   \
           --subscribe volume volume_change     \
                              mouse.clicked     \
           --add item volume_icon right         \
           --set volume_icon "${volume_icon[@]}"

sketchybar --add bracket status volume_icon \
           --set status "${status_bracket[@]}"

