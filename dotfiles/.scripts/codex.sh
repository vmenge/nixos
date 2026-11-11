cdx() {
    command codex -C "$PWD" \
        --sandbox workspace-write \
        --add-dir /tmp \
        --ask-for-approval never \
        "$@"
}
