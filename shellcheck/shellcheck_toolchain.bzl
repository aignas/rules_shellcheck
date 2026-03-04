"""shellcheck_toolchain"""

load(
    "//shellcheck/internal:toolchain.bzl",
    _shellcheck_toolchain = "shellcheck_toolchain",
)

shellcheck_toolchain = _shellcheck_toolchain
