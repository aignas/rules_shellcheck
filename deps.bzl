"""Provides shellcheck dependencies on all supported platforms:
- Linux 64-bit and ARM64
- OSX 64-bit
"""

load("//shellcheck/internal:extensions.bzl", _shellcheck_dependencies = "shellcheck_dependencies")

shellcheck_dependencies = _shellcheck_dependencies
