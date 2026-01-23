# xdg desktop entries file
{ ... }:

{
  programs.gh = {
    enable = true;
    gitCredentialHelper = {
      enable = true;
    };
  };

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

      # video formats
      "video/mp4" = "vlc.desktop";
      "video/x-matroska" = "vlc.desktop";
      "video/quicktime" = "vlc.desktop";
      "video/x-msvideo" = "vlc.desktop";
      "application/vnd.rn-realmedia" = "vlc.desktop";
      "application/vnd.rn-realmedia-vbr" = "vlc.desktop";
      "video/vnd.rn-realvideo" = "vlc.desktop";
      "video/x-flv" = "vlc.desktop";
      "video/x-ms-wmv" = "vlc.desktop";
      "video/x-ms-asf" = "vlc.desktop";
      "video/mpeg" = "vlc.desktop";
      "video/ogg" = "vlc.desktop";
      "video/webm" = "vlc.desktop";
      "video/3gpp" = "vlc.desktop";
      "video/3gpp2" = "vlc.desktop";
    };
  };
}
