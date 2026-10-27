#!/usr/bin/env bash
# Install the Syft release pinned in tools/syft.lock into .tools/bin, verifying
# the tarball's SHA-256 against the committed lock file.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
lock="$root/tools/syft.lock"
version="$(sed -n 's/^version=//p' "$lock")"
arch="$(uname -m | sed 's/x86_64/amd64/')"
tarball="syft_${version}_darwin_${arch}.tar.gz"
bin_dir="$root/.tools/bin"

if [ -x "$bin_dir/syft" ] && "$bin_dir/syft" --version | grep -qx "syft $version"; then
	echo "sbom/install: syft $version already installed"
	exit 0
fi

expected="$(awk -v t="$tarball" '$2 == t { print $1 }' "$lock")"
[ -n "$expected" ] || { echo "sbom/install: no checksum for $tarball in $lock" >&2; exit 1; }

work="$(mktemp -d "${TMPDIR:-/tmp}/uictl.XXXXXX")"
trap 'rm -rf "$work"' EXIT
curl -fsSL -o "$work/$tarball" "https://github.com/anchore/syft/releases/download/v${version}/${tarball}"
actual="$(shasum -a 256 "$work/$tarball" | awk '{ print $1 }')"
[ "$actual" = "$expected" ] || { echo "sbom/install: checksum mismatch for $tarball" >&2; exit 1; }

mkdir -p "$bin_dir"
tar -xzf "$work/$tarball" -C "$bin_dir" syft
echo "sbom/install: installed syft $version to $bin_dir"
