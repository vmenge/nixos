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
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      kdePackages.xdg-desktop-portal-kde
    ];
  };

  security.pam.services.swaylock = { };
}
