"""shellcheck_aspect"""

load(
    "//shellcheck/internal:rules.bzl",
    _shellcheck_aspect = "shellcheck_aspect",
)

shellcheck_aspect = _shellcheck_aspect
