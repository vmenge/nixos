{ pkgs, lib, ... }:
let
  kde-windows-98-theme = import ../derivations/kde-windows-98-theme.nix { inherit pkgs lib; };
in
{
  services.desktopManager.plasma6.enable = true;
  environment.systemPackages = [
    kde-windows-98-theme
  ];
}
