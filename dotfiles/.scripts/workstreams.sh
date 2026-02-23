#!/usr/bin/env bash

_ws_elapsed() {
  local file="$1"
  local start_epoch
  start_epoch=$(stat -c %Y "$file" 2>/dev/null || stat -f %m "$file" 2>/dev/null) || return
  local now_epoch
  now_epoch=$(date +%s)
  local diff=$(( now_epoch - start_epoch ))
  local hours=$(( diff / 3600 ))
  local mins=$(( (diff % 3600) / 60 ))
  if (( hours > 0 )); then
    printf "%dh %dm" "$hours" "$mins"
  elif (( diff < 120 )); then
    printf "%ds" "$diff"
  else
    printf "%dm" "$mins"
  fi
}

ws() {
  local ws_dir=".workstreams"
  local subcmd="$1"
  shift 2>/dev/null

  case "$subcmd" in
    path)
      if [[ -z "$1" ]]; then
        echo "Usage: ws path <workstream_name>"
        return 1
      fi

      local worktree_path="$ws_dir/$1/worktree"

      if [[ ! -d "$worktree_path" ]]; then
        echo "No worktree found for workstream '$1'" >&2
        return 1
      fi

      realpath "$worktree_path"
      ;;

    cd)
      if [[ -z "$1" ]]; then
        echo "Usage: ws cd <workstream_name>"
        return 1
      fi

      local worktree_path="$ws_dir/$1/worktree"

      if [[ ! -d "$worktree_path" ]]; then
        echo "No worktree found for workstream '$1'"
        return 1
      fi

      pushd "$worktree_path"
      ;;

    status)
      if [[ -z "$1" ]]; then
        echo "Usage: ws status <workstream_name>"
        return 1
      fi

      local name="$1"
      local ws_path="$ws_dir/$name"

      if [[ ! -d "$ws_path" ]]; then
        echo "Workstream '$name' not found"
        return 1
      fi

      local tasks_file="$ws_path/tasks.json"
      local total_tasks=0
      local passed_tasks=0

      if [[ -f "$tasks_file" ]] && command -v jq &> /dev/null; then
        total_tasks=$(jq '. | length' "$tasks_file" 2>/dev/null || echo 0)
        passed_tasks=$(jq '[.[] | select(.passes == true)] | length' "$tasks_file" 2>/dev/null || echo 0)
      fi

      local bold='\033[1m'
      local dim='\033[2m'
      local green='\033[32m'
      local yellow='\033[33m'
      local red='\033[31m'
      local cyan='\033[36m'
      local reset='\033[0m'

      local ws_status_color ws_status ws_extra=""
      if [[ -f "$ws_path/is_running" ]]; then
        ws_status="RUNNING"
        ws_status_color="$yellow"
        ws_extra="  ${dim}$(_ws_elapsed "$ws_path/is_running")${reset}"
      elif [[ "$total_tasks" -gt 0 && "$passed_tasks" -eq "$total_tasks" ]]; then
        ws_status="DONE"
        ws_status_color="$green"
        if [[ -f "$ws_path/completed_at" ]]; then
          ws_extra="  ${dim}$(cat "$ws_path/completed_at")${reset}"
        fi
      else
        ws_status="IDLE"
        ws_status_color="$dim"
      fi

      printf "\n${bold}%s${reset}  ${ws_status_color}%s${reset}  %d/%d tasks${ws_extra}\n" "$name" "$ws_status" "$passed_tasks" "$total_tasks"

      if [[ -f "$tasks_file" ]] && command -v jq &> /dev/null; then
        printf "\n${bold}${cyan}Tasks${reset}\n"
        local count
        count=$(jq '. | length' "$tasks_file")
        local desc passes mark mark_color
        for ((j=0; j<count; j++)); do
          desc=$(jq -r ".[$j].description" "$tasks_file")
          passes=$(jq -r ".[$j].passes" "$tasks_file")
          if [[ "$passes" == "true" ]]; then
            mark="✓"
            mark_color="$green"
          else
            mark="○"
            mark_color="$dim"
          fi
          printf "  ${mark_color}%s${reset} ${bold}%d${reset}  %s\n" "$mark" "$((j+1))" "$desc"
        done
      fi

      local log_file="$ws_path/log"
      printf "\n${bold}${cyan}Recent logs${reset}\n"
      if [[ -f "$log_file" ]]; then
        tail -5 "$log_file" | while IFS= read -r line; do
          printf "  ${dim}%s${reset}\n" "$line"
        done
      else
        printf "  ${dim}(no log file)${reset}\n"
      fi
      echo ""
      ;;

    logs)
      if [[ ! -d "$ws_dir" ]]; then
        echo "No workstreams directory found in current workspace"
        return 1
      fi

      local log_file="$ws_dir/$1/log"
      tail -F "$log_file"
      ;;

    ls)
      local active_only=false

      if [[ "$1" == "-a" ]]; then
        active_only=true
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

        local ws_status="" ws_status_color="" ws_extra=""
        if [[ -f "$is_running_file" ]]; then
          ws_status="RUNNING"
          ws_status_color='\033[33m'
          ws_extra="  \033[2m$(_ws_elapsed "$is_running_file")\033[0m"
        elif [[ "$total_tasks" -gt 0 && "$passed_tasks" -eq "$total_tasks" ]]; then
          ws_status="DONE"
          ws_status_color='\033[32m'
          if [[ -f "$workstream_path/completed_at" ]]; then
            ws_extra="  \033[2m$(cat "$workstream_path/completed_at")\033[0m"
          fi
        else
          ws_status="IDLE"
          ws_status_color='\033[2m'
        fi

        if [[ "$active_only" == true && "$ws_status" == "DONE" ]]; then
          continue
        fi

        printf "  \033[1m%-30s\033[0m ${ws_status_color}%-10s\033[0m %d/%d tasks${ws_extra}\n" "$workstream_name" "$ws_status" "$passed_tasks" "$total_tasks"
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

    clean)
      if [[ -z "$1" ]]; then
        echo "Usage: ws clean <workstream_name> [-f]"
        return 1
      fi

      local name="$1"
      local force="$2"
      local worktree_path="$ws_dir/$name/worktree"

      if [[ "$force" != "-f" ]]; then
        printf "Clean workstream '%s'? [y/N] " "$name"
        read confirm
        if [[ "$confirm" != [yY] ]]; then
          echo "Aborted"
          return 0
        fi
      fi

      if [[ -d "$worktree_path" ]]; then
        rm -rf "$worktree_path"
        echo "Removed worktree at $worktree_path"
      else
        echo "No worktree found, skipping"
      fi

      echo "Pruning worktrees..."
      git worktree prune

      if git branch --list "$name" | grep -q .; then
        git branch -D "$name" 2>/dev/null
        echo "Deleted branch '$name'"
      else
        echo "No branch '$name' found, skipping"
      fi

      if [[ -f "$ws_dir/$name/is_running" ]]; then
        rm -f "$ws_dir/$name/is_running"
        echo "Removed is_running marker"
      else
        echo "No is_running marker, skipping"
      fi

      local tasks_file="$ws_dir/$name/tasks.json"
      if [[ -f "$tasks_file" ]] && command -v jq &> /dev/null; then
        jq '[.[] | .passes = false]' "$tasks_file" > "$tasks_file.tmp" && mv "$tasks_file.tmp" "$tasks_file"
        echo "Reset all tasks to passes=false"
      else
        echo "No tasks.json found, skipping"
      fi

      echo "Done cleaning workstream '$name'"
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

      if [[ -f "$ws_path/is_running" ]]; then
        echo "Error: Workstream '$name' is already running. Use 'ws clean $name' to reset."
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
      else
        local post_worktree_hook="$ws_dir/.hooks/post-worktree"
        if [[ -x "$post_worktree_hook" ]]; then
          echo "Running post-worktree hook..."
          "$post_worktree_hook" "$worktree_path"
        else
          echo "No post-worktree hook found at $post_worktree_hook"
        fi
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
          date '+%Y-%m-%d %H:%M' > "$ws_path/completed_at"
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

    review)
      if [[ -z "$1" ]]; then
        echo "Usage: ws review <workstream_name>"
        return 1
      fi

      claude "ws review $1"
      ;;

    pr)
      if [[ -z "$1" ]]; then
        echo "Usage: ws pr <workstream_name>"
        return 1
      fi

      claude "workstream pr for $1"
      ;;

    man)
      cat << 'EOF'
