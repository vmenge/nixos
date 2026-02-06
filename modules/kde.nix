{ pkgs, lib, ... }:
let
  kde-windows-98-theme = import ../derivations/kde-windows-98-theme.nix { inherit pkgs lib; };
  reactionary-theme = import ../derivations/reactionary-theme.nix { inherit pkgs lib; };
  se98-icons = import ../derivations/se98-icons.nix { inherit pkgs lib; };
  modernxp-cursor = import ../derivations/modernxp-cursor.nix { inherit pkgs lib; };
in
{
  services.desktopManager.plasma6.enable = true;
  environment.systemPackages = [
    kde-windows-98-theme
    reactionary-theme
    se98-icons
    modernxp-cursor
  ];
}
