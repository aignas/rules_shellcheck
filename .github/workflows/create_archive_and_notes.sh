#!/bin/bash
set -o errexit -o nounset -o pipefail

# Set by GH actions, see
# https://docs.github.com/en/actions/learn-github-actions/environment-variables#default-environment-variables
TAG=${GITHUB_REF_NAME}
if [[ "$TAG" == "master" ]]; then
    TAG="${GITHUB_SHA}"
fi

# A prefix is added to better match the GitHub generated archives.
ARCHIVE="rules_shellcheck-$TAG.tar.gz"
git archive --format=tar "${TAG}" | gzip > "$ARCHIVE"
SHA=$(shasum -a 256 "$ARCHIVE" | awk '{print $1}')

cat > release_notes.txt << EOF
## Using Bzlmod with Bazel 6

**NOTE: bzlmod support is still beta. APIs subject to change.**

Add to your \`MODULE.bazel\` file:

\`\`\`starlark
bazel_dep(name = "rules_shellcheck", version = "${TAG}")
\`\`\`

## Legacy: using WORKSPACE

Paste this snippet into your \`WORKSPACE\` file:

\`\`\`starlark
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "rules_shellcheck",
    sha256 = "${SHA}",
    url = "https://github.com/aignas/rules_shellcheck/releases/download/${TAG}/rules_shellcheck-${TAG}.tar.gz",
)

load("@rules_shellcheck//:deps.bzl", "shellcheck_dependencies")

shellcheck_dependencies()
\`\`\`
EOF
