# krohnkite.nix
# A dynamic tiling script for KWin
# https://github.com/esjeon/krohnkite
{ pkgs, lib }:

pkgs.stdenvNoCC.mkDerivation rec {
  pname = "krohnkite";
  version = "0.8.2";

  src = pkgs.fetchFromGitHub {
    owner = "esjeon";
    repo = "krohnkite";
    rev = "master";
    hash = lib.fakeHash;
  };

  nativeBuildInputs = with pkgs; [
    typescript
  ];

  buildPhase = ''
    runHook preBuild

    # Compile TypeScript
    tsc

    # Build the package structure
    mkdir -p pkg/contents/ui pkg/contents/code pkg/contents/config

    # metadata.desktop with version substituted
    sed "s/\$VER/${version}/" res/metadata.desktop \
      | sed "s/\$REV/nix/" \
      > pkg/metadata.desktop

    # Copy QML and UI files
    cp res/main.qml pkg/contents/ui/
    cp res/config.ui pkg/contents/ui/
    cp res/popup.qml pkg/contents/ui/

    # Copy compiled script
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
    description = "A dynamic tiling extension for KWin";
    homepage = "https://github.com/esjeon/krohnkite";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
