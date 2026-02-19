{ pkgs, config, ... }:
let
  p = path: /. + "${config.home.homeDirectory}/nixos/dotfiles/${path}";
  sl = path: config.lib.file.mkOutOfStoreSymlink (p path);
in
{
  imports = [
    ./apps.nix
    ./services.nix
    ./dconf.nix
    ./steam.nix
    # ./kde.nix
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

    ".config/wii".source = sl ".config/wii";
    ".config/wii".recursive = true;

    ".config/starship.toml".source = sl ".config/starship.toml";
    ".zshrc".source = sl ".zshrc";
    ".aws/config".source = sl ".aws/config";

    ".config/sunshine/sunshine.conf".source = sl ".config/sunshine/sunshine.conf";
    ".config/sunshine/apps.json".source = sl ".config/sunshine/apps.json";

    ".cargo/config.toml".source = sl ".cargo/config.toml";

    # AI stuff
    ".agents".source = sl ".agents";
    ".agents".recursive = true;

    ".claude/skills".source = sl ".agents/skills";
    ".claude/skills".recursive = true;
    ".claude/settings.json".source = sl ".cloud/settings.json";

    # openxr shit
    # ".config/openxr/1/active_runtime.json".source =
    #   config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.local/share/Steam/steamapps/common/SteamVR/steamxr_linux64.json";
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
    # GBM_BACKEND = "nvidia-drm";
    LIBVA_DRIVER_NAME = "nvidia";
    __GL_THREADED_OPTIMIZATIONS = "0";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    BROWSER = "google-chrome";
    # vr shit
    LD_LIBRARY_PATH = "${
      pkgs.lib.makeLibraryPath [
        pkgs.openxr-loader
        pkgs.vulkan-loader
      ]
    }:$LD_LIBRARY_PATH";
    XR_RUNTIME_JSON = "${config.home.homeDirectory}/.config/openxr/1/active_runtime.json";
    PROTON_ENABLE_VR = 1;
  };

  gtk = {
    enable = true;
    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
  };
}
