{ lib, stdenvNoCC, fetchurl }:

let
  version = "0.6.5-nightly.7afef14";
  release = {
    x86_64-linux = {
      target = "x86_64-unknown-linux-musl";
      hash = "sha256-4HgcZZSLVOQLwp4LA9M1nWWS0BMsK4T+tvzvCy07Hio=";
    };
  }.${stdenvNoCC.hostPlatform.system} or (throw ''
    Unsupported system for fff-mcp: ${stdenvNoCC.hostPlatform.system}
  '');
in
stdenvNoCC.mkDerivation rec {
  pname = "fff-mcp";
  inherit version;

  src = fetchurl {
    url = "https://github.com/dmtrKovalenko/fff.nvim/releases/download/${version}/${pname}-${release.target}";
    hash = release.hash;
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 "$src" "$out/bin/${pname}"
    runHook postInstall
  '';

  meta = with lib; {
    description = "FFF MCP server";
    homepage = "https://github.com/dmtrKovalenko/fff.nvim";
    license = licenses.mit;
    mainProgram = pname;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
}
