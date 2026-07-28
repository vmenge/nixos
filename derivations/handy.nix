{
  appimageTools,
  fetchurl,
  lib,
  stdenvNoCC,
}:

let
  pname = "handy";
  version = "0.9.4";

  releases = {
    x86_64-linux = {
      arch = "amd64";
      hash = "sha256-DOnyJ4qXgYFJvIQ1vMswu8tB8vRsMUBGMO9+2PDA6V0=";
    };
    aarch64-linux = {
      arch = "aarch64";
      hash = "sha256-AssWomyfb2rfzW9Bbrf2Gc8KLMW+q+7YI0xl3AqelSc=";
    };
  };

  release =
    releases.${stdenvNoCC.hostPlatform.system}
      or (throw "Handy does not support ${stdenvNoCC.hostPlatform.system}");

  src = fetchurl {
    url = "https://github.com/cjpais/Handy/releases/download/v${version}/Handy_${version}_${release.arch}.AppImage";
    inherit (release) hash;
  };

  appimageContents = appimageTools.extractType2 {
    inherit pname version src;
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -Dm444 "${appimageContents}/Handy.desktop" \
      "$out/share/applications/Handy.desktop"
    install -Dm444 "${appimageContents}/handy.png" \
      "$out/share/icons/hicolor/128x128/apps/handy.png"
  '';

  meta = {
    description = "Offline speech-to-text application";
    homepage = "https://github.com/cjpais/Handy";
    license = lib.licenses.mit;
    mainProgram = "handy";
    platforms = builtins.attrNames releases;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
