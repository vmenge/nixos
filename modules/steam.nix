{ pkgs, ... }:
let
  steamosSessionSelect = pkgs.writeShellScriptBin "steamos-session-select" ''
    #!/usr/bin/env bash
    set -eu

    # Steam calls this with an argument (e.g. "desktop"/"gamescope"/"plasma"),
    # but if you just want “back to login screen”, you can ignore it.
    if [ -n "''${XDG_SESSION_ID:-}" ]; then
      exec loginctl terminate-session "''${XDG_SESSION_ID}"
    else
      exec loginctl terminate-user "''${USER}"
    fi
  '';
in
{
  environment.systemPackages = [ steamosSessionSelect ];
  systemd.tmpfiles.rules = [
    "d /usr 0755 root root - -"
    "d /usr/bin 0755 root root - -"
    "L+ /usr/bin/steamos-session-select - - - - /run/current-system/sw/bin/steamos-session-select"
  ];

  programs.gamemode.enable = true;
  programs.gamescope.capSysNice = true;
  programs.steam.enable = true;
  programs.steam.gamescopeSession.enable = true;
  programs.steam.gamescopeSession.args = [
    "--prefer-output"
    "DP-1,DP-2,DP-3,HDMI-A-1,*,eDP-1"
  ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # vr shit
  security.pam.loginLimits = [
    {
      domain = "vmenge";
      type = "-";
      item = "rtprio";
      value = "99";
    }
  ];

  boot.kernelPatches = [
    {
      name = "amdgpu-ignore-ctx-privileges";
      patch = pkgs.fetchpatch {
        name = "cap_sys_nice_begone.patch";
        url = "https://github.com/Frogging-Family/community-patches/raw/master/linux61-tkg/cap_sys_nice_begone.mypatch";
        hash = "sha256-Y3a0+x2xvHsfLax/uwycdJf3xLxvVfkfDVqjkxNaYEo=";
      };
    }
  ];

  services.wivrn = {
    enable = true;
    openFirewall = true;

    # Write information to /etc/xdg/openxr/1/active_runtime.json, VR applications
    # will automatically read this and work with WiVRn (Note: This does not currently
    # apply for games run in Valve's Proton)
    defaultRuntime = true;

    # Run WiVRn as a systemd service on startup
    autoStart = true;

    # If you're running this with an nVidia GPU and want to use GPU Encoding (and don't otherwise have CUDA enabled system wide), you need to override the cudaSupport variable.
    package = (pkgs.wivrn.override { cudaSupport = true; });

    # You should use the default configuration (which is no configuration), as that works the best out of the box.
    # However, if you need to configure something see https://github.com/WiVRn/WiVRn/blob/master/docs/configuration.md for configuration options and https://mynixos.com/nixpkgs/option/services.wivrn.config.json for an example configuration.
  };
}
