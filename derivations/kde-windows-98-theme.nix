# kde-windows-98-theme.nix
{ pkgs, lib }:

let
  mkPlasmaTheme = import ../utils/mk-plasma-theme.nix { inherit pkgs lib; };

  src = pkgs.fetchFromGitHub {
    owner = "Die4Ever";
    repo = "KDE-Windows-98-Theme";
    rev = "main";
    hash = lib.fakeHash; # replace after first build
  };

  lookAndFeel = mkPlasmaTheme {
    kind = "lookAndFeel";
    pname = "kde-windows-98-look-and-feel";
    version = "unstable-2026-02-06";
    src = "${src}/look-and-feel";
    mode = "collection";
    stripTopLevel = false;
  };

  aurorae = mkPlasmaTheme {
    kind = "aurorae";
    pname = "kde-windows-98-aurorae";
    version = "unstable-2026-02-06";
    src = src;
    mode = "collection";
    stripTopLevel = false;
    includeGlobs = [ "*aurorae" ]; # only the aurorae theme dirs
  };

  colorSchemes = mkPlasmaTheme {
    kind = "colorSchemes";
    pname = "kde-windows-98-color-schemes";
    version = "unstable-2026-02-06";
    src = src;
    mode = "collection";
    stripTopLevel = false;
    includeGlobs = [ "*.colors" ]; # only the colorscheme files at repo root
  };
in

pkgs.symlinkJoin {
  name = "kde-windows-98-theme";
  paths = [
    lookAndFeel
    aurorae
    colorSchemes
  ];
  meta = with lib; {
    description = "Die4Ever KDE Windows 95/98/ME bundle (Look-and-Feel + Aurorae + color schemes)";
    homepage = "https://github.com/Die4Ever/KDE-Windows-98-Theme";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
  };
}
