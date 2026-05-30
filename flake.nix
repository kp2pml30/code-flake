{
  description = "VS Code with pinned version";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = builtins.fromJSON (builtins.readFile ./systems.json);
      supportedSystems = builtins.attrNames systems;
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      data = builtins.fromJSON (builtins.readFile ./data.json);
    in
    {
      overlays.default = final: prev:
        let
          vscodeSystem = systems.${final.system};
        in
        {
          vscode = prev.vscode.overrideAttrs (oldAttrs: rec {
            version = data.version;
            src = builtins.fetchTarball {
              url = "https://update.code.visualstudio.com/${version}/${vscodeSystem}/stable";
              sha256 = data.hashes.${vscodeSystem};
            };
            buildInputs = (oldAttrs.buildInputs or [])
              ++ final.lib.optionals final.stdenv.hostPlatform.isLinux [ final.musl ];
            # Upstream renamed `@vscode/ripgrep` to `@vscode/ripgrep-universal`
            # in 1.122 and moved the binary under a per-arch subdirectory.
            # Retarget nixpkgs' postPatch at the new location so vscode actually
            # picks up the nixpkgs-provided ripgrep.
            postPatch =
              let
                rgArch = if final.stdenv.hostPlatform.isAarch64 then "linux-arm64" else "linux-x64";
                oldRg = "resources/app/node_modules/@vscode/ripgrep/bin/rg";
                newRg = "resources/app/node_modules/@vscode/ripgrep-universal/bin/${rgArch}/rg";
              in
              builtins.replaceStrings [ oldRg ] [ newRg ] (oldAttrs.postPatch or "");
          });
        };

      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ self.overlays.default ];
          };
        in
        {
          inherit (pkgs) vscode;
          default = pkgs.vscode;
        }
      );

      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.python3
              pkgs.nix
            ];
          };
        }
      );
    };
}
