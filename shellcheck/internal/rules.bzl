"""This file provides all user facing functions.
"""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load("@rules_shell//shell:sh_binary_info.bzl", "ShBinaryInfo")
load("@rules_shell//shell:sh_info.bzl", "ShInfo")
load(":toolchain.bzl", "TOOLCHAIN_TYPE")

_SHELL_CONTENT = """\
#!/bin/sh

set -eu

"{shellcheck}" {args}{post}
"""

_BATCH_CONTENT = """\
@ECHO OFF

"{shellcheck}" {args}{post}
"""

def _quote_for_shell(value):
    return "\"{}\"".format(value.replace("\"", "\\\""))

def _quote_for_batch(value):
    return "\"{}\"".format(value.replace("\"", "\"\""))

def shellcheck_test_impl(ctx, expect_fail = False):
    """The implementation of the `shellcheck_test` rule.

    Args:
        ctx (ctx): The rule's context object.
        expect_fail (bool, optional): Whether or not shellcheck is expected to fail.

    Returns:
        list: All providers.
    """
    is_windows = ctx.target_platform_has_constraint(
        ctx.attr._windows_constraint[platform_common.ConstraintValueInfo],
    )

    toolchain = ctx.toolchains[TOOLCHAIN_TYPE]
    executable = ctx.actions.declare_file("{}{}".format(
        ctx.label.name,
        ".bat" if is_windows else ".sh",
    ))

    cmd = []
    if ctx.attr.format:
        cmd.append("--format={}".format(ctx.attr.format))
    if ctx.attr.severity:
        cmd.append("--severity={}".format(ctx.attr.severity))

    shellcheck_path = toolchain.shellcheck.short_path
    shellcheck_rc = toolchain.shellcheckrc.short_path
    srcs = [f.short_path for f in ctx.files.data]
    if is_windows:
        shellcheck_path = shellcheck_path.replace("/", "\\")
        shellcheck_rc = shellcheck_rc.replace("/", "\\")
        srcs = [src.replace("/", "\\") for src in srcs]

    if is_windows:
        cmd.append("--rcfile={}".format(_quote_for_batch(shellcheck_rc)))
        cmd.extend([_quote_for_batch(src) for src in srcs])
    else:
        cmd.append("--rcfile={}".format(_quote_for_shell(shellcheck_rc)))
        cmd.extend([_quote_for_shell(src) for src in srcs])

    post = ""
    if expect_fail:
        post = " && exit /b 1 || exit /b 0" if is_windows else " || exit 0\nexit 1"

    ctx.actions.write(
        output = executable,
        content = (_BATCH_CONTENT if is_windows else _SHELL_CONTENT).format(
            shellcheck = shellcheck_path,
            args = " ".join(cmd),
            post = post,
        ),
        is_executable = True,
    )

    return [
        DefaultInfo(
            executable = executable,
            runfiles = ctx.runfiles(
                files = [toolchain.shellcheck, toolchain.shellcheckrc] + ctx.files.data,
                transitive_files = toolchain.all_files,
            ),
        ),
    ]

ATTRS = {
    "data": attr.label_list(
        allow_files = True,
    ),
    "format": attr.string(
        values = ["checkstyle", "diff", "gcc", "json", "json1", "quiet", "tty"],
        doc = "The format of the outputted lint results.",
    ),
    "severity": attr.string(
        values = ["error", "info", "style", "warning"],
        doc = "The severity of the lint results.",
    ),
    "_windows_constraint": attr.label(
        default = Label("@platforms//os:windows"),
    ),
}

shellcheck_test = rule(
    implementation = shellcheck_test_impl,
    attrs = ATTRS,
    test = True,
    toolchains = [TOOLCHAIN_TYPE],
)

ShellcheckSrcsInfo = provider(
    doc = "A provider containing relevant data for linting.",
    fields = {
        "source_paths": "depset[str]: `--source-path` target paths.",
        "srcs": "depset[File]: Sources collected from the target.",
        "transitive_source_paths": "depset[str]: Transitive source paths collected from dependencies.",
        "transitive_srcs": "depset[File]: Transitive sources collected from dependencies.",
    },
)

