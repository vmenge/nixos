# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "com/github/ryonakano/reco" = {
      autosave-destination = "/home/vmenge/Downloads";
    };

    "org/gnome/control-center" = {
      last-panel = "keyboard";
      window-state = mkTuple [
        1280
        784
        false
      ];
    };

    "org/gnome/desktop/app-folders" = {
      folder-children = [
        "System"
        "Utilities"
        "YaST"
        "Pardus"
      ];
    };

    "org/gnome/desktop/app-folders/folders/Pardus" = {
      categories = [ "X-Pardus-Apps" ];
      name = "X-Pardus-Apps.directory";
      translate = true;
    };

    "org/gnome/desktop/app-folders/folders/System" = {
      apps = [
        "org.gnome.baobab.desktop"
        "org.gnome.DiskUtility.desktop"
        "org.gnome.Logs.desktop"
        "org.gnome.SystemMonitor.desktop"
      ];
      name = "X-GNOME-Shell-System.directory";
      translate = true;
    };

    "org/gnome/desktop/app-folders/folders/Utilities" = {
      apps = [
        "org.gnome.Connections.desktop"
        "org.gnome.Evince.desktop"
        "org.gnome.FileRoller.desktop"
        "org.gnome.font-viewer.desktop"
        "org.gnome.Loupe.desktop"
        "org.gnome.seahorse.Application.desktop"
      ];
      name = "X-GNOME-Shell-Utilities.directory";
      translate = true;
    };

    "org/gnome/desktop/app-folders/folders/YaST" = {
      categories = [ "X-SuSE-YaST" ];
      name = "suse-yast.directory";
      translate = true;
    };

    "org/gnome/desktop/background" = {
      color-shading-type = "solid";
      picture-options = "zoom";
      picture-uri = "file:///run/current-system/sw/share/backgrounds/gnome/ring-l.jxl";
      picture-uri-dark = "file:///run/current-system/sw/share/backgrounds/gnome/ring-d.jxl";
      primary-color = "#26a269";
      secondary-color = "#000000";
    };

    "org/gnome/desktop/input-sources" = {
      sources = [
        (mkTuple [
          "xkb"
          "us"
        ])
      ];
      xkb-options = [ ];
    };

    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      icon-theme = "Adwaita";
    };

    "org/gnome/desktop/notifications" = {
      application-children = [ "steam" ];
    };

    "org/gnome/desktop/notifications/application/gnome-power-panel" = {
      application-id = "gnome-power-panel.desktop";
    };

    "org/gnome/desktop/notifications/application/steam" = {
      application-id = "steam.desktop";
    };

    "org/gnome/desktop/screensaver" = {
      color-shading-type = "solid";
      picture-options = "zoom";
      picture-uri = "file:///run/current-system/sw/share/backgrounds/gnome/ring-l.jxl";
      primary-color = "#26a269";
      secondary-color = "#000000";
    };

    "org/gnome/desktop/search-providers" = {
      sort-order = [
        "org.gnome.Settings.desktop"
        "org.gnome.Contacts.desktop"
        "org.gnome.Nautilus.desktop"
      ];
    };

    "org/gnome/desktop/wm/keybindings" = {
      close = [ "<Super>q" ];
      minimize = [ ];
      move-to-workspace-1 = [ "<Shift><Super>1" ];
      move-to-workspace-2 = [ "<Shift><Super>2" ];
      move-to-workspace-3 = [ "<Shift><Super>3" ];
      move-to-workspace-4 = [ "<Shift><Super>4" ];
      move-to-workspace-5 = [ "<Shift><Super>5" ];
      move-to-workspace-6 = [ "<Shift><Super>6" ];
      move-to-workspace-7 = [ "<Shift><Super>7" ];
      move-to-workspace-8 = [ "<Shift><Super>8" ];
      move-to-workspace-9 = [ "<Shift><Super>9" ];
      move-to-workspace-10 = [ "<Shift><Super>0" ];
      switch-to-workspace-1 = [ "<Super>1" ];
      switch-to-workspace-2 = [ "<Super>2" ];
      switch-to-workspace-3 = [ "<Super>3" ];
      switch-to-workspace-4 = [ "<Super>4" ];
      switch-to-workspace-5 = [ "<Super>5" ];
      switch-to-workspace-6 = [ "<Super>6" ];
      switch-to-workspace-7 = [ "<Super>7" ];
      switch-to-workspace-8 = [ "<Super>8" ];
      switch-to-workspace-9 = [ "<Super>9" ];
      switch-to-workspace-10 = [ "<Super>0" ];
      switch-to-workspace-left = [ "<Shift><Super>h" ];
      switch-to-workspace-right = [ "<Shift><Super>l" ];
      toggle-fullscreen = [ "<Super>f" ];
    };

    "org/gnome/desktop/wm/preferences" = {
      num-workspaces = 10;
    };

    "org/gnome/evolution-data-server" = {
      migrated = true;
    };

    "org/gnome/mutter" = {
      dynamic-workspaces = false;
      output-luminance = [
        (mkTuple [
          "DP-1"
          "DEL"
          "Dell AW3821DW"
          "#GTIYMxgwABWz"
          (mkUint32 1)
          190.0
        ])
      ];
    };

    "org/gnome/nautilus/preferences" = {
      default-folder-viewer = "icon-view";
      migrated-gtk-settings = true;
      search-filter-time-type = "last_modified";
    };

    "org/gnome/nautilus/window-state" = {
      initial-size = mkTuple [
        890
        550
      ];
    };

    "org/gnome/settings-daemon/plugins/color" = {
      night-light-schedule-automatic = false;
    };

    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
      ];
      screensaver = [ ];
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      binding = "<Super>Return";
      command = "ghostty";
      name = "terminal";
    };

    "org/gnome/shell" = {
      enabled-extensions = [
        "tactile@lundal.io"
        "focus-changer@heartmire"
      ];
      last-selected-power-profile = "performance";
      welcome-dialog-last-shown-version = "48.4";
    };

    "org/gnome/shell/extensions/tactile" = {
      col-0 = 0;
      layout-2-col-0 = 2;
      layout-2-col-2 = 0;
      layout-2-col-3 = 0;
      monitor-0-layout = 1;
      row-0 = 1;
      show-tiles = [ "<Super>e" ];
    };

    "org/gnome/shell/keybindings" = {
      switch-to-application-1 = [ ];
      switch-to-application-2 = [ ];
      switch-to-application-3 = [ ];
      switch-to-application-4 = [ ];
    };

    "org/gnome/shell/world-clocks" = {
      locations = [ ];
    };

  };
}
