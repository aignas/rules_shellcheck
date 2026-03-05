"""Shellcheck internal test rules"""

# buildifier: disable=bzl-visibility
load(
    "//shellcheck/internal:rules.bzl",
    "ATTRS",
    "shellcheck_test_impl",
)

def _shellcheck_internal_test_impl(ctx):
    return shellcheck_test_impl(ctx, ctx.attr.expect_fail)

shellcheck_internal_test = rule(
    implementation = _shellcheck_internal_test_impl,
    attrs = ATTRS | {
        "expect_fail": attr.bool(
            default = False,
        ),
    },
    test = True,
    toolchains = ["@rules_shellcheck//shellcheck:toolchain_type"],
)