ws - workstream manager

Workstreams are isolated units of work, each with their own git worktree,
plan, task list, and activity log. They live under .workstreams/ in the
current directory.

DIRECTORY STRUCTURE

  .workstreams/
    .hooks/
      post-worktree    Executable hook run after a new worktree is created.
                       Receives the worktree path as its first argument.
                       Useful for copying config files, installing deps, etc.
    <name>/
      PLAN.md          High-level plan and context for the workstream.
      tasks.json       Task list with "passes" booleans tracking completion.
      ACTIVITY.md      Dated log of progress and changes.
      log              Real-time log of agent thoughts during execution.
      worktree/        Git worktree (created by "ws run").
      is_running       Marker file present while a run is in progress.

COMMANDS

  ws new
      Create a new workstream interactively via Claude.

  ws ls [-a]
      List workstreams and their status. Shows all by default.
      Pass -a to show only active (idle/running) workstreams.

  ws run <name> [iterations]
      Run a workstream. Creates a git worktree (and branch) if one doesn't
      exist, then invokes Claude in headless mode for up to <iterations>
      iterations (default: 10). Each iteration picks the next incomplete
      task, implements it, tests it, and commits. Stops early if all tasks
      pass.

  ws path <name>
      Print the absolute path to a workstream's worktree.

  ws logs <name>
      Tail the real-time log file for a workstream.

  ws prompt <name>
      Print the prompt that "ws run" sends to Claude each iteration.

  ws review <name>
      Review the work done in a workstream via Claude. Suggests additions
      to PLAN.md and new tasks based on the diff.

  ws clean <name> [-f]
      Remove the worktree for a workstream but keep all other files
      (PLAN.md, tasks.json, etc). Prompts for confirmation unless -f
      is passed.

  ws rm <name>
      Remove a workstream directory entirely and prune its git worktree.

