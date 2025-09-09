# xdg desktop entries file
{ pkgs, config, ... }:

{
  xdg.desktopEntries = {
    # spotify = {
    #   name = "Spotify";
    #   genericName = "Music Player";
    #   icon = "spotify-client";
    #   exec = "${pkgs.spotify}/bin/spotify --enable-features=UseOzonePlatform --ozone-platform=wayland %U";
    #   terminal = false;
    #   mimeType = [ "x-scheme-handler/spotify" ];
    #   categories = [
    #     "Audio"
    #     "Music"
    #     "Player"
    #     "AudioVideo"
    #   ];
    # };
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "google-chrome.desktop";
      "x-scheme-handler/http" = "google-chrome.desktop";
      "x-scheme-handler/https" = "google-chrome.desktop";
      "application/pdf" = "org.pwmt.zathura.desktop";
      "TerminalEmulator" = "com.mitchellh.ghostty.desktop";
      "x-scheme-handler/terminal" = "com.mitchellh.ghostty.desktop";
      "video/mp4" = "vlc.desktop";
      "video/x-matroska" = "vlc.desktop";
    };
  };
}
