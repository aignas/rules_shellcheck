def _shellcheck_dependencies_impl(repository_ctx):
    version = "v0.8.0"

    os_name = repository_ctx.os.name.lower()
    if os_name.startswith("mac os"):
        arch = "darwin.x86_64"
        sha256 = "e065d4afb2620cc8c1d420a9b3e6243c84ff1a693c1ff0e38f279c8f31e86634"
    elif getattr(repository_ctx.os, "arch", None) == "aarch64":
        arch = "linux.aarch64"
        sha256 = "9f47bbff5624babfa712eb9d64ece14c6c46327122d0c54983f627ae3a30a4ac"
    else:
        arch = "linux.x86_64"
        sha256 = "ab6ee1b178f014d1b86d1e24da20d1139656c8b0ed34d2867fbb834dad02bf0a"

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