def _shellcheck_srcs_aspect_impl(_target, ctx):
    srcs = getattr(ctx.rule.files, "srcs", [])
    source_paths = [src.dirname for src in srcs]

    transitive_srcs = []
    transitive_source_paths = []

    for dep in getattr(ctx.rule.attr, "deps", []):
        if ShellcheckSrcsInfo in dep:
            transitive_srcs.extend([
                dep[ShellcheckSrcsInfo].srcs,
                dep[ShellcheckSrcsInfo].transitive_srcs,
            ])
            transitive_source_paths.extend([
                dep[ShellcheckSrcsInfo].source_paths,
                dep[ShellcheckSrcsInfo].transitive_source_paths,
            ])

    return [ShellcheckSrcsInfo(
        srcs = depset(srcs),
        source_paths = depset(source_paths),
        transitive_srcs = depset(transitive = transitive_srcs),
        transitive_source_paths = depset(transitive = transitive_source_paths),
    )]

_shellcheck_srcs_aspect = aspect(
    doc = "An aspect for collecting data about how to lint the target.",
    attr_aspects = ["deps"],
    implementation = _shellcheck_srcs_aspect_impl,
)

def _unix_path_arg(value):
    return value.path

def _windows_path_arg(value):
    return value.path.replace("/", "\\")

def _shellcheck_aspect_impl(target, ctx):
    if target.label.workspace_root.startswith("external"):
        return []

    ignore_tags = [
        "no_shellcheck",
        "no_lint",
        "nolint",
        "noshellcheck",
    ]
    for tag in ctx.rule.attr.tags:
        if tag.replace("-", "_").lower() in ignore_tags:
            return []

    if ShellcheckSrcsInfo not in target:
        return []

    src_info = target[ShellcheckSrcsInfo]

    srcs = [
        src
        for src in src_info.srcs.to_list()
        if src.is_source
    ]

    if not srcs:
        return []

    toolchain = ctx.toolchains[TOOLCHAIN_TYPE]
    is_windows = ctx.target_platform_has_constraint(
        ctx.attr._windows_constraint[platform_common.ConstraintValueInfo],
    )

    inputs_direct = [toolchain.shellcheckrc] + getattr(ctx.rule.files, "data", [])
    inputs_transitive = [src_info.srcs, src_info.transitive_srcs]

    if DefaultInfo in target:
        inputs_transitive.extend([
            target[DefaultInfo].files,
            target[DefaultInfo].default_runfiles.files,
        ])

    format = ctx.attr._format[BuildSettingInfo].value
    severity = ctx.attr._severity[BuildSettingInfo].value

    output = ctx.actions.declare_file("{}.shellcheck.ok".format(target.label.name))

    tools = depset([toolchain.shellcheck], transitive = [toolchain.all_files])

    shellcheck_path = toolchain.shellcheck.path
    shellcheck_rc_path = toolchain.shellcheckrc.path
    if is_windows:
        shellcheck_path = shellcheck_path.replace("/", "\\")
        shellcheck_rc_path = shellcheck_rc_path.replace("/", "\\")

    args = ctx.actions.args()
    args.add(shellcheck_path)
    args.add(shellcheck_rc_path, format = "--rcfile=%s")
    args.add_all(src_info.source_paths, format_each = "--source-path=%s")

    if format:
        args.add(format, format = "--format=%s")

    if severity:
        args.add(severity, format = "--severity=%s")

    args.add_all(srcs, map_each = _windows_path_arg if is_windows else _unix_path_arg)

    ctx.actions.run(
        mnemonic = "Shellcheck",
        progress_message = "Shellcheck {}".format(target.label),
        executable = ctx.file._runner,
        inputs = depset(inputs_direct, transitive = inputs_transitive),
        arguments = [args],
        env = ctx.configuration.default_shell_env | {
            "SHELLCHECK_ASPECT_OUTPUT": output.path,
        },
        tools = tools,
        outputs = [output],
    )

    return [
        OutputGroupInfo(
            shellcheck_checks = depset([output]),
        ),
    ]

shellcheck_aspect = aspect(
    doc = "An aspect for performing shellcheck checks on `rules_shell` rules.",
    implementation = _shellcheck_aspect_impl,
    attrs = {
        "_format": attr.label(
            default = Label("//shellcheck/settings:format"),
        ),
        "_runner": attr.label(
            allow_single_file = True,
            default = Label("//shellcheck/internal:aspect_runner"),
        ),
        "_severity": attr.label(
            default = Label("//shellcheck/settings:severity"),
        ),
        "_windows_constraint": attr.label(
            default = Label("@platforms//os:windows"),
        ),
    },
    toolchains = [TOOLCHAIN_TYPE],
    requires = [_shellcheck_srcs_aspect],
    required_providers = [[ShInfo], [ShBinaryInfo]],
)
