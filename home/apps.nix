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
      icon = "lock";
      exec = "${config.home.homeDirectory}/.scripts/lock.sh";
      terminal = false;
      categories = [ "Utility" ];
    };

    suspend = {
      type = "Application";
      name = "Suspend";
      icon = "sleep";
      exec = "${config.home.homeDirectory}/.scripts/suspend.sh";
      terminal = false;
      categories = [ "System" ];
    };

    shutdown = {
      type = "Application";
      name = "Shutdown";
      icon = "system-shutdown";
      exec = "shutdown now";
      terminal = false;
      categories = [ "System" ];
    };

    reboot = {
      type = "Application";
      name = "Reboot";
      icon = "refresh";
      exec = "reboot";
      terminal = false;
      categories = [ "System" ];
    };
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "google-chrome.desktop";
      "x-scheme-handler/http" = "google-chrome.desktop";
      "x-scheme-handler/https" = "google-chrome.desktop";
      "application/pdf" = "org.pwmt.zathura.desktop";
      "inode/directory" = "dolphin.desktop";
      "TerminalEmulator" = "com.mitchellh.ghostty.desktop";
      "x-scheme-handler/terminal" = "com.mitchellh.ghostty.desktop";
    };
  };
}
