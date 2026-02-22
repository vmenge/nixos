wsl() {
  local ws_dir=".workstreams"

  # Check if .workstreams directory exists
  if [[ ! -d "$ws_dir" ]]; then
    echo "No workstreams directory found in current workspace"
    return 1
  fi

  local log_file = "$ws_dir/$1/log"
  tail -f "$log_file"
}

ws() {
  local ws_dir=".workstreams"

  # Check if .workstreams directory exists
  if [[ ! -d "$ws_dir" ]]; then
    echo "No workstreams directory found in current workspace"
    return 1
  fi

  # Check if there are any workstreams
  if [[ -z "$(ls -A "$ws_dir" 2>/dev/null)" ]]; then
    echo "No workstreams found"
    return 0
  fi

  echo "Workstreams:"
  echo "----------------------------------------"

  # Iterate through each workstream directory
  for workstream_path in "$ws_dir"/*; do
    if [[ ! -d "$workstream_path" ]]; then
      continue
    fi

    local workstream_name=$(basename "$workstream_path")
    local tasks_file="$workstream_path/tasks.json"
    local is_running_file="$workstream_path/is_running"

    # Check if running
    local ws_status=""
    if [[ -f "$is_running_file" ]]; then
      ws_status="[RUNNING]"
    else
      ws_status="[IDLE]"
    fi

    # Count tasks and passes
    local total_tasks=0
    local passed_tasks=0

    if [[ -f "$tasks_file" ]]; then
      # Use jq to parse the JSON and count tasks
      if command -v jq &> /dev/null; then
        total_tasks=$(jq '. | length' "$tasks_file" 2>/dev/null || echo 0)
        passed_tasks=$(jq '[.[] | select(.passes == true)] | length' "$tasks_file" 2>/dev/null || echo 0)
      else
        # Fallback if jq is not available
        total_tasks=$(grep -c '"category"' "$tasks_file" 2>/dev/null || echo 0)
        passed_tasks=$(grep -c '"passes": true' "$tasks_file" 2>/dev/null || echo 0)
      fi
    fi

    # Print the workstream info
    printf "  %-30s %s %d/%d tasks completed\n" "$workstream_name" "$ws_status" "$passed_tasks" "$total_tasks"
  done

  echo "----------------------------------------"
}
