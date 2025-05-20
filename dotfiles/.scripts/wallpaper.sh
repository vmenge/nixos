#!/usr/bin/env bash

if [ $# -lt 1 ] || [ ! -d "$1" ]; then
  printf "Usage: %s DIRECTORY\n" "$0"
  exit 1
fi

DIR="$1"
RESIZE_TYPE="crop"
export SWWW_TRANSITION_FPS="${SWWW_TRANSITION_FPS:-60}"
export SWWW_TRANSITION_STEP="${SWWW_TRANSITION_STEP:-2}"

# pick one random file
img=$(find "$DIR" -type f | shuf -n1)

# apply to each display
for d in $(swww query | cut -d: -f1); do
  swww img --resize "$RESIZE_TYPE" --outputs "$d" "$img"
done
