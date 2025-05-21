_prompt_pass() {
  printf 'Passphrase: ' >&2
  stty -echo
  IFS= read -r p
  stty echo
  printf '\n' >&2
  printf '%s' "$p"
}

env_new() {
  local f="${1:-.env}"
  # If f is a directory, append .env to it
  if [[ -d "$f" ]]; then
    f="${f}/.env"
  fi
  local p="$(_prompt_pass)" || return
  local t=$(mktemp)
  : >"$t"
  printf '%s' "$p" | gpg --symmetric --cipher-algo AES256 --pinentry-mode loopback \
    --batch --yes --passphrase-fd 0 -o "$f" "$t"
  rm -f "$t"; unset p
}

env_edit() {                           # env_edit [file] (default .env)
  local f="${1:-.env}" t=$(mktemp) p
  # If f is a directory, append .env to it
  if [[ -d "$f" ]]; then
    f="${f}/.env"
  fi
  if [[ -f $f ]]; then                 # existing file → decrypt first
    p="$(_prompt_pass)" || { rm -f "$t"; return; }
    printf '%s' "$p" | gpg --quiet --batch --yes --pinentry-mode loopback \
      --passphrase-fd 0 --decrypt "$f" >"$t" 2>/dev/null || { rm -f "$t"; return; }
  else                                 # new file → start empty
    : >"$t"
  fi

  "${EDITOR:-vi}" "$t" || { rm -f "$t"; return; }

  p="${p:-$(_prompt_pass)}"            # ask passphrase if not yet set
  printf '%s' "$p" | gpg --symmetric --cipher-algo AES256 \
    --pinentry-mode loopback --batch --yes --passphrase-fd 0 \
    -o "$f" "$t"
  rm -f "$t"; unset p
}

env_load() {
  local f="${1:-.env}"
  # If f is a directory, append .env to it
  if [[ -d "$f" ]]; then
    f="${f}/.env"
  fi
  local p="$(_prompt_pass)" || return
  local t=$(mktemp)
  printf '%s' "$p" | gpg --quiet --batch --yes --pinentry-mode loopback \
    --passphrase-fd 0 --decrypt "$f" >"$t" || { rm -f "$t"; return 1; }
  set -a; . "$t"; set +a
  rm -f "$t"; unset p
}
