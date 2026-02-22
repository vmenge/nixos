source /etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh
source $HOME/.scripts/tfh.sh
source $HOME/.scripts/safe_env.sh
source $HOME/.scripts/zed.sh
source $HOME/.scripts/dconf.sh
source $HOME/.scripts/steam.sh
source $HOME/.scripts/workstreams.sh

##########################################
# rust                                   #
##########################################
# export PATH="$HOME/.rustup/toolchains/$(rustup show active-toolchain | cut -d" " -f1)/bin:$PATH"
# export PATH="$HOME/.cargo/bin:$PATH"


##########################################
# ocaml                                  #
##########################################
# BEGIN opam configuration
# This is useful if you're using opam as it adds:
#   - the correct directories to the PATH
#   - auto-completion for the opam binary
# This section can be safely removed at any time if needed.
[[ ! -r '/home/vmenge/.opam/opam-init/init.zsh' ]] || source '/home/vmenge/.opam/opam-init/init.zsh' > /dev/null 2> /dev/null
# END opam configuration

##########################################
# aliases                                #
##########################################
alias gc="git commit"
alias gcdate="git commit -m \"$(date)\""
alias gst="git status"
alias glog="git log --oneline --decorate --graph"
alias gloga="git log --oneline --decorate --graph --all"
alias gco="git checkout"
alias gb="git branch"
alias ga="git add"
alias gaa="git add --all"
alias gp="git push"
ggp() { git push origin "$(git branch --show-current)" "$@" }
ggl() { git pull origin "$(git branch --show-current)" "$@" }
alias zed="zeditor"
alias grep="rg"
alias yy="yazi"
alias ls="lsd"
alias nxs="sudo nixos-rebuild switch"
alias nxu="sudo nix flake update && sudo nixos-rebuild switch"
alias nxg="sudo nix-collect-garbage -d && nix-collect-garbage -d"
# plasma manager stuff
alias rc2nix="nix run github:nix-community/plasma-manager"
alias x="$HOME/nixos/xtask/target/debug/x"
alias sucata="/home/vmenge/dev/sucata/target/debug/sucata"
alias sucatad="/home/vmenge/dev/sucata/target/debug/sucatad"


##########################################
# fzf                                    #
##########################################
if [ -n "${commands[fzf-share]}" ]; then
  source "$(fzf-share)/key-bindings.zsh"
  source "$(fzf-share)/completion.zsh"
fi


##########################################
# wii remote                             #
##########################################
export SDL_GAMECONTROLLERCONFIG="$(cat ~/.config/wii/gamecontrollerdb.txt)"

##########################################
# avahi                                  #
##########################################
avahi() {
  avahi-resolve -4 --name $1 | awk '{print $2}'
}

##########################################
# restart sound
##########################################
rsound() {
  systemctl --user restart pipewire pipewire-pulse wireplumber
}

##########################################
# edit command line                      #
##########################################
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line
