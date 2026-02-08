# reactionary-theme.nix
# Packages the Reactionary theme suite from https://www.opencode.net/phob1an/reactionary
# Includes: reactplus (plasma theme) and Reactionary wallpaper
{ pkgs, lib }:

let
  mkPlasmaTheme = import ../utils/mk-plasma-theme.nix { inherit pkgs lib; };

  src = pkgs.fetchgit {
    url = "https://www.opencode.net/phob1an/reactionary.git";
    rev = "4aa2d20f0e93ae4387a90947fcc6c90940c18122";
    hash = "sha256-obKYi85SEMSvoF9KY8TbU02mag57yr/03TvNNNa67N0=";
  };

  desktopTheme = mkPlasmaTheme {
    kind = "desktoptheme";
    pname = "reactplus-plasma-theme";
    version = "unstable-2026-02-06";
    src = src;
    sourceSubdir = "PLUS/desktoptheme";
    mode = "collection";
    stripTopLevel = false;
  };

  wallpaper = mkPlasmaTheme {
    kind = "wallpapers";
    pname = "reactionary-wallpaper";
    version = "unstable-2026-02-06";
    src = src;
    sourceSubdir = "wallpapers";
    mode = "collection";
    stripTopLevel = false;
  };
in

pkgs.symlinkJoin {
  name = "reactionary-theme";
  paths = [
    desktopTheme
    wallpaper
  ];
  meta = with lib; {
    description = "Reactionary Plus plasma theme and wallpaper";
    homepage = "https://www.opencode.net/phob1an/reactionary";
    license = licenses.gpl2Plus;
    platforms = platforms.linux;
  };
}
