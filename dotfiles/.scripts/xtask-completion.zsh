_xtask_workstream_names() {
  local -a workstreams
  workstreams=( .workstreams/*(/N:t) )
  _describe 'workstream' workstreams
}

_xtask_ws_subcommands() {
  local -a ws_subcommands
  ws_subcommands=(
    'ls:List workstreams'
    'rm:Remove a workstream'
    'info:Show detailed workstream info'
    'exec:Execute a workstream'
  )
  _describe 'ws subcommand' ws_subcommands
}

_x() {
  local context state line
  local -a commands

  commands=(
    'agentsmd:Create an AGENTS.override.md symlink'
    'build:Build xtask in debug mode'
    'ws:Workstream commands'
  )

  _arguments -C \
    '1:command:->command' \
    '2:subcommand:->subcommand' \
    '3:workstream:->workstream' && return 0

  case "$state" in
    command) _describe 'x command' commands ;;
    subcommand) [[ ${words[2]} == ws ]] && _xtask_ws_subcommands ;;
    workstream) [[ ${words[2]} == ws && ( ${words[3]} == rm || ${words[3]} == info || ${words[3]} == exec ) ]] && _xtask_workstream_names ;;
  esac
}

_ws() {
  local context state line

  _arguments -C \
    '1:subcommand:->subcommand' \
    '2:workstream:->workstream' && return 0

  case "$state" in
    subcommand) _xtask_ws_subcommands ;;
    workstream) [[ ${words[2]} == rm || ${words[2]} == info || ${words[2]} == exec ]] && _xtask_workstream_names ;;
  esac
}

compdef _x x
compdef _ws ws
