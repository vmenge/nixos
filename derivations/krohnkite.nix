# krohnkite.nix
# A dynamic tiling script for KWin (Plasma 6 fork)
# https://github.com/anametologin/krohnkite
{ pkgs, lib }:

pkgs.stdenvNoCC.mkDerivation rec {
  pname = "krohnkite";
  version = "0.9.8";

  src = pkgs.fetchFromGitHub {
    owner = "anametologin";
    repo = "krohnkite";
    rev = "master";
    hash = "sha256-9sT2VDKFjaSTN1I5bacdfFk1VzzqiV+E9z44soSKHvw=";
  };

  nativeBuildInputs = with pkgs; [
    typescript
  ];

  buildPhase = ''
    runHook preBuild

    # Compile TypeScript directly (no npm needed)
    tsc

    # Build the package structure
    mkdir -p pkg/contents/ui pkg/contents/code pkg/contents/config

    # metadata.json with version substituted
    sed "s/\$VER/${version}/" res/metadata.json \
      | sed "s/\$REV/nix/" \
      > pkg/metadata.json

    # Copy QML and UI files
    cp res/main.qml pkg/contents/ui/
    cp res/config.ui pkg/contents/ui/
    cp res/dbus.qml pkg/contents/ui/
    cp res/popup.qml pkg/contents/ui/
    cp res/shortcuts.qml pkg/contents/ui/

    # Copy scripts
    cp res/main.js pkg/contents/code/
    cp krohnkite.js pkg/contents/code/script.js

    # Copy config
    cp res/config.xml pkg/contents/config/main.xml

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share/kwin/scripts/krohnkite"
    cp -r pkg/* "$out/share/kwin/scripts/krohnkite/"

    runHook postInstall
  '';

  meta = with lib; {
    description = "A dynamic tiling extension for KWin (Plasma 6)";
    homepage = "https://github.com/anametologin/krohnkite";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
