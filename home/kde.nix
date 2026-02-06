{ ... }:
{
  programs.plasma = {
    enable = true;

    workspace = {
      # theme = "breeze-dark";
      # colorScheme = "BreezeDark";
      # cursorTheme = "Breeze";
      # iconTheme = "breeze-dark";
      # wallpaper = "${pkgs.kdePackages.plasma-workspace-wallpapers}/share/wallpapers/Next/contents/images_dark/3840x2160.png";
    };

    hotkeys.commands = {
      "launch-terminal" = {
        key = "Meta+Return";
        command = "ghostty";
      };
    };

    panels = [
      # Example panel at bottom
      # {
      #   location = "bottom";
      #   height = 44;
      #   widgets = [
      #     "org.kde.plasma.kickoff"
      #     "org.kde.plasma.pager"
      #     "org.kde.plasma.taskmanager"
      #     "org.kde.plasma.systemtray"
      #     "org.kde.plasma.digitalclock"
      #   ];
      # }
    ];

    shortcuts = {
      # "kwin"."Switch to Desktop 1" = "Meta+1";
      # "kwin"."Switch to Desktop 2" = "Meta+2";
    };

    configFile = {
      # Example: disable single-click to open files
      # "kdeglobals"."KDE"."SingleClick" = false;
    };
  };
}
