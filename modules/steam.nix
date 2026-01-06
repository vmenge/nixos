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

  # vr permission shit
  programs.steam.package = 
   let
  patchedBwrap = pkgs.bubblewrap.overrideAttrs (o: {
    patches = (o.patches or []) ++ [
      ./steam-bwrap.patch
    ];
  });
in pkgs.steam.override {
    buildFHSEnv = (args: ((pkgs.buildFHSEnv.override {
      bubblewrap = patchedBwrap;
    }) (args // {
      extraBwrapArgs = (args.extraBwrapArgs or []) ++ [ "--cap-add ALL" ];
    })));
  };
  }
