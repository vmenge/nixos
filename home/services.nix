# xdg desktop entries file
{ pkgs, config, ... }:

{
  systemd.user.services.wallpaper-randomizer = {
    Unit.Description = "Random wallpaper rotator";
    Unit.After = [ "graphical-session.target" ];

    Service.ExecStart = ''
      ${pkgs.bashInteractive}/bin/bash -l -c \
      "${config.home.homeDirectory}/.scripts/wallpaper.sh \
       ${config.home.homeDirectory}/.wallpaper"
    '';
    Service.Restart = "on-failure";
  };

  systemd.user.timers.wallpaper-randomizer = {
    Unit.Description = "Run wallpaper-randomizer every 5 minutes";
    Timer.OnUnitActiveSec = "300s";
    Timer.Persistent = true;
    Install.WantedBy = [ "timers.target" ];
  };
}
