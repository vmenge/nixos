# xdg desktop entries file
{ pkgs, config, ... }:

{
  xdg.desktopEntries = {
    spotify = {
      name = "Spotify";
      genericName = "Music Player";
      icon = "spotify-client";
      exec = "${pkgs.spotify}/bin/spotify --enable-features=UseOzonePlatform --ozone-platform=wayland %U";
      terminal = false;
      mimeType = [ "x-scheme-handler/spotify" ];
      categories = [
        "Audio"
        "Music"
        "Player"
        "AudioVideo"
      ];
    };

    lock = {
      type = "Application";
      name = "Lock Screen";
      icon = "system-lock-screen"; 
      exec = "${pkgs.bash}/bin/bash -l -c \"${config.home.homeDirectory}/.scripts/lock.sh\"";
      terminal = false;
      categories = [ "Utility" ];
    };

    suspend = {
      type = "Application";
      name = "Suspend";
      icon = "system-suspend"; 
      exec = "${pkgs.bash}/bin/bash -l -c \"${config.home.homeDirectory}/.scripts/suspend.sh\"";
      terminal = false;
      categories = [ "System" ];
    };
  };
}
