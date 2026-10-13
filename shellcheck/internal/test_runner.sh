#!/usr/bin/env bash
#
# Runner for `shellcheck_test`. The rule passes its inputs as rlocation paths
# through `SHELLCHECK_TEST_*` environment variables; see `rules.bzl`.

# --- begin runfiles.bash initialization v3 ---
# Copy-pasted from the Bazel Bash runfiles library v3.
set -uo pipefail; set +e; f=bazel_tools/tools/bash/runfiles/runfiles.bash
# shellcheck disable=SC1090
source "${RUNFILES_DIR:-/dev/null}/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -f2- -d' ')" 2>/dev/null || \
  source "$0.runfiles/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.exe.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  { echo>&2 "ERROR: cannot find $f"; exit 1; }; f=; set -e
# --- end runfiles.bash initialization v3 ---

# shellcheck disable=SC2086 # Options are intentionally split on whitespace.
set -- \
    "$(rlocation "${SHELLCHECK_TEST_BIN}")" \
    ${SHELLCHECK_TEST_OPTS} \
    "--rcfile=$(rlocation "${SHELLCHECK_TEST_RCFILE}")"

for file in ${SHELLCHECK_TEST_SOURCE_FILES}; do
    set -- "$@" "--source-path=$(dirname "$(rlocation "${file}")")"
done

for file in ${SHELLCHECK_TEST_FILES}; do
    set -- "$@" "$(rlocation "${file}")"
done

if [[ "${SHELLCHECK_TEST_EXPECT_FAIL}" == "1" ]]; then
    if "$@"; then
        echo "ERROR: expected shellcheck to fail" >&2
        exit 1
    fi
    exit 0
fi

exec "$@"
