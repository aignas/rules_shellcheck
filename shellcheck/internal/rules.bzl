"""This file provides all user facing functions.
"""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load("@rules_shell//shell:sh_binary_info.bzl", "ShBinaryInfo")
load("@rules_shell//shell:sh_info.bzl", "ShInfo")
load(":toolchain.bzl", "TOOLCHAIN_TYPE", "rlocationpath")

def shellcheck_test_impl(ctx, expect_fail = False):
    """The implementation of the `shellcheck_test` rule.

    Args:
        ctx (ctx): The rule's context object.
        expect_fail (bool, optional): Whether or not shellcheck is expected to fail.

    Returns:
        list: All providers.
    """
    toolchain = ctx.toolchains[TOOLCHAIN_TYPE]
    runner = ctx.file._runner
    executable = ctx.actions.declare_file("{}.{}".format(ctx.label.name, runner.extension))
    ctx.actions.symlink(
        output = executable,
        target_file = runner,
        is_executable = True,
    )

    opts = []
    if ctx.attr.format:
        opts.append("--format={}".format(ctx.attr.format))
    if ctx.attr.severity:
        opts.append("--severity={}".format(ctx.attr.severity))

    check_generated = ctx.attr.check_generated == 1 or (
        ctx.attr.check_generated == -1 and ctx.attr._check_generated[BuildSettingInfo].value
    )
    target_srcs = [
        src
        for src in depset(transitive = [
            srcs
            for target in ctx.attr.targets
            for srcs in (target[ShellcheckSrcsInfo].srcs, target[ShellcheckSrcsInfo].transitive_srcs)
        ]).to_list()
        if src.is_source or check_generated
    ]
    files = ctx.files.data + target_srcs

    # The runner derives `--source-path` from one file per directory, since
    # directories themselves are not listed in the runfiles manifest.
    source_files = {src.short_path.rpartition("/")[0]: src for src in target_srcs}.values()

    workspace_name = ctx.workspace_name
    env = {
        "SHELLCHECK_TEST_BIN": rlocationpath(toolchain.shellcheck, workspace_name),
        "SHELLCHECK_TEST_EXPECT_FAIL": "1" if expect_fail else "0",
        "SHELLCHECK_TEST_FILES": " ".join([rlocationpath(f, workspace_name) for f in files]),
        "SHELLCHECK_TEST_OPTS": " ".join(opts),
        "SHELLCHECK_TEST_RCFILE": rlocationpath(toolchain.shellcheckrc, workspace_name),
        "SHELLCHECK_TEST_SOURCE_FILES": " ".join([rlocationpath(f, workspace_name) for f in source_files]),
    }

    runfiles = ctx.runfiles(
        files = [toolchain.shellcheck, toolchain.shellcheckrc] + files,
        transitive_files = toolchain.all_files,
    )

    return [
        DefaultInfo(
            executable = executable,
            runfiles = runfiles.merge(ctx.attr._runfiles_lib[DefaultInfo].default_runfiles),
        ),
        RunEnvironmentInfo(environment = env),
    ]

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

ATTRS = {
    "check_generated": attr.int(
        doc = (
            "Whether to lint generated files collected from `targets`: `0` never, " +
            "`1` always, `-1` defer to `//shellcheck/settings:check_generated`."
        ),
        default = -1,
        values = [-1, 0, 1],
    ),
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
    "targets": attr.label_list(
        doc = "`rules_shell` targets whose sources, and those of their transitive `deps`, are linted.",
        providers = [[ShInfo], [ShBinaryInfo]],
        aspects = [_shellcheck_srcs_aspect],
    ),
    "_check_generated": attr.label(
        default = Label("//shellcheck/settings:check_generated"),
    ),
    "_runfiles_lib": attr.label(
        doc = "The runfiles library sourced by `_runner`.",
        default = Label("//shellcheck/internal:runfiles_lib"),
    ),
    "_runner": attr.label(
        default = Label("//shellcheck/internal:test_runner"),
        allow_single_file = True,
    ),
}

shellcheck_test = rule(
    implementation = shellcheck_test_impl,
    attrs = ATTRS,
    test = True,
    toolchains = [TOOLCHAIN_TYPE],
)

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

    check_generated = ctx.attr._check_generated[BuildSettingInfo].value
    srcs = [
        src
        for src in src_info.srcs.to_list()
        if src.is_source or check_generated
    ]

    if not srcs:
        return []

    toolchain = ctx.toolchains[TOOLCHAIN_TYPE]

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

    args = ctx.actions.args()
    args.add(output)
    args.add("--")
    args.add(toolchain.shellcheck)
    args.add(toolchain.shellcheckrc, format = "--rcfile=%s")
    args.add_all(src_info.source_paths, format_each = "--source-path=%s")

    if format:
        args.add(format, format = "--format=%s")

    if severity:
        args.add(severity, format = "--severity=%s")

    args.add_all(srcs)

    ctx.actions.run(
        mnemonic = "Shellcheck",
        progress_message = "Shellcheck {}".format(target.label),
        executable = ctx.file._runner,
        inputs = depset(inputs_direct, transitive = inputs_transitive),
        arguments = [args],
        env = ctx.configuration.default_shell_env,
        tools = tools,
        outputs = [output],
        execution_requirements = {"supports-path-mapping": ""},
        toolchain = TOOLCHAIN_TYPE,
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
        "_check_generated": attr.label(
            default = Label("//shellcheck/settings:check_generated"),
        ),
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
    },
    toolchains = [TOOLCHAIN_TYPE],
    requires = [_shellcheck_srcs_aspect],
    required_providers = [[ShInfo], [ShBinaryInfo]],
)
