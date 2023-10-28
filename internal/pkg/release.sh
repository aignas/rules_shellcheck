#!/bin/bash
set -euo pipefail

DST="${BUILD_WORKSPACE_DIRECTORY}/$1"
TAG="${2:-${BUILD_EMBED_LABEL}}"

mkdir -p "$DST"

RELEASE_ARCHIVE="$DST/rules_shellcheck-$TAG.tar.gz"
RELEASE_NOTES="$DST/release_notes.md"

cp -v "$ARCHIVE" "$RELEASE_ARCHIVE"
SHA=$(sha256sum "$RELEASE_ARCHIVE" | awk '{print $1}')

sed \
  -e "s/%%TAG%%/$1/g" \
  -e "s/%%SHA256%%/$SHA/g" \
  "${RELEASE_NOTES_TEMPLATE}" \
  > "$RELEASE_NOTES"
