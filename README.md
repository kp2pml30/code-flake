# code-flake

Nix flake that provides a pinned version of VS Code, updated automatically via GitHub Actions. Vibecoded.

## Usage

```nix
# flake.nix
{
  inputs.code-flake.url = "github:OWNER/code-flake";

  outputs = { self, code-flake, ... }: {
    # Use as a package
    environment.systemPackages = [ code-flake.packages.${system}.default ];
  };
}
```

Or run directly:

```sh
nix run github:OWNER/code-flake
```

## Supported systems

| Nix system | VS Code target |
|---|---|
| `x86_64-linux` | `linux-x64` |
| `armv7l-linux` | `linux-armhf` |
| `aarch64-linux` | `linux-arm64` |
| `x86_64-darwin` | `darwin` |
| `aarch64-darwin` | `darwin-arm64` |

## How it works

- `data.json` stores the current VS Code version and pre-fetched hashes for each platform
- `systems.json` maps Nix system names to VS Code download targets
- `flake.nix` overrides `pkgs.vscode` with the pinned version and hash
- A GitHub Action runs daily and checks for new releases from [microsoft/vscode](https://github.com/microsoft/vscode/releases), prefetches all platform tarballs, and commits the updated `data.json`

## Manual update

```sh
nix develop -c python3 update/update.py
```

Options:

- `--version <version>` — update to a specific version instead of latest
- `--force` — re-fetch hashes even if the version hasn't changed

## Disclaimer

This project is not affiliated with or endorsed by Microsoft. VS Code is a product of Microsoft Corporation.
