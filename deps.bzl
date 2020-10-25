def _shellcheck_dependencies_impl(repository_ctx):
    version = "v0.7.1"

    arch = "linux.x86_64"
    sha256 = "64f17152d96d7ec261ad3086ed42d18232fcb65148b44571b564d688269d36c8"

    os_name = repository_ctx.os.name.lower()
    if os_name.startswith("mac os"):
        arch = "darwin.x86_64"
        sha256 = "b080c3b659f7286e27004aa33759664d91e15ef2498ac709a452445d47e3ac23"

    url = "https://github.com/koalaman/shellcheck/releases/download/{version}/shellcheck-{version}.{arch}.tar.xz".format(
        version = version,
        arch = arch,
    )

    repository_ctx.download_and_extract(
        url = url,
        sha256 = sha256,
        stripPrefix = "shellcheck-" + version,
    )

    repository_ctx.file(
        "BUILD",
        """exports_files(["shellcheck"])""",
    )

_shellcheck_dependencies = repository_rule(
    implementation = _shellcheck_dependencies_impl,
)

def shellcheck_dependencies():
    _shellcheck_dependencies(name = "shellcheck")
