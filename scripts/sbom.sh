#!/usr/bin/env bash
# Write a CycloneDX JSON SBOM for the uictl package to <dir>/bom.json using the
# Syft version pinned in tools/syft.lock.
# Usage: sbom.sh <output-dir> [--skip-if-missing]
set -euo pipefail

out_dir="${1:?usage: sbom.sh <output-dir> [--skip-if-missing]}"
skip_if_missing=false
[ "${2:-}" = "--skip-if-missing" ] && skip_if_missing=true

root="$(cd "$(dirname "$0")/.." && pwd)"
syft="${SYFT:-$root/.tools/bin/syft}"
want="$(sed -n 's/^version=//p' "$root/tools/syft.lock")"

if [ ! -x "$syft" ] || ! "$syft" --version 2>/dev/null | grep -qx "syft $want"; then
	if $skip_if_missing; then
		echo "sbom: syft $want not installed; skipping (run 'make sbom/install')" >&2
		exit 0
	fi
	echo "sbom: syft $want not found at $syft; run 'make sbom/install'" >&2
	exit 1
fi

mkdir -p "$out_dir"
# Package.resolved pins the full shipped dependency closure. Syft also lists the
# scanned file itself as a component, which is not a library, so drop it.
SYFT_CHECK_FOR_APP_UPDATE=false "$syft" scan "file:$root/Package.resolved" -q \
	--source-name uictl -o cyclonedx-json |
	jq '.components |= map(select(.type != "file"))' >"$out_dir/bom.json"
echo "sbom: wrote $(cd "$out_dir" && pwd)/bom.json" >&2
