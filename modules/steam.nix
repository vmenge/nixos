{ pkgs, ... }:
let
  steamosSessionSelect = pkgs.writeShellScriptBin "steamos-session-select" ''
    #!/usr/bin/env bash
    set -euo pipefail
    steam -shutdown 2>/dev/null || true
    systemctl --user exit || true
    if [ -n "''${XDG_SESSION_ID:-}" ]; then
      loginctl terminate-session "''${XDG_SESSION_ID}" || true
    else
      loginctl terminate-user "''${USER}" || true
    fi
  '';
in
{
  environment.systemPackages = [ steamosSessionSelect ];

  systemd.tmpfiles.rules = [
    "L+ /usr/bin/steamos-session-select - - - - /run/current-system/sw/bin/steamos-session-select"
  ];

  programs.gamemode.enable = true;
  programs.gamescope.capSysNice = true;
  programs.steam.enable = true;
  programs.steam.gamescopeSession.enable = true;
  programs.steam.gamescopeSession.args = [
    "--prefer-output"
    "DP-1,HDMI-A-1,*,eDP-1"
  ];

}
