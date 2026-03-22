_xtask_workstream_names() {
  local -a workstreams
  workstreams=( .workstreams/*(/N:t) )
  _describe 'workstream' workstreams
}

_xtask_agent_names() {
  local -a agents
  agents=(
    'codex:Run with Codex'
    'claude:Run with Claude'
  )
  _describe 'agent' agents
}

_xtask_ws_subcommands() {
  local -a ws_subcommands
  ws_subcommands=(
    'ls:List workstreams'
    'queue:Queue multiple workstreams'
    'rm:Remove a workstream'
    'info:Show detailed workstream info'
    'exec:Execute a workstream'
  )
  _describe 'ws subcommand' ws_subcommands
}

_xtask_ws_queue_subcommands() {
  local -a queue_subcommands
  queue_subcommands=(
    'run:Run queued workstreams serially'
  )
  _describe 'ws queue subcommand' queue_subcommands
}

_xtask_ws_exec_options() {
  local -a exec_options
  exec_options=(
    '--agent:Choose agent'
    '--stall-limit:Set stall limit'
    '--unsafe:Skip nono sandbox'
  )
  _describe 'ws exec option' exec_options
}

_xtask_ws_queue_run_options() {
  local -a queue_run_options
  queue_run_options=(
    '--agent:Choose agent'
    '--stall-limit:Set stall limit'
    '--unsafe:Skip nono sandbox'
  )
  _describe 'ws queue run option' queue_run_options
}

_xtask_complete_exec() {
  local workstream_index=$1
  local prev_word=${words[CURRENT-1]}

  if [[ ${prev_word} == --agent ]]; then
    _xtask_agent_names
    return
  fi

  if [[ ${prev_word} == --stall-limit ]]; then
    _message 'stall limit'
    return
  fi

  if (( CURRENT == workstream_index )) && [[ ${words[CURRENT]} != -* ]]; then
    _xtask_workstream_names
    return
  fi

  if (( CURRENT > workstream_index )) && [[ ${words[CURRENT]} == -* ]]; then
    _xtask_ws_exec_options
  fi
}

_xtask_complete_queue_run() {
  local first_workstream_index=$1
  local prev_word=${words[CURRENT-1]}

  if [[ ${prev_word} == --agent ]]; then
    _xtask_agent_names
    return
  fi

  if [[ ${prev_word} == --stall-limit ]]; then
    _message 'stall limit'
    return
  fi

  if (( CURRENT >= first_workstream_index )) && [[ ${words[CURRENT]} == -* ]]; then
    _xtask_ws_queue_run_options
    return
  fi

  if (( CURRENT >= first_workstream_index )); then
    _xtask_workstream_names
  fi
}

_x() {
  local context state line
  local -a commands

  commands=(
    'agents-md:Create an AGENTS.override.md symlink'
    'build:Build xtask in debug mode'
    'ws:Workstream commands'
  )

  if (( CURRENT == 2 )); then
    _describe 'x command' commands
    return
  fi

  [[ ${words[2]} == ws ]] || return

  if (( CURRENT == 3 )); then
    _xtask_ws_subcommands
    return
  fi

  case ${words[3]} in
    rm|info)
      (( CURRENT == 4 )) && _xtask_workstream_names
      ;;
    exec)
      _xtask_complete_exec 4
      ;;
    queue)
      if (( CURRENT == 4 )); then
        _xtask_ws_queue_subcommands
        return
      fi

      [[ ${words[4]} == run ]] && _xtask_complete_queue_run 5
      ;;
  esac
}

_ws() {
  if (( CURRENT == 2 )); then
    _xtask_ws_subcommands
    return
  fi

  case ${words[2]} in
    rm|info)
      (( CURRENT == 3 )) && _xtask_workstream_names
      ;;
    exec)
      _xtask_complete_exec 3
      ;;
    queue)
      if (( CURRENT == 3 )); then
        _xtask_ws_queue_subcommands
        return
      fi

      [[ ${words[3]} == run ]] && _xtask_complete_queue_run 4
      ;;
  esac
}

compdef _x x
compdef _ws ws
