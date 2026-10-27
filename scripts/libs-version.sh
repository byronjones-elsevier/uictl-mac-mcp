#!/usr/bin/env bash
# Print every direct and transitive library the uictl binary ships, one
# "name  version" pair per line, aligned in columns and sorted by name.
# Test and dev-only dependencies are not in the uictl target's graph.
set -euo pipefail

command -v swift >/dev/null || { echo "libs-version: swift toolchain not found" >&2; exit 1; }
command -v jq >/dev/null || { echo "libs-version: jq not found" >&2; exit 1; }

swift package show-dependencies --format json |
	jq -r '[.. | objects | select(has("dependencies")) | .dependencies[]]
		| unique_by(.name) | .[] | "\(.name)\t\(.version)"' |
	LC_ALL=C sort -f |
	awk -F'\t' '{ n[NR] = $1; v[NR] = $2; if (length($1) > w) w = length($1) }
		END { for (i = 1; i <= NR; i++) printf "%-*s  %s\n", w, n[i], v[i] }'
