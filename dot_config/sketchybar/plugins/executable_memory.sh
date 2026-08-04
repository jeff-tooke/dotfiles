#!/usr/bin/env bash

PAGE_SIZE=$(pagesize)

VM_STAT=$(vm_stat)

ACTIVE=$(echo "$VM_STAT" | awk '/Pages active/ {print $3}' | tr -d '.')
WIRED=$(echo "$VM_STAT" | awk '/Pages wired down/ {print $4}' | tr -d '.')
COMPRESSED=$(echo "$VM_STAT" | awk '/Pages occupied by compressor/ {print $5}' | tr -d '.')

# Fallback for systems without memory compression
[[ -z "$COMPRESSED" ]] && COMPRESSED=0

USED=$((WIRED + ACTIVE + COMPRESSED))

TOTAL=$(sysctl -n hw.memsize)

USED_BYTES=$((USED * PAGE_SIZE))

MEM=$((USED_BYTES * 100 / TOTAL))


if (( MEM < 50 )); then
    COLOR=0xffa6da95
elif (( MEM < 80 )); then
    COLOR=0xffeed49f
else
    COLOR=0xffed8796
fi


sketchybar --set "$NAME" \
    label="${MEM}%" \
    icon.color="$COLOR" \
    label.color="$COLOR"
