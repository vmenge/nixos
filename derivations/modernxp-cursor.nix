# modernxp-cursor.nix
# Packages ModernXP cursor theme from https://github.com/na0miluv/modernXP-cursor-theme
# This needs to be built from SVG sources
{ pkgs, lib }:

pkgs.stdenvNoCC.mkDerivation {
  pname = "modernxp-cursor";
  version = "unstable-2026-02-06";

  src = pkgs.fetchFromGitHub {
    owner = "na0miluv";
    repo = "modernXP-cursor-theme";
    rev = "main";
    hash = "sha256-1Pv+Ny1Gt7NM3cB038oQXb1cGIgg0VNxuO1IApTWo5U=";
  };

  nativeBuildInputs = with pkgs; [
    inkscape
    xorg.xcursorgen
  ];

  buildPhase = ''
    runHook preBuild

    bash build.sh

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share/icons"
    cp -R ModernXP "$out/share/icons/" || cp -R dist/* "$out/share/icons/" || cp -R out/* "$out/share/icons/"

    runHook postInstall
  '';

  meta = with lib; {
    description = "ModernXP cursor theme - pixel-perfect Windows XP cursors with modern scaling";
    homepage = "https://github.com/na0miluv/modernXP-cursor-theme";
    license = licenses.gpl3;
    platforms = platforms.linux;
  };
}
