"""This file provides all user facing functions.
"""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load(":toolchain.bzl", "TOOLCHAIN_TYPE")

_SHELL_CONTENT = """\
#!/bin/sh

set -eu

{shellcheck} {args}
"""

_BATCH_CONTENT = """\
@ECHO OFF

{shellcheck} {args}
"""

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
        shellcheck_path.replace("/", "\\")
        shellcheck_rc.replace("/", "\\")
        srcs = [src.replace("/", "\\") for src in srcs]

    cmd.append("--rcfile={}".format(shellcheck_rc))
    cmd.extend(srcs)

    if expect_fail:
        cmd.append("|| exit 0; exit 1")

    ctx.actions.write(
        output = executable,
        content = (_BATCH_CONTENT if is_windows else _SHELL_CONTENT).format(
            shellcheck = shellcheck_path,
            args = " ".join(cmd),
        ),
        is_executable = True,
    )

    return [
        DefaultInfo(
            executable = executable,
            runfiles = ctx.runfiles(
                files = [toolchain.shellcheck] + ctx.files.data,
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

_ASPECT_SHELL_CONTENT = """\
#!/bin/sh

echo '' > '{output}'
exec '{shellcheck}' $@
"""

_ASPECT_BATCH_CONTENT = """\
@ECHO OFF

echo "" > {output}
{shellcheck} %*
"""

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

    # TODO: https://github.com/aignas/rules_shellcheck/issues/23
    rule_name = ctx.rule.kind
    if rule_name not in ["sh_binary", "sh_test", "sh_library"]:
        return []

    srcs = [
        src
        for src in getattr(ctx.rule.files, "srcs", [])
        if src.is_source
    ]

    if not srcs:
        return []

    toolchain = ctx.toolchains[TOOLCHAIN_TYPE]

    inputs_direct = getattr(ctx.rule.files, "srcs", []) + getattr(ctx.rule.files, "data", [])
    inputs_transitive = []

    if DefaultInfo in target:
        inputs_transitive.extend([
            target[DefaultInfo].files,
            target[DefaultInfo].default_runfiles.files,
        ])

    format = ctx.attr._format[BuildSettingInfo].value
    severity = ctx.attr._format[BuildSettingInfo].value

    shellcheck = toolchain.shellcheck
    is_windows = True if shellcheck.basename.endswith(".exe") else False

    executable = ctx.actions.declare_file("{}.shellcheck.{}".format(target.label.name, "bat" if is_windows else "sh"))
    output = ctx.actions.declare_file("{}.shellcheck.ok".format(target.label.name))

    ctx.actions.write(
        output = executable,
        content = (_ASPECT_BATCH_CONTENT if is_windows else _ASPECT_SHELL_CONTENT).format(
            output = output.path,
            shellcheck = shellcheck.path,
        ),
        is_executable = True,
    )

    tools = depset([shellcheck], transitive = [toolchain.all_files])

    args = ctx.actions.args()
    args.add(toolchain.shellcheckrc, format = "--rcfile=%s")

    if format:
        args.add(format, format = "--format=%s")

    if severity:
        args.add(severity, format = "--severity=%s")

    args.add_all(srcs)

    ctx.actions.run(
        mnemonic = "Shellcheck",
        progress_message = "Shellcheck {}".format(target.label),
        executable = executable,
        inputs = depset(inputs_direct, transitive = inputs_transitive),
        arguments = [args],
        env = ctx.configuration.default_shell_env,
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
        "_severity": attr.label(
            default = Label("//shellcheck/settings:severity"),
        ),
    },
    toolchains = [TOOLCHAIN_TYPE],
)
