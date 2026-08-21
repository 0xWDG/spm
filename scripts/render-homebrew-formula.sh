#!/bin/sh

set -eu

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
    echo "Usage: $0 <version> <sha256> [output]" >&2
    exit 2
fi

version="$1"
checksum="$2"
output="${3:-build/homebrew/spm.rb}"
template="packaging/homebrew/spm.rb.in"

if ! printf '%s' "$version" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?$'; then
    echo "Invalid semantic version: $version" >&2
    exit 2
fi

if ! printf '%s' "$checksum" | grep -Eq '^[0-9a-f]{64}$'; then
    echo "Invalid SHA-256 checksum" >&2
    exit 2
fi

if [ ! -f "$template" ]; then
    echo "Formula template not found: $template" >&2
    exit 1
fi

mkdir -p "$(dirname "$output")"
sed \
    -e "s/__VERSION__/$version/g" \
    -e "s/__SHA256__/$checksum/g" \
    "$template" > "$output"

echo "Rendered $output for spm $version"
