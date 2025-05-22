{ pkgs, ... }:
{

  environment.systemPackages = with pkgs; [
    swayfx
    swaylock-effects
    waybar
  ];

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    config.sway = {
      default = [
        "wlr"
        "gtk"
      ];
    };
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  security.pam.services.swaylock = { };
}
