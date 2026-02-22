if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 <workstream_name> <iterations>"
  exit 1
fi

if [ ! -d ".workstreams/$1" ] || [ ! -f ".workstreams/$1/PLAN.md" ] || [ ! -f ".workstreams/$1/tasks.json" ]; then
  echo "Error: Workstream '$1' does not exist or is missing required files (PLAN.md, tasks.json)"
  exit 1
fi

if ! touch ".workstreams/$1/is_running"; then
  echo "Error: Failed to create is_running file"
  exit 1
fi

worktree_path=".workstreams/$1/worktree"
if ! git worktree add "$worktree_path" -b "$1"; then
  echo "Error: Failed to create git worktree"
  rm ".workstreams/$1/is_running"
  exit 1
fi

for ((i=1; i<=$2; i++)); do
  echo "[$1] Iteration $i"
  echo "--------------------------------"

  prompt=$(./prompt.sh $1)
  result=$(cd "$worktree_path" && claude -p "$prompt" --dangerously-skip-permissions --model opus --output-format text 2>&1) || true

  echo "$result"

  if [[ "$result" == *"<promise>COMPLETE</promise>"* ]]; then
    echo "All tasks complete after $i iterations."
    rm ".workstreams/$1/is_running"
    exit 0
  fi

  echo ""
  echo "--- [$1] End of iteration $i ---"
  echo ""
done

echo "[$1] Reached max iterations ($2)"
rm ".workstreams/$1/is_running"
exit 1
