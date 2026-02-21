"""Provides shellcheck dependencies on all supported platforms:
- Linux 64-bit and ARM64
- OSX 64-bit
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

_HUB_BUILD_CONTENT = """\
{toolchains}
"""

_CONSTRAINTS = {
    "darwin_aarch64": [
        "@platforms//os:macos",
        "@platforms//cpu:aarch64",
    ],
    "darwin_x86_64": [
        "@platforms//os:macos",
        "@platforms//cpu:x86_64",
    ],
    "linux_aarch64": [
        "@platforms//os:linux",
        "@platforms//cpu:aarch64",
    ],
    "linux_armv6hf": [
        "@platforms//cpu:armv6-m",
        "@platforms//os:linux",
    ],
    "linux_x86_64": [
        "@platforms//os:linux",
        "@platforms//cpu:x86_64",
    ],
    "windows_x86_64": [
        "@platforms//os:windows",
        "@platforms//cpu:x86_64",
    ],
}

_TOOLCHAIN_ENTRY = """\
toolchain(
    name = "shellcheck_toolchain_{arch}",
    toolchain_type = "@rules_shellcheck//shellcheck:toolchain_type",
    toolchain = "{toolchain}",
    exec_compatible_with = {constraints},
    visibility = ["//visibility:public"],
)
"""

def _shellcheck_toolchains_hub_impl(repository_ctx):
    toolchains = []
    for toolchain, arch in repository_ctx.attr.toolchains.items():
        toolchains.append(_TOOLCHAIN_ENTRY.format(
            arch = arch,
            constraints = repr(_CONSTRAINTS[arch]),
            toolchain = str(toolchain),
        ))

    repository_ctx.file("BUILD.bazel", _HUB_BUILD_CONTENT.format(
        toolchains = "\n".join(toolchains),
    ))

    repository_ctx.file("WORKSPACE.bazel", """workspace(name = "{}")""".format(
        repository_ctx.name,
    ))

shellcheck_toolchains_hub = repository_rule(
    doc = "A repository rule for defining shellcheck toolchains",
    implementation = _shellcheck_toolchains_hub_impl,
    attrs = {
        "toolchains": attr.label_keyed_string_dict(
            doc = "A mapping of toolchain labels to platforms.",
            mandatory = True,
        ),
    },
)

def _urls(arch, version):
    archive_template_name = {
        "darwin_aarch64": "shellcheck-{version}.{arch}.tar.xz",
        "darwin_x86_64": "shellcheck-{version}.{arch}.tar.xz",
        "linux_aarch64": "shellcheck-{version}.{arch}.tar.xz",
        "linux_armv6hf": "shellcheck-{version}.{arch}.tar.xz",
        "linux_x86_64": "shellcheck-{version}.{arch}.tar.xz",
        "windows_x86_64": "shellcheck-{version}.zip",
    }
    url = "https://github.com/koalaman/shellcheck/releases/download/{version}/{archive}".format(
        version = version,
        archive = archive_template_name[arch].format(
            version = version,
            arch = arch.replace("_", ".", 1),
        ),
    )

    return [
        url,
    ]

_SHELLCHECK_UNIX_BUILD_CONTENT = """\
load("@rules_shellcheck//shellcheck:shellcheck_toolchain.bzl", "shellcheck_toolchain")

package(default_visibility = ["//visibility:public"])

exports_files(["shellcheck"])

alias(
    name = "{name}",
    actual = "shellcheck",
)

shellcheck_toolchain(
    name = "toolchain",
    shellcheck = "shellcheck",
)
"""

_SHELLCHECK_WINDOWS_BUILD_CONTENT = """\
load("@rules_shellcheck//shellcheck:shellcheck_toolchain.bzl", "shellcheck_toolchain")

package(default_visibility = ["//visibility:public"])

exports_files(["shellcheck.exe"])

alias(
    name = "shellcheck",
    actual = "shellcheck.exe",
)

alias(
    name = "{name}",
    actual = "shellcheck.exe",
)

shellcheck_toolchain(
    name = "toolchain",
    shellcheck = ":shellcheck",
)
"""

def shellcheck_dependencies():
    """Define shellcheck repositories"""
    version = "v0.11.0"
    sha256 = {
        "darwin_aarch64": "56affdd8de5527894dca6dc3d7e0a99a873b0f004d7aabc30ae407d3f48b0a79",
        "darwin_x86_64": "3c89db4edcab7cf1c27bff178882e0f6f27f7afdf54e859fa041fca10febe4c6",
        "linux_aarch64": "12b331c1d2db6b9eb13cfca64306b1b157a86eb69db83023e261eaa7e7c14588",
        "linux_armv6hf": "8afc50b302d5feeac9381ea114d563f0150d061520042b254d6eb715797c8223",
        "linux_x86_64": "8c3be12b05d5c177a04c29e3c78ce89ac86f1595681cab149b65b97c4e227198",
        "windows_x86_64": "8a4e35ab0b331c85d73567b12f2a444df187f483e5079ceffa6bda1faa2e740e",
    }

    toolchains = {}

    for arch, sha256 in sha256.items():
        name = "shellcheck_{arch}".format(arch = arch)

        strip_prefix = "shellcheck-{version}".format(version = version)
        build_file_content = _SHELLCHECK_UNIX_BUILD_CONTENT.format(
            name = name,
        )

        # Special case, as it is a zip archive with no prefix to strip.
        if "windows" in arch:
            strip_prefix = None
            build_file_content = _SHELLCHECK_WINDOWS_BUILD_CONTENT.format(
                name = name,
            )

        maybe(
            http_archive,
            name = name,
            strip_prefix = strip_prefix,
            build_file_content = build_file_content,
            sha256 = sha256,
            urls = _urls(arch = arch, version = version),
        )

        toolchains["@{}//:toolchain".format(name)] = arch

    maybe(
        shellcheck_toolchains_hub,
        name = "shellcheck_toolchains",
        toolchains = toolchains,
    )

def _impl(_):
    shellcheck_dependencies()

shellcheck = module_extension(
    implementation = _impl,
)
