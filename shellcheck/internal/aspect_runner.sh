#!/bin/sh

set -eu

output="$1"
shift

if [ "${1-}" != "--" ]; then
    echo "aspect_runner: expected '--' after output path, got: ${1-}" >&2
    exit 1
fi
shift

echo "" > "${output}"
exec "$@"
