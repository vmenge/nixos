{ pkgs, lib, ... }:
{
  imports = [
    ./pkgs.nix
    ./sway.nix
    ./gnome.nix
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  networking.networkmanager.enable = true;
  boot.binfmt.emulatedSystems = lib.filter (s: s != pkgs.stdenv.hostPlatform.system) [
    "aarch64-linux"
    "x86_64-linux"
  ];

  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  users.users.vmenge = {
    isNormalUser = true;
    extraGroups = [
      "networkmanager"
      "audio"
      "video"
      "wheel"
      "docker"
    ];
  };

  nix.settings.trusted-users = [
    "root"
    "vmenge"
  ];

  services.logind.lidSwitch = "suspend";
  services.logind.lidSwitchDocked = "ignore";
  services.logind.lidSwitchExternalPower = "ignore";
  services.logind.killUserProcesses = false;

  security.polkit.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    wireplumber.enable = true;

    # support alsa and pulseaudio
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.devmon.enable = true;
  services.dbus.enable = true;
  services.avahi.enable = true;

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      # sunshine
      47984
      47989
      47990
      48010
    ];
    allowedUDPPortRanges = [
      # sunshine
      {
        from = 47998;
        to = 48000;
      }
      # sunshine
      {
        from = 8000;
        to = 8010;
      }
    ];
  };

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.11"; # Did you read the comment?
}
