#!/usr/bin/env bash

_ws_list_paths() {
  local ws_dir=".workstreams"

  if [[ ! -d "$ws_dir" ]]; then
    echo "No workstreams directory found in current workspace"
    return 1
  fi

  local paths
  paths="$(find "$ws_dir" -mindepth 1 -maxdepth 1 -type d -print | LC_ALL=C sort)"

  if [[ -z "$paths" ]]; then
    echo "No workstreams found"
    return 0
  fi

  printf '%s\n' "$paths"
}

_ws_list_names() {
  local path

  while IFS= read -r path; do
    [[ -n "$path" ]] || continue
    basename "$path"
  done < <(find ".workstreams" -mindepth 1 -maxdepth 1 -type d -print 2>/dev/null | LC_ALL=C sort)
}

ws() {
  local ws_dir=".workstreams"
  local subcmd="${1:-}"

  case "$subcmd" in
    ls)
      _ws_list_paths
      ;;

    rm)
      if [[ -z "${2:-}" ]]; then
        echo "Usage: ws rm <workstream_name>"
        return 1
      fi

      local name="$2"
      local ws_path="$ws_dir/$name"

      if [[ ! -d "$ws_path" ]]; then
        echo "Workstream '$name' not found"
        return 1
      fi

      rm -rf -- "$ws_path"
      echo "Removed $ws_path"
      ;;

    *)
      echo "Usage: ws ls | ws rm <workstream_name>"
      return 1
      ;;
  esac
}

if [[ -n "${ZSH_VERSION:-}" ]]; then
  _ws_completion() {
    local subcommands=(ls rm)

    if (( CURRENT == 2 )); then
      _describe 'subcommand' subcommands
    elif (( CURRENT == 3 )) && [[ "${words[2]}" == "rm" ]]; then
      local names=()
      local name

      while IFS= read -r name; do
        [[ -n "$name" ]] || continue
        names+=("$name")
      done < <(_ws_list_names)

      _describe 'workstream' names
    fi
  }
  compdef _ws_completion ws
elif [[ -n "${BASH_VERSION:-}" ]]; then
  _ws_completion_bash() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local subcmd="${COMP_WORDS[1]}"

    if (( COMP_CWORD == 1 )); then
      COMPREPLY=($(compgen -W "ls rm" -- "$cur"))
    elif (( COMP_CWORD == 2 )) && [[ "$subcmd" == "rm" ]]; then
      local names
      names="$(_ws_list_names)"
      COMPREPLY=($(compgen -W "$names" -- "$cur"))
    fi
  }
  complete -F _ws_completion_bash ws
fi

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  ws "$@"
  exit $?
fi
