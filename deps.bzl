load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def _shellcheck_dep(name, version, arch, sha256):
    http_archive(
        name = name,
        build_file_content = """exports_files(["shellcheck"])
        """,
        sha256 = sha256,
        strip_prefix = "shellcheck-" + version,
        urls = [
            "https://github.com/koalaman/shellcheck/releases/download/{version}/shellcheck-{version}.{arch}.tar.xz".format(
                version = version,
                arch = arch,
            ),
        ],
    )


def shellcheck_dependencies():
    _shellcheck_dep(
        name = "shellcheck_darwin",
        version = "v0.7.1",
        arch = "darwin.x86_64",
        sha256 = "b080c3b659f7286e27004aa33759664d91e15ef2498ac709a452445d47e3ac23",
    )

    _shellcheck_dep(
        name = "shellcheck_linux_x86_64",
        version = "v0.7.1",
        arch = "linux.x86_64",
        sha256 = "64f17152d96d7ec261ad3086ed42d18232fcb65148b44571b564d688269d36c8",
    )
