#!/usr/bin/env bash
# Build the rules_shellcheck release archive and emit release notes.
# Invoked by bazel-contrib/.github/.github/workflows/release_ruleset.yaml
# at the hardcoded path `.github/workflows/release_prep.sh`.
#
# Args:
#   $1: tag name (e.g. 0.4.0). Passed through as the --embed_label
#       value so the archive is stamped with the release version.
#
# Side effects:
#   Writes rules_shellcheck-${TAG}.tar.gz to the current directory —
#   the location the `release_files` glob in release.yml expects.
#
# Output:
#   Release notes to stdout. The reusable workflow redirects stdout
#   into release_notes.txt for the GitHub release body; every other
#   line goes to stderr so it doesn't pollute the notes.

set -euo pipefail

# Redirect stdout to stderr; keep fd 3 for the final release-notes write.
exec 3>&1 1>&2

TAG="${1:?tag_name required}"

# MODULE.bazel is checked in with a placeholder `version = "0.0.0"`.
# Stamp the release tag in before packaging so the MODULE.bazel
# inside the published archive matches the version BCR sees.
sed -i -E "s/^([[:space:]]*version = )\"0\.0\.0\"/\1\"${TAG}\"/" MODULE.bazel
if ! grep -qE "^[[:space:]]*version = \"${TAG}\"" MODULE.bazel; then
    echo "ERROR: failed to stamp version ${TAG} into MODULE.bazel" >&2
    exit 1
fi

# Reuse the existing //:release target — same tarball and rendered
# notes that ci/package.sh produces for PR validation, minus the
# example-validation loop (release_ruleset already runs bazel test).
bazel run --stamp --embed_label "${TAG}" //:release -- release

# //:release writes into ./release/; move the archive up so the
# `release_files: rules_shellcheck-*.tar.gz` glob picks it up.
mv "release/rules_shellcheck-${TAG}.tar.gz" .

cat "release/release_notes.md" >&3
