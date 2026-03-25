{ pkgs, lib }:

pkgs.stdenvNoCC.mkDerivation {
  pname = "consolas-nerd-font";
  version = "unstable-2023-10-23";

  src = pkgs.fetchFromGitHub {
    owner = "banDeveloper";
    repo = "Consolas-Nerd-Font";
    rev = "7437e8112f3234e15cf557d0101af0a2b2405a54";
    hash = "sha256-Oi+M/mPsImZ4+Fq85N21qU555Wph9Z9IJ8Q4V40w2Pw=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share/fonts/truetype"
    install -Dm644 ConsolasNerdFont-Regular.ttf "$out/share/fonts/truetype/ConsolasNerdFont-Regular.ttf"
    install -Dm644 ConsolasNerdFont-Italic.ttf "$out/share/fonts/truetype/ConsolasNerdFont-Italic.ttf"
    install -Dm644 ConsolasNerdFont-Bold.ttf "$out/share/fonts/truetype/ConsolasNerdFont-Bold.ttf"
    install -Dm644 ConsolasNerdFont-BoldItalic.ttf "$out/share/fonts/truetype/ConsolasNerdFont-BoldItalic.ttf"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Consolas patched with Nerd Fonts glyphs";
    homepage = "https://github.com/banDeveloper/Consolas-Nerd-Font";
    license = licenses.unfree;
    platforms = platforms.all;
  };
}
