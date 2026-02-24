{ pkgs, ... }:
{
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  environment.systemPackages = with pkgs; [
    hyprlock
    hypridle
  ];

  security.pam.services.hyprlock = { };

  environment.sessionVariables.NIXOS_OZONE_WL = "1";
}
