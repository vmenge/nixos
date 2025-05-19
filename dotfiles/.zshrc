source $HOME/.scripts/tfh.sh
source $HOME/.scripts/safe_env.sh

##########################################
# aliases                                #
##########################################
alias gc="git commit"
alias gst="git status"
alias glog="git log --oneline --decorate --graph"
alias gloga="git log --oneline --decorate --graph --all"
alias gco="git checkout"
alias gb="git branch"
alias ga="git add"
alias gaa="git add --all"
alias gp="git push"
alias ggp="git push origin"
alias ggl="git pull origin"
alias zed="zeditor"
alias grep="rg"
alias yy="yazi"
alias cat="bat"
alias ls="lsd"
alias nxs="sudo nixos-rebuild switch"
alias nxu="sudo nixos-rebuild switch --upgrade"
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
