#!/usr/bin/env bash

cpshot() {
  while [[ "$#" -gt 0 ]]; do
      case $1 in
          -r|--region)
              region_flag=true
              ;;
      esac
      shift
  done

  if $region_flag; then
    grim -g "$(slurp)" - | wl-copy
  else
    grim - | wl-copy
  fi
}

sshot() {
  while [[ "$#" -gt 0 ]]; do
      case $1 in
          -r|--region)
              region_flag=true
              ;;
      esac
      shift
  done

  mkdir -p "$HOME/.screenshots"
  if $region_flag; then
    grim -g "$(slurp)" "$HOME/.screenshots/$(date).png"
  else
    grim "$HOME/.screenshots/$(date).png"
  fi
}

if [ "$1" = "clip" ]; then
  shift
  cpshot "$@"
else
  sshot "$@"
fi
