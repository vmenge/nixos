{ pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  programs.nix-ld.enable = true;
  services.fwupd.enable = true;

  programs.steam.enable = true;
  programs.steam.gamescopeSession.enable = true;
  programs.gamemode.enable = true;
  programs.gamescope.capSysNice = true;

  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;
  programs.starship.enable = true;

  programs.light.enable = true;

  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
  };

  services.mullvad-vpn.enable = true;

  virtualisation = {
    waydroid.enable = true;
    docker.enable = true;
  };

  environment.systemPackages = with pkgs; [
    # text editors
    neovim
    vim
    zed-editor
    vscode

    # dev tools, lsps, fmts, runtimes and compilers
    git
    git-lfs
    strace
    openssh
    openssl
    just # command runner
    tldr
    gcc
    gnumake
    cmake
    clang
    clang-tools
    dasm # assembler for 6502
    bear # gen compilation db for clang tooling
    postman # http API dev env
    atac # postman-like TUI
    lldb # debugger
    gdb
    valgrind
    ante
    clojure
    clojure-lsp
    leiningen
    (dotnetCorePackages.combinePackages [
      dotnetCorePackages.sdk_8_0-bin
      dotnetCorePackages.sdk_9_0-bin
      dotnetCorePackages.sdk_10_0-bin
      dotnetCorePackages.aspnetcore_8_0-bin
      dotnetCorePackages.aspnetcore_9_0-bin
      dotnetCorePackages.aspnetcore_10_0-bin
    ])
    omnisharp-roslyn
    fsautocomplete
    fantomas
    bun # js runtime
    nodejs
    eslint_d # eslint lsp
    prettierd # prettier as a daemon
    typescript
    typescript-language-server
    gopls # official go lsp
    protobuf
    k9s # k8s TUI
    kubectl # k8s CLI
    kubernetes-helm # k8s package manager
    helm-ls # helm lsp
    terraform # build, change and version infra
    terraform-ls # terraform lsp
    pulumi
    pulumiPackages.pulumi-nodejs
    lua-language-server
    markdown-oxide # markdown lsp
    opam # OCaml package manager
    ocamlPackages.ocaml-lsp
    ocamlPackages.ocamlformat
    ocamlPackages.ocamlformat-rpc-lib
    ocamlPackages.ocp-indent
    ocamlPackages.merlin
    ocamlPackages.reason
    ocamlPackages.dune_3
    ocamlPackages.findlib
    ocamlPackages.melange
    i2c-tools
    stlink-gui
    zig
    nixd # nix lsp
    nil # nix lsp
    nixfmt-rfc-style
    rustup
    bacon # rust test watcher
    dioxus-cli # dioxus
    jdk
    claude-code
    codex
    amp-cli
    probe-rs
    man-pages
    python3
    pyright
    pylint
    uv
    godot
    godot-mono
    cargo-zigbuild
    nushell
    vulkan-tools
    woeusb-ng # windows bootable usb
    python313Packages.west
    taplo
    qemu
    cloud-init
    cloud-utils
    libguestfs
    guestfs-tools
    exercism

    # dev services
    gh # GitHub cli
    awscli2 # AWS cli
    ssm-session-manager-plugin # AWS session manager
    cloudflared # CloudFlare tunnel daemon, toolkit and dns-over-https client
    doctl # DigitalOcean cli

    # databases and related
    mongodb-compass
    mongosh

    # containerization
    docker-compose
    docker-buildx
    podman # containerization client and daemon
    distrobox # podman / docker wrapper for distros
    toolbox # podman / docker wrapper for distros

    # terminals and shells
    ghostty

    # desktop functionality
    libnotify
    i3blocks # i3 bar scheduler
    gtk2 # UI toolkit
    gtk3 # UI toolkit
    gtk4 # UI toolkit
    webkitgtk_4_1
    grim # grab images from wayland compositor
    slurp # select region for wayland compositor
    fuzzel # application launcher
    mako # noficiations
    kanshi # display configuration
    swww # wallpaper daemon
    acpi # battery status and other ACPI info
    acpilight # backlight control
    bluez # bluetooth
    bluetuith # bluetooth tui (req bluez)
    btop # resource monitoring
    emote # emoji picker
    pavucontrol # volume control
    pamixer # pulseaudio command line mixer
    yazi # terminal file manager
    zathura # pdf viewer
    wl-clipboard # clipboard for wayland
    wdisplays # configure displays
    xdg-utils
    adwaita-icon-theme
    adwaita-icon-theme-legacy
    hicolor-icon-theme
    dconf
    dconf2nix
    gnomeExtensions.focus-changer
    gnomeExtensions.tactile
    gnomeExtensions.blur-my-shell
    gnomeExtensions.vitals
    gnomeExtensions.clipboard-indicator

    # gaming
    game-devices-udev-rules # udev rules to make supported controlles available
    gamemode # optimize linux performance on demand
    protontricks # winetricks wrapper for proton games
    protonup-qt # proton GE ver manager
    stella # Atari 2600 VCS emulator
    vrrtest
    mangohud
    lsfg-vk
    lsfg-vk-ui

    # messaging
    slack

    # fun
    neofetch
    cmatrix # simulates falling characters theme from matrix movie
    cowsay

    # archiving and compression
    p7zip
    atool # archive command line helper
    zip
    unzip
    zlib

    # browsers
    brave
    firefox
    google-chrome

    # images / video / audio
    vlc
    mpv
    spotify
    cava # visualizer for alsa
    alsa-utils
    imagemagick # create, edit, compose or convert bitmap images
    ffmpeg
    shotcut
    libcamera
    reco
    gpu-screen-recorder-gtk

    # filesystems
    ntfs3g

    # assorted tools
    lsd # alternative to ls
    fd # alternative to find
    fzf # command line fuzzy finder
    ripgrep # grep alternative
    tree
    wget
    curl
    killall
    bat # cat clone with syntax highlighting
    _1password-gui
    _1password-cli
    magic-wormhole # transfer data across computers
    lshw # provide detailed information on the hw cfg of host
    gnupg
    jq
    cachix
    file
    picocom
    parted
    f2fs-tools
    usbutils
    edid-decode
    pciutils
    socat
  ];

  fonts.packages = with pkgs; [
    dina-font
    fira-code
    fira-code-symbols
    font-awesome
    jetbrains-mono
    liberation_ttf
    mplus-outline-fonts.githubRelease
    nerd-fonts.droid-sans-mono
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    nerd-fonts.iosevka
    nerd-fonts.iosevka-term
    noto-fonts
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    noto-fonts-emoji
    proggyfonts
    source-han-sans
    source-han-sans-japanese
    source-han-serif-japanese
  ];
}
