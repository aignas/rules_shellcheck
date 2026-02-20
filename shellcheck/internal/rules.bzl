"""This file provides all user facing functions.
"""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")

def shellcheck_test_impl(ctx, expect_fail = False):
    """The implementation of the `shellcheck_test` rule.

    Args:
        ctx (ctx): The rule's context object.
        expect_fail (bool, optional): Whether or not shellcheck is expected to fail.

    Returns:
        list: All providers.
    """
    cmd = [ctx.file._shellcheck.short_path]
    if ctx.attr.format:
        cmd.append("--format={}".format(ctx.attr.format))
    if ctx.attr.severity:
        cmd.append("--severity={}".format(ctx.attr.severity))
    cmd += [f.short_path for f in ctx.files.data]
    cmd = " ".join(cmd)

    if expect_fail:
        script = "{cmd} || exit 0\nexit1".format(cmd = cmd)
    else:
        script = "exec {cmd}".format(cmd = cmd)

    ctx.actions.write(
        output = ctx.outputs.executable,
        content = script,
        is_executable = True,
    )

    return [
        DefaultInfo(
            executable = ctx.outputs.executable,
            runfiles = ctx.runfiles(files = [ctx.file._shellcheck] + ctx.files.data),
        ),
    ]

ATTRS = {
    "data": attr.label_list(
        allow_files = True,
    ),
    "expect_fail": attr.bool(
        default = False,
    ),
    "format": attr.string(
        values = ["checkstyle", "diff", "gcc", "json", "json1", "quiet", "tty"],
        doc = "The format of the outputted lint results.",
    ),
    "severity": attr.string(
        values = ["error", "info", "style", "warning"],
        doc = "The severity of the lint results.",
    ),
    "_shellcheck": attr.label(
        default = Label("//:shellcheck"),
        allow_single_file = True,
        cfg = "exec",
        executable = True,
        doc = "The shellcheck executable to use.",
    ),
}

shellcheck_test = rule(
    implementation = shellcheck_test_impl,
    attrs = ATTRS,
    test = True,
)

_SHELL_CONTENT = """\
#!/bin/sh

echo '' > '{output}'
exec '{shellcheck}' $@
"""

_BATCH_CONTENT = """\
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

    inputs_direct = getattr(ctx.rule.files, "srcs", []) + getattr(ctx.rule.files, "data", [])
    inputs_transitive = []

    if DefaultInfo in target:
        inputs_transitive.extend([
            target[DefaultInfo].files,
            target[DefaultInfo].default_runfiles.files,
        ])

    format = ctx.attr._format[BuildSettingInfo].value
    severity = ctx.attr._format[BuildSettingInfo].value

    shellcheck = ctx.executable._shellcheck
    is_windows = True if shellcheck.basename.endswith(".exe") else False

    executable = ctx.actions.declare_file("{}.shellcheck.{}".format(target.label.name, "bat" if is_windows else "sh"))
    output = ctx.actions.declare_file("{}.shellcheck.ok".format(target.label.name))

    ctx.actions.write(
        output = executable,
        content = (_BATCH_CONTENT if is_windows else _SHELL_CONTENT).format(
            output = output.path,
            shellcheck = ctx.executable._shellcheck.path,
        ),
        is_executable = True,
    )

    tools = depset([ctx.executable._shellcheck])
    if DefaultInfo in ctx.attr._shellcheck:
        tools = depset(transitive = [
            tools,
            ctx.attr._shellcheck[DefaultInfo].files,
            ctx.attr._shellcheck[DefaultInfo].default_runfiles.files,
        ])

    args = ctx.actions.args()
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
        "_shellcheck": attr.label(
            default = Label("//:shellcheck"),
            allow_single_file = True,
            cfg = "exec",
            executable = True,
            doc = "The shellcheck executable to use.",
        ),
    },
)
