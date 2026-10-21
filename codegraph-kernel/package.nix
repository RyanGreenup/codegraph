{
  lib,
  stdenv,
  rustPlatform,
  nodejs_24,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "codegraph-kernel";
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./Cargo.toml
      ./Cargo.lock
      ./build.rs
      ./src
      ./grammars
    ];
  };

  cargoLock.lockFile = ./Cargo.lock;

  installPhase = ''
    runHook preInstall
    install -Dm755 target/${stdenv.hostPlatform.rust.rustcTargetSpec}/release/libcodegraph_kernel.${
      if stdenv.hostPlatform.isDarwin then "dylib" else "so"
    } "$out/lib/codegraph-kernel.node"
    runHook postInstall
  '';

  nativeInstallCheckInputs = [ nodejs_24 ];
  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    ${nodejs_24}/bin/node -e 'const k = require(process.argv[1]); if (typeof k.extractFile !== "function" || typeof k.contractInfo !== "function") process.exit(1)' "$out/lib/codegraph-kernel.node"
    runHook postInstallCheck
  '';

  meta = {
    description = "Native extraction addon for CodeGraph";
    homepage = "https://github.com/colbymchenry/codegraph";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    mainProgram = "codegraph-kernel.node";
  };
})
