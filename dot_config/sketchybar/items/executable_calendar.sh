#!/bin/bash

sketchybar --add item clock right \
           --set clock script="$PLUGIN_DIR/clock.sh" \
                        update_freq=60 \
                        label.color=$LABEL_COLOR \
			background.color=$TRANSPARENT
