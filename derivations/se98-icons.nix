# se98-icons.nix
# Packages SE98 icon theme from https://github.com/nestoris/Win98SE
{ pkgs, lib }:

pkgs.stdenvNoCC.mkDerivation {
  pname = "se98-icons";
  version = "unstable-2026-02-06";

  src = pkgs.fetchFromGitHub {
    owner = "nestoris";
    repo = "Win98SE";
    rev = "master";
    hash = "sha256-ixX7WAMvrw/Rwam6LNV8zz/cClwRLYuxtAMzMmwdXWk=";
  };

  dontBuild = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share/icons"
    cp -R SE98 "$out/share/icons/"

    runHook postInstall
  '';

  meta = with lib; {
    description = "SE98 icon theme - Windows 98 SE style icons";
    homepage = "https://github.com/nestoris/Win98SE";
    license = licenses.gpl3;
    platforms = platforms.linux;
  };
}
