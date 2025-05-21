{ pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  programs.nix-ld.enable = true;

  programs.steam.enable = true;

  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;
  programs.starship.enable = true;

  programs.light.enable = true;

  environment.systemPackages = with pkgs; [
    # text editors
    neovim
    vim
    zed-editor

    # dev tools, lsps, fmts, runtimes and compilers
    git
    strace
    openssh
    just # command runner
    tldr
    gcc
    gnumake
    cmake
    dasm # assembler for 6502
    bear # gen compilation db for clang tooling
    postman # http API dev env
    atac # postman-like TUI
    lldb # debugger
    dotnetCorePackages.aspnetcore_8_0-bin
    dotnetCorePackages.aspnetcore_9_0-bin
    dotnetCorePackages.aspnetcore_10_0-bin
    bun # js runtime
    eslint_d # eslint lsp
    prettierd # prettier as a daemon
    gopls # official go lsp
    k9s # k8s TUI
    kubectl # k8s CLI
    kubernetes-helm # k8s package manager
    helm-ls # helm lsp
    terraform # build, change and version infra
    terraform-ls # terraform lsp
    lua-language-server
    markdown-oxide # markdown lsp
    opam # OCaml package manager
    i2c-tools
    stlink-gui
    zig
    nixd # nix lsp
    nil # nix lsp
    nixfmt-rfc-style
    rustup
    dioxus-cli # dioxus
    jdk
    claude-code

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
    docker # containerization client and daemon
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
    grim # grab images from wayland compositor
    slurp # select region for wayland compositor
    fuzzel # application launcher
    mako # noficiations
    kanshi # display configuration
    swww # wallpaper daemon
    acpi # battery status and other ACPI info
    acpilight # backlight control
    bluetuith # bluetooth
    btop # resource monitoring
    emote # emoji picker
    pavucontrol # volume control
    pamixer # pulseaudio command line mixer
    yazi # terminal file manager
    zathura # pdf viewer
    wl-clipboard # clipboard for wayland
    wdisplays # configure displays

    # gaming
    game-devices-udev-rules # udev rules to make supported controlles available
    gamemode # optimize linux performance on demand
    protontricks # winetricks wrapper for proton games
    protonup-qt # proton GE ver manager
    stella # Atari 2600 VCS emulator

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
