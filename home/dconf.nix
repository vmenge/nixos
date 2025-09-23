# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "apps/seahorse/listing" = {
      keyrings-selected = [ "gnupg://" ];
    };

    "apps/seahorse/windows/key-manager" = {
      height = 476;
      width = 600;
    };

    "com/github/ryonakano/reco" = {
      autosave-destination = "/home/vmenge/Downloads";
    };

    "org/gnome/Characters" = {
      recent-characters = [ "128517" ];
    };

    "org/gnome/Connections" = {
      first-run = false;
    };

    "org/gnome/Music" = {
      window-maximized = true;
    };

    "org/gnome/Snapshot" = {
      is-maximized = false;
      window-height = 640;
      window-width = 800;
    };

    "org/gnome/Totem" = {
      active-plugins = [ "rotation" "autoload-subtitles" "mpris" "movie-properties" "screenshot" "save-file" "open-directory" "screensaver" "recent" "skipto" "variable-rate" ];
      subtitle-encoding = "UTF-8";
    };

    "org/gnome/Weather" = {
      locations = [];
      window-height = 494;
      window-maximized = false;
      window-width = 439;
    };

    "org/gnome/baobab/ui" = {
      is-maximized = false;
      window-size = mkTuple [ 960 600 ];
    };

    "org/gnome/clocks/state/window" = {
      maximized = false;
      panel-id = "world";
      size = mkTuple [ 870 690 ];
    };

    "org/gnome/control-center" = {
      last-panel = "display";
      window-state = mkTuple [ 1440 928 true ];
    };

    "org/gnome/desktop/app-folders" = {
      folder-children = [ "System" "Utilities" "YaST" "Pardus" ];
    };

    "org/gnome/desktop/app-folders/folders/Pardus" = {
      categories = [ "X-Pardus-Apps" ];
      name = "X-Pardus-Apps.directory";
      translate = true;
    };

    "org/gnome/desktop/app-folders/folders/System" = {
      apps = [ "org.gnome.baobab.desktop" "org.gnome.DiskUtility.desktop" "org.gnome.Logs.desktop" "org.gnome.SystemMonitor.desktop" ];
      name = "X-GNOME-Shell-System.directory";
      translate = true;
    };

    "org/gnome/desktop/app-folders/folders/Utilities" = {
      apps = [ "org.gnome.Connections.desktop" "org.gnome.Evince.desktop" "org.gnome.FileRoller.desktop" "org.gnome.font-viewer.desktop" "org.gnome.Loupe.desktop" "org.gnome.seahorse.Application.desktop" ];
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
      picture-uri = "file:///home/vmenge/.local/share/backgrounds/2025-09-01-19-02-56-wallhaven-yj9w9g.jpg";
      picture-uri-dark = "file:///home/vmenge/.local/share/backgrounds/2025-09-01-19-02-56-wallhaven-yj9w9g.jpg";
      primary-color = "#000000000000";
      secondary-color = "#000000000000";
    };

    "org/gnome/desktop/input-sources" = {
      sources = [ (mkTuple [ "xkb" "us" ]) ];
      xkb-options = [];
    };

    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      icon-theme = "Adwaita";
      show-battery-percentage = true;
    };

    "org/gnome/desktop/notifications" = {
      application-children = [ "steam" "gnome-power-panel" "google-chrome" "spotify" "org-gnome-characters" "com-mitchellh-ghostty" "slack" ];
    };

    "org/gnome/desktop/notifications/application/com-mitchellh-ghostty" = {
      application-id = "com.mitchellh.ghostty.desktop";
    };

    "org/gnome/desktop/notifications/application/gnome-power-panel" = {
      application-id = "gnome-power-panel.desktop";
    };

    "org/gnome/desktop/notifications/application/google-chrome" = {
      application-id = "google-chrome.desktop";
    };

    "org/gnome/desktop/notifications/application/org-gnome-characters" = {
      application-id = "org.gnome.Characters.desktop";
    };

    "org/gnome/desktop/notifications/application/slack" = {
      application-id = "slack.desktop";
    };

    "org/gnome/desktop/notifications/application/spotify" = {
      application-id = "spotify.desktop";
    };

    "org/gnome/desktop/notifications/application/steam" = {
      application-id = "steam.desktop";
    };

    "org/gnome/desktop/screensaver" = {
      color-shading-type = "solid";
      picture-options = "zoom";
      picture-uri = "file:///home/vmenge/.local/share/backgrounds/2025-09-01-19-02-56-wallhaven-yj9w9g.jpg";
      primary-color = "#000000000000";
      secondary-color = "#000000000000";
    };

    "org/gnome/desktop/search-providers" = {
      sort-order = [ "org.gnome.Settings.desktop" "org.gnome.Contacts.desktop" "org.gnome.Nautilus.desktop" ];
    };

    "org/gnome/desktop/session" = {
      idle-delay = mkUint32 0;
    };

    "org/gnome/desktop/wm/keybindings" = {
      close = [ "<Super>q" ];
      minimize = [];
      move-to-monitor-down = [ "<Shift><Control><Super>j" ];
      move-to-monitor-left = [ "<Shift><Control><Super>h" ];
      move-to-monitor-right = [ "<Shift><Control><Super>l" ];
      move-to-monitor-up = [ "<Shift><Control><Super>k" ];
      move-to-workspace-1 = [ "<Shift><Super>1" ];
      move-to-workspace-10 = [ "<Shift><Super>0" ];
      move-to-workspace-2 = [ "<Shift><Super>2" ];
      move-to-workspace-3 = [ "<Shift><Super>3" ];
      move-to-workspace-4 = [ "<Shift><Super>4" ];
      move-to-workspace-5 = [ "<Shift><Super>5" ];
      move-to-workspace-6 = [ "<Shift><Super>6" ];
      move-to-workspace-7 = [ "<Shift><Super>7" ];
      move-to-workspace-8 = [ "<Shift><Super>8" ];
      move-to-workspace-9 = [ "<Shift><Super>9" ];
      switch-to-application-1 = [];
      switch-to-application-10 = [];
      switch-to-application-2 = [];
      switch-to-application-3 = [];
      switch-to-application-4 = [];
      switch-to-application-5 = [];
      switch-to-application-6 = [];
      switch-to-application-7 = [];
      switch-to-application-8 = [];
      switch-to-application-9 = [];
      switch-to-workspace-1 = [ "<Super>1" ];
      switch-to-workspace-10 = [ "<Super>0" ];
      switch-to-workspace-2 = [ "<Super>2" ];
      switch-to-workspace-3 = [ "<Super>3" ];
      switch-to-workspace-4 = [ "<Super>4" ];
      switch-to-workspace-5 = [ "<Super>5" ];
      switch-to-workspace-6 = [ "<Super>6" ];
      switch-to-workspace-7 = [ "<Super>7" ];
      switch-to-workspace-8 = [ "<Super>8" ];
      switch-to-workspace-9 = [ "<Super>9" ];
      switch-to-workspace-left = [ "<Ctrl><Super>h" ];
      switch-to-workspace-right = [ "<Ctrl><Super>l" ];
      toggle-fullscreen = [ "<Super>f" ];
    };

    "org/gnome/desktop/wm/preferences" = {
      num-workspaces = 10;
    };

    "org/gnome/evolution-data-server" = {
      migrated = true;
    };

    "org/gnome/file-roller/listing" = {
      list-mode = "as-folder";
      name-column-width = 67;
      show-path = false;
      sort-method = "name";
      sort-type = "ascending";
    };

    "org/gnome/file-roller/ui" = {
      sidebar-width = 200;
      window-height = 480;
      window-width = 600;
    };

    "org/gnome/gnome-system-monitor" = {
      cpu-colors = [ (mkTuple [ (mkUint32 0) "#e01b24" ]) (mkTuple [ 1 "#ff7800" ]) (mkTuple [ 2 "#f6d32d" ]) (mkTuple [ 3 "#33d17a" ]) (mkTuple [ 4 "#26a269" ]) (mkTuple [ 5 "#62a0ea" ]) (mkTuple [ 6 "#1c71d8" ]) (mkTuple [ 7 "#613583" ]) (mkTuple [ 8 "#9141ac" ]) (mkTuple [ 9 "#c061cb" ]) (mkTuple [ 10 "#ffbe6f" ]) (mkTuple [ 11 "#f9f06b" ]) (mkTuple [ 12 "#8ff0a4" ]) (mkTuple [ 13 "#2ec27e" ]) (mkTuple [ 14 "#1a5fb4" ]) (mkTuple [ 15 "#c061cb" ]) (mkTuple [ 16 "#7999c483f332" ]) (mkTuple [ 17 "#e7fff3327999" ]) (mkTuple [ 18 "#dae97999f332" ]) (mkTuple [ 19 "#7999f332b76e" ]) (mkTuple [ 20 "#f33293f37999" ]) (mkTuple [ 21 "#799982baf332" ]) (mkTuple [ 22 "#a635f3327999" ]) (mkTuple [ 23 "#f3327999c9b1" ]) ];
      maximized = false;
      show-dependencies = false;
      show-whose-processes = "user";
      window-height = 720;
      window-width = 800;
    };

    "org/gnome/gnome-system-monitor/proctree" = {
      col-26-visible = false;
      col-26-width = 0;
    };

    "org/gnome/maps" = {
      last-viewed-location = [ 44.075355 32.990146 ];
      map-type = "MapsVectorSource";
      transportation-type = "pedestrian";
      window-maximized = true;
      zoom-level = 2;
    };

    "org/gnome/mutter" = {
      dynamic-workspaces = false;
      output-luminance = [ (mkTuple [ "DP-1" "DEL" "Dell AW3821DW" "#GTIYMxgwABWz" (mkUint32 1) 190.0 ]) (mkTuple [ "DP-3" "DEL" "Dell AW3821DW" "#GTIYMxgwABWz" 1 190.0 ]) ];
      workspaces-only-on-primary = true;
    };

    "org/gnome/nautilus/preferences" = {
      default-folder-viewer = "icon-view";
      migrated-gtk-settings = true;
      search-filter-time-type = "last_modified";
    };

    "org/gnome/nautilus/window-state" = {
      initial-size = mkTuple [ 711 916 ];
      initial-size-file-chooser = mkTuple [ 890 550 ];
      maximized = false;
    };

    "org/gnome/portal/filechooser/google-chrome" = {
      last-folder-path = "/home/vmenge/Screenshots";
    };

    "org/gnome/portal/filechooser/org/gnome/Settings" = {
      last-folder-path = "/home/vmenge/.wallpaper";
    };

    "org/gnome/portal/filechooser/slack" = {
      last-folder-path = "/home/vmenge/Downloads";
    };

    "org/gnome/settings-daemon/plugins/color" = {
      night-light-schedule-automatic = false;
    };

    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [ "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/" ];
      screensaver = [];
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      binding = "<Super>Return";
      command = "ghostty";
      name = "terminal";
    };

    "org/gnome/settings-daemon/plugins/power" = {
      sleep-inactive-ac-type = "nothing";
      sleep-inactive-battery-type = "nothing";
    };

    "org/gnome/shell" = {
      disabled-extensions = [];
      enabled-extensions = [ "tactile@lundal.io" "focus-changer@heartmire" "Vitals@CoreCoding.com" "blur-my-shell@aunetx" "clipboard-indicator@tudmotu.com" ];
      favorite-apps = [];
      last-selected-power-profile = "power-saver";
      welcome-dialog-last-shown-version = "48.4";
    };

    "org/gnome/shell/app-switcher" = {
      current-workspace-only = true;
    };

    "org/gnome/shell/extensions/blur-my-shell" = {
      settings-version = 2;
    };

    "org/gnome/shell/extensions/blur-my-shell/appfolder" = {
      brightness = 0.6;
      sigma = 30;
    };

    "org/gnome/shell/extensions/blur-my-shell/coverflow-alt-tab" = {
      pipeline = "pipeline_default";
    };

    "org/gnome/shell/extensions/blur-my-shell/dash-to-dock" = {
      blur = true;
      brightness = 0.6;
      pipeline = "pipeline_default_rounded";
      sigma = 30;
      static-blur = true;
      style-dash-to-dock = 0;
    };

    "org/gnome/shell/extensions/blur-my-shell/lockscreen" = {
      pipeline = "pipeline_default";
    };

    "org/gnome/shell/extensions/blur-my-shell/overview" = {
      pipeline = "pipeline_default";
    };

    "org/gnome/shell/extensions/blur-my-shell/panel" = {
      brightness = 0.6;
      pipeline = "pipeline_default";
      sigma = 30;
    };

    "org/gnome/shell/extensions/blur-my-shell/screenshot" = {
      pipeline = "pipeline_default";
    };

    "org/gnome/shell/extensions/blur-my-shell/window-list" = {
      brightness = 0.6;
      sigma = 30;
    };

    "org/gnome/shell/extensions/tactile" = {
      col-0 = 0;
      gap-size = 12;
      grid-rows = 3;
      layout-1 = [ "1" ];
      layout-2 = [ "2" ];
      layout-2-col-0 = 1;
      layout-2-col-1 = 1;
      layout-2-col-2 = 1;
      layout-2-col-3 = 1;
      layout-2-row-2 = 0;
      layout-3 = [ "3" ];
      layout-3-row-3 = 0;
      layout-4 = [ "4" ];
      monitor-0-layout = 2;
      monitor-1-layout = 2;
      monitor-2-layout = 2;
      row-0 = 1;
      show-tiles = [ "<Super>e" ];
      tile-0-0 = [ "q" ];
      tile-0-1 = [ "a" ];
      tile-0-2 = [ "z" ];
      tile-0-3 = [ "z" ];
      tile-1-0 = [ "w" ];
      tile-1-1 = [ "s" ];
      tile-1-2 = [ "x" ];
      tile-1-3 = [ "x" ];
      tile-2-0 = [ "e" ];
      tile-2-1 = [ "d" ];
      tile-2-2 = [ "c" ];
      tile-2-3 = [ "c" ];
      tile-3-0 = [ "r" ];
      tile-3-1 = [ "f" ];
      tile-3-2 = [ "v" ];
      tile-3-3 = [ "v" ];
    };

    "org/gnome/shell/extensions/vitals" = {
      hot-sensors = [ "_memory_usage_" "_system_load_1m_" "_processor_usage_" "__temperature_avg__" "__network-rx_max__" "__network-tx_max__" ];
      icon-style = 1;
      show-battery = false;
    };

    "org/gnome/shell/keybindings" = {
      switch-to-application-1 = [];
      switch-to-application-10 = [];
      switch-to-application-2 = [];
      switch-to-application-3 = [];
      switch-to-application-4 = [];
      switch-to-application-5 = [];
      switch-to-application-6 = [];
      switch-to-application-7 = [];
      switch-to-application-8 = [];
      switch-to-application-9 = [];
    };

    "org/gnome/shell/weather" = {
      automatic-location = true;
      locations = [];
    };

    "org/gnome/shell/world-clocks" = {
      locations = [];
    };

    "org/gtk/gtk4/settings/file-chooser" = {
      show-hidden = true;
    };

  };
}
