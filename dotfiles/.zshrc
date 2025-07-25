source /etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh
source $HOME/.scripts/tfh.sh
source $HOME/.scripts/safe_env.sh
source $HOME/.scripts/zed.sh

##########################################
# rust                                   #
##########################################
export PATH="$HOME/.rustup/toolchains/$(rustup show active-toolchain | cut -d" " -f1)/bin:$PATH"

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
alias cat="bat"
alias ls="lsd"
alias nxs="sudo nixos-rebuild switch"
alias nxu="sudo nix flake update && sudo nixos-rebuild switch"
alias nxg="sudo nix-collect-garbage -d && nix-collect-garbage -d"


##########################################
# fzf                                    #
##########################################
if [ -n "${commands[fzf-share]}" ]; then
  source "$(fzf-share)/key-bindings.zsh"
  source "$(fzf-share)/completion.zsh"
fi

##########################################
# avahi                                  #
##########################################
avahi() {
  avahi-resolve -4 --name $1 | awk '{print $2}'
}

##########################################
# edit command line                      #
##########################################
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

##########################################
# auto start sway on tty login          #
##########################################
if [ "$(tty)" = "/dev/tty1" ]; then
  exec sway --unsupported-gpu
fi
