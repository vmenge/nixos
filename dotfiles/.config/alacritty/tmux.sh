#!/bin/bash
N=tmux ls | grep -v attached | head -1 | cut -f1 -d:

if [[ -z $N ]]; then
	tmux new
else
	tmux attach -t $N
fi
