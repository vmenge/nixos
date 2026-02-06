# se98-icons.nix
# Packages SE98 icon theme from https://github.com/nestoris/Win98SE
{ pkgs, lib }:

let
  mkPlasmaTheme = import ../utils/mk-plasma-theme.nix { inherit pkgs lib; };
in

mkPlasmaTheme {
  kind = "icons";
  pname = "se98-icons";
  version = "unstable-2026-02-06";
  src = pkgs.fetchFromGitHub {
    owner = "nestoris";
    repo = "Win98SE";
    rev = "master";
    hash = lib.fakeHash;
  };
  sourceSubdir = "SE98";
  themeName = "SE98";
  mode = "single";
  stripTopLevel = false;
  meta = with lib; {
    description = "SE98 icon theme - Windows 98 SE style icons";
    homepage = "https://github.com/nestoris/Win98SE";
    license = licenses.gpl3;
    platforms = platforms.linux;
  };
}
