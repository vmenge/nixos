{ pkgs, config, ... }:
{
  imports = [
    ./apps.nix
    ./services.nix
  ];

  home.username = "vmenge";
  home.homeDirectory = "/home/vmenge";
  home.stateVersion = "25.11";

  home.file = {
    ".config/nvim".source = ../dotfiles/.config/nvim;
    ".config/nvim".recursive = true;

    ".config/ghostty".source = ../dotfiles/.config/ghostty;
    ".config/ghostty".recursive = true;

    ".config/sway".source = ../dotfiles/.config/sway;
    ".config/sway".recursive = true;

    ".config/waybar".source = ../dotfiles/.config/waybar;
    ".config/waybar".recursive = true;

    ".config/fuzzel".source = ../dotfiles/.config/fuzzel;
    ".config/fuzzel".recursive = true;

    ".config/i3".source = ../dotfiles/.config/i3;
    ".config/i3".recursive = true;

    ".config/mako".source = ../dotfiles/.config/mako;
    ".config/mako".recursive = true;

    ".config/kanshi".source = ../dotfiles/.config/kanshi;
    ".config/kanshi".recursive = true;

    ".config/zed".source = ../dotfiles/.config/zed;
    ".config/zed".recursive = true;

    ".scripts".source = ../dotfiles/.scripts;
    ".scripts".recursive = true;

    ".config/starship.toml".source = ../dotfiles/.config/starship.toml;
    ".zshrc".source = ../dotfiles/.zshrc;
    ".aws/config".source = ../dotfiles/.aws/config;
  };

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    XDG_CURRENT_DESKTOP = "sway";
    XDG_SESSION_TYPE = "wayland";
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    MOZ_ENABLE_WAYLAND = "1";
    GDK_BACKEND = "wayland";
    QT_QPA_PLATFORM = "wayland";
    SDL_VIDEODRIVER = "wayland,x11,windows";
    GBM_BACKEND = "nvidia-drm";
    BROWSER = "google-chrome";
  };

}
