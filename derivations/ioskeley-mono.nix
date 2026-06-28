{ pkgs, lib }:

pkgs.stdenvNoCC.mkDerivation rec {
  pname = "ioskeley-mono";
  version = "2.0.0";

  src = pkgs.fetchzip {
    url = "https://github.com/ahatem/IoskeleyMono/releases/download/v${version}/IoskeleyMono.zip";
    stripRoot = false;
    hash = "sha256-EJDlA18XZPq7vhtpw/74n5s1NmTy0/DLu2oYB7OuvbA=";
  };

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    while IFS= read -r -d "" font; do
      rel=''${font#"$src"/}
      install -Dm444 "$font" "$out/share/fonts/truetype/ioskeley-mono/$rel"
    done < <(find "$src" -type f -name "*.ttf" -print0)

    runHook postInstall
  '';

  meta = with lib; {
    description = "Free Iosevka-based alternative to Berkeley Mono";
    homepage = "https://github.com/ahatem/IoskeleyMono";
    license = licenses.ofl;
    platforms = platforms.all;
  };
}
