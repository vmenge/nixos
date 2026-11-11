cdx() {
    local git_dir common_dir encoded_path
    local -a permissions

    if git_dir=$(git rev-parse --absolute-git-dir 2>/dev/null); then
        common_dir=$(git rev-parse --path-format=absolute --git-common-dir) || return

        for git_dir in "$git_dir" "$common_dir"; do
            encoded_path=$(jq -cn --arg path "$git_dir" '$path') || return
            permissions+=(-c "permissions.cdx.filesystem.${encoded_path}=\"write\"")
        done
    else
        printf '%s\n' 'cdx: Git discovery failed; starting without additional Git metadata access.' >&2
    fi

    command codex -C "$PWD" --profile cdx \
        --ask-for-approval never \
        "${permissions[@]}" \
        "$@"
}

compdef _codex cdx=codex
