"""shellcheck_test"""

load(
    "//shellcheck/internal:rules.bzl",
    _shellcheck_test = "shellcheck_test",
)

shellcheck_test = _shellcheck_test
