#!/usr/bin/env python3

import json
import subprocess
import sys
from pathlib import Path
from urllib.request import urlopen
import argparse

parser = argparse.ArgumentParser(description="Update VS Code version")
parser.add_argument("--version", type=str, help="Version to update to")
parser.add_argument("--force", action="store_true", help="Force update even if version is the same")
args = parser.parse_args()

ROOT = Path(__file__).resolve().parent.parent
DATA_JSON = ROOT / "data.json"
SYSTEMS_JSON = ROOT / "systems.json"


def get_latest_version() -> str:
	with urlopen("https://api.github.com/repos/microsoft/vscode/releases/latest") as resp:
		return json.loads(resp.read())["tag_name"]


def nix_prefetch(url: str) -> str:
	hash_hex = subprocess.check_output(
		["nix-prefetch-url", "--unpack", url, "--type", "sha256"],
		text=True,
	).strip()
	print(f'\t{url} -> {hash_hex}')
	# builtins.fetchTarball uses sha256:<base32>, convert from sri sha256-<base64>
	return "sha256:" + subprocess.check_output(
		["nix", "hash", "convert", "--hash-algo", "sha256", "--to", "nix32", hash_hex],
		text=True,
	).strip()


def main():
	systems = json.loads(SYSTEMS_JSON.read_text())
	data = json.loads(DATA_JSON.read_text())
	current = data["version"]
	if args.version:
		latest = args.version
	else:
		latest = get_latest_version()

	print(f"Current: {current}")
	print(f"Latest:  {latest}")

	if latest == current:
		print("Already up to date.")
		if not args.force:
			return
		print("Forcing update...")

	print(f"Updating to {latest}...")

	hashes = {}
	for nix_system, vscode_system in systems.items():
		url = f"https://update.code.visualstudio.com/{latest}/{vscode_system}/stable"
		print(f"Prefetching {vscode_system}...")
		hashes[vscode_system] = nix_prefetch(url)
		print(f"  {hashes[vscode_system]}")

	data["version"] = latest
	data["hashes"] = hashes
	DATA_JSON.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n")

	print("Updated data.json")


if __name__ == "__main__":
	main()
