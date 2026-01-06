vrfix() {
    sudo setcap CAP_SYS_NICE=eip ~/.local/share/Steam/steamapps/common/SteamVR/bin/linux64/vrcompositor-launcher
    sudo setcap CAP_SYS_NICE=eip ~/.local/share/Steam/steamapps/common/SteamVR/bin/linux64/vrserver
}

vrstatus() {
  echo vrcompositor-launcher: $(getcap ~/.local/share/Steam/steamapps/common/SteamVR/bin/linux64/vrcompositor-launcher)
  echo vrserver: $(getcap ~/.local/share/Steam/steamapps/common/SteamVR/bin/linux64/vrserver)
}

vrkill() {
  killall -9 vrserver vrcompositor steam
}
