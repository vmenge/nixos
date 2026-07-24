{
  lib,
  stdenvNoCC,
  fetchurl,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "plannotator";
  version = "0.24.2";

  src = fetchurl {
    url = "https://github.com/backnotprop/plannotator/releases/download/v${finalAttrs.version}/plannotator-linux-x64";
    hash = "sha256-6cyScQhh/1hD8XQmst/I4NKWEwxmciRBAejBUy8f2A0=";
  };

  dontUnpack = true;
  # Bun embeds the compiled application in the executable's trailer. Generic
  # ELF fixups corrupt its offsets and make the binary launch as plain Bun.
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 "$src" "$out/bin/plannotator"
    runHook postInstall
  '';

  meta = {
    description = "Visual review and annotation tool for coding agent plans and diffs";
    homepage = "https://github.com/backnotprop/plannotator";
    license = with lib.licenses; [
      asl20
      mit
    ];
    mainProgram = "plannotator";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})
