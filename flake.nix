{
  description = "VS Code with pinned version";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
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
          });
        };

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
