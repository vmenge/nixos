{ pkgs, ... }:
{
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  services.gnome.core-apps.enable = true;
  services.gnome.core-developer-tools.enable = false;
  services.gnome.games.enable = false;

  environment.gnome.excludePackages = with pkgs; [
    epiphany    # browser
    gedit       # text editor
    simple-scan # document scanner
    totem       # video player
    evince      # document viewer
    geary       # email client
    seahorse    # password manager
    yelp        # help viewer
    gnome-contacts
    gnome-maps
    gnome-music
    gnome-connections
    gnome-weather
    gnome-tour
  ];
}
