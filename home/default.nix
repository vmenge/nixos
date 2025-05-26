{ pkgs, config, ... }:
let
  p = path: /. + "${config.home.homeDirectory}/nixos/dotfiles/${path}";
  sl = path: config.lib.file.mkOutOfStoreSymlink (p path);
in
{
  imports = [
    ./apps.nix
    ./services.nix
  ];

  home.username = "vmenge";
  home.homeDirectory = "/home/vmenge";
  home.stateVersion = "25.11";

  home.file = {
    ".config/nvim".source = sl ".config/nvim";
    ".config/nvim".recursive = true;

    ".config/ghostty".source = sl ".config/ghostty";
    ".config/ghostty".recursive = true;

    ".config/sway".source = sl ".config/sway";
    ".config/sway".recursive = true;

    ".config/waybar".source = sl ".config/waybar";
    ".config/waybar".recursive = true;

    ".config/fuzzel".source = sl ".config/fuzzel";
    ".config/fuzzel".recursive = true;

    ".config/i3".source = sl ".config/i3";
    ".config/i3".recursive = true;

    ".config/mako".source = sl ".config/mako";
    ".config/mako".recursive = true;

    ".config/kanshi".source = sl ".config/kanshi";
    ".config/kanshi".recursive = true;

    ".config/zed".source = sl ".config/zed";
    ".config/zed".recursive = true;

    ".scripts".source = sl ".scripts";
    ".scripts".recursive = true;

    ".config/starship.toml".source = sl ".config/starship.toml";
    ".zshrc".source = sl ".zshrc";
    ".aws/config".source = sl ".aws/config";
  };

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    TERMINAL = "ghostty";
    XDG_CURRENT_DESKTOP = "sway";
    XDG_SESSION_TYPE = "wayland";
    XDG_CONFIG_HOME = "${config.home.homeDirectory}/.config/";
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    MOZ_ENABLE_WAYLAND = "1";
    GDK_BACKEND = "wayland";
    QT_QPA_PLATFORM = "wayland";
    SDL_VIDEODRIVER = "wayland,x11,windows";
    GBM_BACKEND = "nvidia-drm";
    BROWSER = "google-chrome";
  };

  gtk = {
    enable = true;
    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
  };
}
