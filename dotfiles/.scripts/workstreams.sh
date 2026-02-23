#!/usr/bin/env bash

ws() {
  local ws_dir=".workstreams"
  local subcmd="$1"
  shift 2>/dev/null

  case "$subcmd" in
    logs)
      if [[ ! -d "$ws_dir" ]]; then
        echo "No workstreams directory found in current workspace"
        return 1
      fi

      local log_file="$ws_dir/$1/log"
      tail -F "$log_file"
      ;;

    ls)
      local show_all=false

      if [[ "$1" == "-a" ]]; then
        show_all=true
      fi

      if [[ ! -d "$ws_dir" ]]; then
        echo "No workstreams directory found in current workspace"
        return 1
      fi

      if [[ -z "$(ls -A "$ws_dir" 2>/dev/null)" ]]; then
        echo "No workstreams found"
        return 0
      fi

      for workstream_path in "$ws_dir"/*; do
        if [[ ! -d "$workstream_path" ]]; then
          continue
        fi

        local workstream_name=$(basename "$workstream_path")
        local tasks_file="$workstream_path/tasks.json"
        local is_running_file="$workstream_path/is_running"

        local ws_status=""
        if [[ -f "$is_running_file" ]]; then
          ws_status="[RUNNING]"
        fi

        local total_tasks=0
        local passed_tasks=0

        if [[ -f "$tasks_file" ]]; then
          if command -v jq &> /dev/null; then
            total_tasks=$(jq '. | length' "$tasks_file" 2>/dev/null || echo 0)
            passed_tasks=$(jq '[.[] | select(.passes == true)] | length' "$tasks_file" 2>/dev/null || echo 0)
          else
            total_tasks=$(grep -c '"category"' "$tasks_file" 2>/dev/null || echo 0)
            passed_tasks=$(grep -c '"passes": true' "$tasks_file" 2>/dev/null || echo 0)
          fi
        fi

        if [[ -z "$ws_status" ]]; then
          if [[ "$total_tasks" -gt 0 && "$passed_tasks" -eq "$total_tasks" ]]; then
            ws_status="[DONE]"
          else
            ws_status="[IDLE]"
          fi
        fi

        if [[ "$show_all" == false && "$ws_status" == "[DONE]" ]]; then
          continue
        fi

        printf "  %-30s %s %d/%d tasks completed\n" "$workstream_name" "$ws_status" "$passed_tasks" "$total_tasks"
      done
      ;;

    rm)
      if [[ -z "$1" ]]; then
        echo "Usage: ws rm <workstream_name>"
        return 1
      fi

      local ws_path="$ws_dir/$1"

      if [[ ! -d "$ws_path" ]]; then
        echo "Workstream '$1' not found"
        return 1
      fi

      rm -rf "$ws_path"
      git worktree prune
      echo "Removed worktree for workstream '$1'"
      ;;

    prompt)
      if [[ -z "$1" ]]; then
        echo "Usage: ws prompt <workstream_name>"
        return 1
      fi

      local ws_path="$ws_dir/$1"

      if [[ ! -d "$ws_path" ]]; then
        echo "Workstream '$1' not found"
        return 1
      fi

      cat << EOF
@$(realpath "$ws_path/PLAN.md") @$(realpath "$ws_path/tasks.json") @$(realpath "$ws_path/ACTIVITY.md")
@$(realpath "$ws_path/log")

First read ACTIVITY.md to see what was recently accomplished.

Open PLAN.md for context, then open tasks.json and choose the single highest priority task where passes is false.

Implement integration tests where appropriate.

Remember to call a fake claude inside the container.

After implementing
1. call the workspace's main linting function if there is one
2. call the workspace's main testing function to test relevant code if there is one

Append a dated progress entry to activity.md describing what you changed.

ONLY WORK ON A SINGLE TASK AT A TIME.

Update that task's passes in plan.md from false to true.

Make one git commit for that task only with a clear message.

Do not git init, do not change remotes, do not push.

ONLY WORK ON A SINGLE TASK AT A TIME.

If you are stuck for too long on something, DO A WEB SEARCH ABOUT IT!

Throughout this process, append log your thoughts using newlines to separate them to this file: @$(realpath "$ws_path/log")
If you get stuck on something for a long time, or something takes too long, make sure to append that to the log file as well.
Be moderately verbose. Don't spend more then 30s without appending anything to the log file.

When ALL tasks have passes true, output <promise>COMPLETE</promise>
EOF
      ;;

    run)
      if [[ -z "$1" ]]; then
        echo "Usage: ws run <workstream_name> [iterations]"
        return 1
      fi

      local name="$1"
      local iterations="${2:-10}"
      local ws_path="$ws_dir/$name"

      if [[ ! -d "$ws_path" ]] || [[ ! -f "$ws_path/PLAN.md" ]] || [[ ! -f "$ws_path/tasks.json" ]]; then
        echo "Error: Workstream '$name' does not exist or is missing required files (PLAN.md, tasks.json)"
        return 1
      fi

      if ! touch "$ws_path/is_running"; then
        echo "Error: Failed to create is_running file"
        return 1
      fi

      local worktree_path="$ws_path/worktree"
      if [[ -d "$worktree_path" ]]; then
        echo "Worktree already existed, resuming"
      elif ! git worktree add "$worktree_path" -b "$name"; then
        echo "Error: Failed to create git worktree"
        rm "$ws_path/is_running"
        return 1
      fi

      if command -v direnv &> /dev/null && [[ -f "$worktree_path/.envrc" ]]; then
        direnv allow "$worktree_path"
      fi

      for ((i=1; i<=iterations; i++)); do
        echo "[$name] Iteration $i"
        echo "--------------------------------"

        local prompt
        prompt=$(ws prompt "$name")
        local result
        result=$(env -C "$worktree_path" claude -p "$prompt" --dangerously-skip-permissions --model opus --output-format text 2>&1) || true

        echo "$result"

        if [[ "$result" == *"<promise>COMPLETE</promise>"* ]]; then
          echo "All tasks complete after $i iterations."
          rm "$ws_path/is_running"
          return 0
        fi

        echo ""
        echo "--- [$name] End of iteration $i ---"
        echo ""
      done

      echo "[$name] Reached max iterations ($iterations)"
      rm "$ws_path/is_running"
      return 1
      ;;

    new)
      claude ws
      ;;

    *)
      echo "Usage: ws <command>"
      echo ""
      echo "Commands:"
      echo "  ls [-a]            List workstreams (-a to include completed)"
      echo "  logs <name>        Tail the log for a workstream"
      echo "  rm <name>          Remove a workstream's worktree"
      echo "  new                Create a new workstream"
      echo "  prompt <name>      Generate the prompt for a workstream"
      echo "  run <name> [n]     Run a workstream for n iterations (default: 10)"
      ;;
  esac
}

# Run directly if executed, not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  ws "$@"
fi


