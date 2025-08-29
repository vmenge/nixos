#!/usr/bin/env bash
set -xuo pipefail

# Get current monitor resolution
resolution=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | "\(.current_mode.width)x\(.current_mode.height)"')
width=$(echo "$resolution" | cut -d'x' -f1)
height=$(echo "$resolution" | cut -d'x' -f2)

gamescopeArgs=(
    --adaptive-sync # VRR support
    --hdr-enabled
    --mangoapp # performance overlay
    --rt
    --steam
    -W "$width"
    -H "$height"
)
steamArgs=(
    -pipewire-dmabuf
    -tenfoot
)
mangoConfig=(
    cpu_temp
    gpu_temp
    ram
    vram
)
mangoVars=(
    MANGOHUD=1
    MANGOHUD_CONFIG="$(IFS=,; echo "${mangoConfig[*]}")"
)

# Check if Steam is available
if ! command -v steam &> /dev/null; then
    echo "Error: Steam not found in PATH" >&2
    exit 1
fi

export "${mangoVars[@]}"

# Launch gamescope with Steam, handling crashes gracefully
if ! gamescope "${gamescopeArgs[@]}" -- steam "${steamArgs[@]}"; then
    echo "Gamescope exited with error code $?" >&2
    exit 1
fi
