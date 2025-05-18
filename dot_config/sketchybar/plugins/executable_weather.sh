#!/bin/bash

# Set your location and coordinates
LOCATION=$(corelocationcli --format %locality)
LAT=$(corelocationcli --format %latitude)
LON=$(corelocationcli --format %longtitude)

# Get weather data: Location + Condition + Temp
WEATHER_INFO=$(curl -s "https://wttr.in/${LOCATION}?format=%l:+%c+%t")

# Extract parts
LOCATION_NAME=$(echo "$WEATHER_INFO" | cut -d: -f1)
CONDITION=$(echo "$WEATHER_INFO" | awk -F: '{print $2}' | awk '{$NF=""; print $0}' | xargs)
TEMP=$(echo "$WEATHER_INFO" | awk '{print $NF}')
TEMP=${TEMP#+}

# Get sunrise and sunset times in UTC
SUN_API=$(curl -s "https://api.sunrise-sunset.org/json?lat=${LAT}&lng=${LON}&formatted=0")
SUNRISE=$(echo "$SUN_API" | jq -r '.results.sunrise')
SUNSET=$(echo "$SUN_API" | jq -r '.results.sunset')

# Convert times to seconds since epoch (local time)
CURRENT_TIME=$(date +%s)
SUNRISE_EPOCH=$(date -j -f "%Y-%m-%dT%H:%M:%S%z" "$(echo "$SUNRISE" | sed -E 's/([+-][0-9]{2}):([0-9]{2})/\1\2/')" +%s)
SUNSET_EPOCH=$(date -j -f "%Y-%m-%dT%H:%M:%S%z" "$(echo "$SUNSET" | sed -E 's/([+-][0-9]{2}):([0-9]{2})/\1\2/')" +%s)

# Determine if it's currently night
IS_NIGHT=false
if [[ $CURRENT_TIME -lt $SUNRISE_EPOCH || $CURRENT_TIME -gt $SUNSET_EPOCH ]]; then
    IS_NIGHT=true
fi

# Fix "Sunny" -> "Clear" if it's night
if [[ "$CONDITION" == *Sunny* ]] && [[ $IS_NIGHT == true ]]; then
    CONDITION="Clear"
fi

# Choose icon based on condition + day/night
if [[ $IS_NIGHT == true ]]; then
    case "$CONDITION" in
        *Clear*)
            ICON="🌙"
            ;;
        *Partly*|*Cloudy*)
            ICON="☁️"
            ;;
        *Overcast*|*Fog*|*Mist*)
            ICON="🌫️"
            ;;
        *Rain*|*Drizzle*)
            ICON="🌧️"
            ;;
        *Thunderstorm*)
            ICON="⛈️"
            ;;
        *Snow*|*Sleet*)
            ICON="❄️"
            ;;
        *Wind*|*Breeze*)
            ICON="💨"
            ;;
        *)
            ICON="🌡️"
            ;;
    esac
else
    case "$CONDITION" in
        *Sunny*|*Clear*)
            ICON="☀️"
            ;;
        *Partly*|*Cloudy*)
            ICON="⛅"
            ;;
        *Overcast*|*Fog*|*Mist*)
            ICON="🌫️"
            ;;
        *Rain*|*Drizzle*)
            ICON="🌧️"
            ;;
        *Thunderstorm*)
            ICON="⛈️"
            ;;
        *Snow*|*Sleet*)
            ICON="❄️"
            ;;
        *Wind*|*Breeze*)
            ICON="💨"
            ;;
        *)
            ICON="🌡️"
            ;;
    esac
fi

# Build label
LABEL="$LOCATION_NAME: $TEMP $CONDITION"
#LABEL="$LOCATION_NAME: $TEMP $ICON $CONDITION"

# Update the item
sketchybar --set $NAME label="$LABEL"
