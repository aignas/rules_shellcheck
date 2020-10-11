load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def shellcheck_dependencies(
        arch = "linux.x86_64",
        version = "v0.7.1",
        sha256 = "64f17152d96d7ec261ad3086ed42d18232fcb65148b44571b564d688269d36c8"):
    http_archive(
        name = "shellcheck",
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
