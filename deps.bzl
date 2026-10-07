"""Provides shellcheck dependencies on all supported platforms:
- Linux x86_64, ARM64 and ARMv6
- macOS x86_64 and ARM64
- Windows x86_64
"""

# buildifier: disable=bzl-visibility
load("//shellcheck/internal:extensions.bzl", _shellcheck_dependencies = "shellcheck_dependencies")

shellcheck_dependencies = _shellcheck_dependencies
