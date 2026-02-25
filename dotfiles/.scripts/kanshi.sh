#!/usr/bin/env bash

kanshi_save() {
  local config_file="$HOME/.config/kanshi/config"

  local monitors
  monitors=$(hyprctl monitors -j 2>/dev/null)

  if [[ -z "$monitors" ]]; then
    notify-send "Kanshi Error" "Could not get monitor info from hyprctl" 2>/dev/null || true
    echo "Error: could not get monitor info from hyprctl" >&2
    return 1
  fi

  local profile_name
  profile_name=$(echo "$monitors" | jq -r '[.[] | "\(.make) \(.model)" | gsub("[^a-zA-Z0-9]"; "")] | sort | join("_")')

  local outputs
  outputs=$(echo "$monitors" | jq -r '.[] |
    (if .serial == "" or .serial == null then "Unknown" else .serial end) as $serial |
    "  output \"\(.make) \(.model) \($serial)\" mode \(.width)x\(.height)@\(.refreshRate * 1000 | round | . / 1000)Hz position \(.x),\(.y) scale \(.scale)"')

  # Remove existing profile with the same name if present
  local tmp_file
  tmp_file=$(mktemp)
  awk -v name="$profile_name" '
    $0 == "profile " name " {" { skip=1; next }
    skip && /^}$/ { skip=0; next }
    !skip
  ' "$config_file" > "$tmp_file" && mv "$tmp_file" "$config_file"

  {
    echo ""
    echo "profile $profile_name {"
    echo "$outputs"
    echo "}"
  } >> "$config_file"

  echo "Saved to $config_file:"
  echo ""
  echo "profile $profile_name {"
  echo "$outputs"
  echo "}"

  notify-send "Kanshi" "Saved profile '$profile_name'" 2>/dev/null || true
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  kanshi_save
fi
