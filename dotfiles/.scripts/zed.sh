zedplug() {
    ls -1 ~/.local/share/zed/extensions/installed | jq -Rn '[inputs | {(.): true}] | add' | wl-copy
}
