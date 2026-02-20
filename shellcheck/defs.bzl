"""# Shellcheck rules"""

load(
    ":shellcheck_aspect.bzl",
    _shellcheck_aspect = "shellcheck_aspect",
)
load(
    ":shellcheck_test.bzl",
    _shellcheck_test = "shellcheck_test",
)

shellcheck_test = _shellcheck_test
shellcheck_aspect = _shellcheck_aspect
