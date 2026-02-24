{ pkgs, ... }:
{

  programs.sway = {
    enable = true;
    package = pkgs.swayfx;
  };

  environment.systemPackages = with pkgs; [
    swaylock-effects
    waybar
  ];

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      kdePackages.xdg-desktop-portal-kde
    ];
  };

  security.pam.services.swaylock = { };
}