HOOKS

  .workstreams/.hooks/post-worktree
      If this file exists and is executable, it is run once after a new
      worktree is created by "ws run". It receives the worktree path as
      its only argument. It is NOT run when resuming an existing worktree.

      Example:
        #!/usr/bin/env bash
        cp .env "$1/.env"
        cd "$1" && npm install
EOF
      ;;

    *)
      echo "Usage: ws <command>"
      echo ""
      echo "Commands:"
      echo "  status <name>      Show detailed status for a workstream"
      echo "  path <name>        Print the worktree path"
      echo "  cd <name>          pushd into a workstream's worktree"
      echo "  ls [-a]            List workstreams (-a for active only)"
      echo "  logs <name>        Tail the log for a workstream"
      echo "  clean <name> [-f]  Remove a workstream's worktree (-f to skip prompt)"
      echo "  rm <name>          Remove a workstream entirely"
      echo "  new                Create a new workstream"
      echo "  review <name>      Review changes and suggest new tasks"
      echo "  pr <name>          Generate a PR description for a workstream"
      echo "  prompt <name>      Generate the prompt for a workstream"
      echo "  run <name> [n]     Run a workstream for n iterations (default: 10)"
      echo "  man                Show detailed manual"
      ;;
  esac
}

# Run directly if executed, not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  ws "$@"
fi

if [[ -n "$ZSH_VERSION" ]]; then
  _ws_completion() {
    local ws_dir=".workstreams"
    local subcommands=(status path cd ls logs clean rm new review pr prompt run man)
    local needs_name=(status path cd logs clean rm review pr prompt run)
    if (( CURRENT == 2 )); then
      _describe 'subcommand' subcommands
    elif (( CURRENT == 3 )) && (( ${needs_name[(Ie)${words[2]}]} )); then
      local names=()
      if [[ -d "$ws_dir" ]]; then
        for d in "$ws_dir"/*/; do
          names+=("$(basename "$d")")
        done
      fi
      _describe 'workstream' names
    fi
  }
  compdef _ws_completion ws
elif [[ -n "$BASH_VERSION" ]]; then
  _ws_completion_bash() {
    local ws_dir=".workstreams"
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local subcmd="${COMP_WORDS[1]}"
    local subcommands="status path cd ls logs clean rm new review pr prompt run man"
    local needs_name="status path cd logs clean rm review pr prompt run"
    if (( COMP_CWORD == 1 )); then
      COMPREPLY=($(compgen -W "$subcommands" -- "$cur"))
    elif (( COMP_CWORD == 2 )) && [[ " $needs_name " == *" $subcmd "* ]] && [[ -d "$ws_dir" ]]; then
      local names=""
      for d in "$ws_dir"/*/; do
        [[ -d "$d" ]] && names+="$(basename "$d") "
      done
      COMPREPLY=($(compgen -W "$names" -- "$cur"))
    fi
  }
  complete -F _ws_completion_bash ws
fi
