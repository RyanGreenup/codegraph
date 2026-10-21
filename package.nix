{
  lib,
  buildNpmPackage,
  importNpmLock,
  nodejs_24,
  codegraphKernel,
  versionCheckHook,
}:

buildNpmPackage (finalAttrs: {
  pname = "codegraph";
  version = (lib.importJSON ./package.json).version;

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./package.json
      ./package-lock.json
      ./tsconfig.json
      ./LICENSE
      ./README.md
      ./src
      ./scripts/check-ui-build.mjs
      ./ui/package.json
      ./ui/index.html
      ./ui/tsconfig.json
      ./ui/svelte.config.js
      ./ui/vite.config.ts
      ./ui/src
    ];
  };

  nodejs = nodejs_24;
  npmDeps = importNpmLock { npmRoot = ./.; };
  npmConfigHook = importNpmLock.npmConfigHook;

  # npm hoists some workspace tools into ui/node_modules, outside the tree
  # patched by importNpmLock.npmConfigHook.
  preBuild = ''
    patchShebangs ui/node_modules
  '';

  postInstall = ''
    install -Dm755 ${codegraphKernel}/lib/codegraph-kernel.node \
      "$out/lib/node_modules/@colbymchenry/codegraph/kernel/codegraph-kernel.node"
    # The private UI workspace has already produced dist/viewer; npm's
    # workspace link points to ui/, which is not part of the runtime package.
    rm "$out/lib/node_modules/@colbymchenry/codegraph/node_modules/@colbymchenry/codegraph-ui"
  '';

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;

  meta = {
    description = "Local code intelligence CLI for coding agents";
    homepage = "https://github.com/colbymchenry/codegraph";
    license = lib.licenses.mit;
    mainProgram = "codegraph";
    platforms = lib.platforms.unix;
  };
})
