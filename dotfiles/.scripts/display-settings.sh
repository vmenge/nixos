#!/usr/bin/env bash

touch /run/user/$(id -u)/kanshi-lock
pkill -f "uwsm app -- kanshi"
pkill kanshi

wdisplays

source "$HOME/.scripts/kanshi.sh"
kanshi_save

rm -f /run/user/$(id -u)/kanshi-lock
uwsm app -- kanshi &
