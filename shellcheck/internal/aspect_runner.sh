#!/bin/sh

set -eu

echo "" > "${SHELLCHECK_ASPECT_OUTPUT}"
exec "$@"
