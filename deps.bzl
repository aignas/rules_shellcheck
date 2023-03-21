"""Provides shellcheck dependencies on all supported platforms:
- Linux 64-bit and ARM64
- OSX 64-bit
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

_LABELS = {
    "darwin_amd64": "darwin.x86_64",
    "linux_amd64": "linux.x86_64",
    "linux_arm64": "linux.aarch64",
    # darwin_arm64 shellcheck binaries are not distributed from GitHub releases.
    # windows_amd64 shellcheck binaries are not distributed from GitHub releases.
}

def _urls(arch, version):
    return [
        "https://github.com/koalaman/shellcheck/releases/download/{version}/shellcheck-{version}.{arch}.tar.xz".format(
            version = version,
            arch = _LABELS[arch],
        ),
    ]

def shellcheck_dependencies():
    version = "v0.9.0"
    sha256 = {
        "darwin_amd64": "7d3730694707605d6e60cec4efcb79a0632d61babc035aa16cda1b897536acf5",
        "linux_amd64": "700324c6dd0ebea0117591c6cc9d7350d9c7c5c287acbad7630fa17b1d4d9e2f",
        "linux_arm64": "179c579ef3481317d130adebede74a34dbbc2df961a70916dd4039ebf0735fae",
    }

    for arch, sha256 in sha256.items():
        maybe(
            http_archive,
            name = "shellcheck_{arch}".format(arch = arch),
            build_file_content = """exports_files(["shellcheck"])
""",
            strip_prefix = "shellcheck-{version}".format(version = version),
            sha256 = sha256,
            urls = _urls(arch = arch, version = version),
        )
