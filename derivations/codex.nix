{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  fetchurl,
  installShellFiles,
  bubblewrap,
  clang,
  cmake,
  gitMinimal,
  libcap,
  libclang,
  livekit-libwebrtc,
  makeBinaryWrapper,
  pkg-config,
  openssl,
  ripgrep,
  versionCheckHook,
  installShellCompletions ? stdenv.buildPlatform.canExecute stdenv.hostPlatform,
}:

let
  # Bump workflow:
  # 1. Update `version` to the desired upstream stable release without the `rust-v` prefix.
  # 2. Temporarily set `src.hash = lib.fakeHash;` and `cargoHash = lib.fakeHash;`.
  # 3. If the upstream release also changed rusty_v8, update the version in `name`/`url`
  #    below and temporarily set the current platform's `sha256` there to `lib.fakeHash`.
  # 4. Run a build and copy the real hashes from the Nix error output back into this file.
  # 5. Rebuild until the derivation evaluates and builds cleanly.
  version = "0.125.0";

  # This archive version is updated only when upstream Codex moves to a different
  # rusty_v8 release; it does not automatically match `version`.
  librusty_v8 = fetchurl {
    name = "librusty_v8-146.4.0";
    url = "https://github.com/denoland/rusty_v8/releases/download/v146.4.0/librusty_v8_release_${stdenv.hostPlatform.rust.rustcTarget}.a.gz";
    sha256 = {
      x86_64-linux = "sha256-5ktNmeSuKTouhGJEqJuAF4uhA4LBP7WRwfppaPUpEVM=";
      aarch64-linux = "sha256-2/FlsHyBvbBUvARrQ9I+afz3vMGkwbW0d2mDpxBi7Ng=";
      x86_64-darwin = "sha256-YwzSQPG77NsHFBfcGDh6uBz2fFScHFFaC0/Pnrpke7c=";
      aarch64-darwin = "sha256-v+LJvjKlbChUbw+WWCXuaPv2BkBfMQzE4XtEilaM+Yo=";
    }.${stdenv.hostPlatform.system} or (throw ''
      Unsupported system for librusty_v8: ${stdenv.hostPlatform.system}
    '');
    meta = {
      version = "146.4.0";
      sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    };
  };
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "codex";
  inherit version;

  src = fetchFromGitHub {
    owner = "openai";
    repo = "codex";
    tag = "rust-v${finalAttrs.version}";
    # Source hash for the `rust-v${version}` tag.
    hash = "sha256-q175gmBw+edb5+w8TM36yUeFsyIdB1/IwWzbxBbBmoA=";
  };

  sourceRoot = "${finalAttrs.src.name}/codex-rs";

  # Cargo dependency hash for the vendored Rust workspace at this source revision.
  cargoHash = "sha256-fDVlj7zAZnwP9YBaYaSQZXYYWrBm5IEyLT9zoorvzFg=";

  cargoBuildFlags = [
    "--package"
    "codex-cli"
  ];

  cargoCheckFlags = [
    "--package"
    "codex-cli"
  ];

  postPatch = ''
    substituteInPlace $cargoDepsCopy/*/webrtc-sys-*/build.rs \
      --replace-fail "cargo:rustc-link-lib=static=webrtc" "cargo:rustc-link-lib=dylib=webrtc"

    substituteInPlace Cargo.toml \
      --replace-fail 'lto = "fat"' "" \
      --replace-fail 'codegen-units = 1' ""
  '';

  nativeBuildInputs = [
    clang
    cmake
    gitMinimal
    installShellFiles
    makeBinaryWrapper
    pkg-config
  ];

  buildInputs = [
    libclang
    openssl
  ] ++ lib.optionals stdenv.hostPlatform.isLinux [
    libcap
  ];

  env = {
    LIBCLANG_PATH = "${lib.getLib libclang}/lib";
    LK_CUSTOM_WEBRTC = lib.getDev livekit-libwebrtc;
    NIX_CFLAGS_COMPILE = toString (
      lib.optionals stdenv.cc.isGNU [
        "-Wno-error=stringop-overflow"
      ]
      ++ lib.optionals stdenv.cc.isClang [
        "-Wno-error=character-conversion"
      ]
    );
    RUSTY_V8_ARCHIVE = librusty_v8;
  };

  doCheck = false;

  postInstall = lib.optionalString installShellCompletions ''
    installShellCompletion --cmd codex \
      --bash <($out/bin/codex completion bash) \
      --fish <($out/bin/codex completion fish) \
      --zsh <($out/bin/codex completion zsh)
  '';

  postFixup = ''
    wrapProgram $out/bin/codex --prefix PATH : ${
      lib.makeBinPath ([ ripgrep ] ++ lib.optionals stdenv.hostPlatform.isLinux [ bubblewrap ])
    }
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];

  meta = with lib; {
    description = "Lightweight coding agent that runs in your terminal";
    homepage = "https://github.com/openai/codex";
    changelog = "https://raw.githubusercontent.com/openai/codex/refs/tags/rust-v${finalAttrs.version}/CHANGELOG.md";
    license = licenses.asl20;
    mainProgram = "codex";
    platforms = platforms.unix;
  };
})
