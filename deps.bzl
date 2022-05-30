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
    version = "v0.8.0"
    sha256 = {
        "darwin_amd64": "e065d4afb2620cc8c1d420a9b3e6243c84ff1a693c1ff0e38f279c8f31e86634",
        "linux_amd64": "ab6ee1b178f014d1b86d1e24da20d1139656c8b0ed34d2867fbb834dad02bf0a",
        "linux_arm64": "9f47bbff5624babfa712eb9d64ece14c6c46327122d0c54983f627ae3a30a4ac",
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
