"""shellcheck toolchain"""

TOOLCHAIN_TYPE = str(Label("//shellcheck:toolchain_type"))

def _rlocationpath(file, workspace_name):
    if file.short_path.startswith("../"):
        return file.short_path[len("../"):]

    return "{}/{}".format(workspace_name, file.short_path)

def _shellcheck_toolchain_impl(ctx):
    all_files = []
    if DefaultInfo in ctx.attr.shellcheck:
        all_files.extend([
            ctx.attr.shellcheck[DefaultInfo].files,
            ctx.attr.shellcheck[DefaultInfo].default_runfiles.files,
        ])

    make_variable_info = platform_common.TemplateVariableInfo({
        "SHELLCHECK": ctx.file.shellcheck.path,
        "SHELLCHECK_RLOCATIONPATH": _rlocationpath(ctx.file.shellcheck, ctx.workspace_name),
    })

    return [
        platform_common.ToolchainInfo(
            label = ctx.label,
            shellcheck = ctx.file.shellcheck,
            shellcheckrc = ctx.file._shellcheckrc,
            make_variable_info = make_variable_info,
            all_files = depset(transitive = all_files),
        ),
        make_variable_info,
    ]

shellcheck_toolchain = rule(
    doc = "A toolchain for shellcheck rules",
    implementation = _shellcheck_toolchain_impl,
    attrs = {
        "shellcheck": attr.label(
            mandatory = True,
            allow_single_file = True,
            cfg = "exec",
            executable = True,
            doc = "The shellcheck executable to use.",
        ),
        "_shellcheckrc": attr.label(
            allow_single_file = True,
            default = Label("//shellcheck:rc"),
        ),
    },
)

def _current_shellcheck_toolchain_impl(ctx):
    toolchain = ctx.toolchains[TOOLCHAIN_TYPE]

    shellcheck = toolchain.shellcheck

    executable = ctx.actions.declare_file("{}/{}".format(
        ctx.label.name,
        shellcheck.basename,
    ))

    ctx.actions.symlink(
        target_file = shellcheck,
        output = executable,
        is_executable = True,
    )

    return [
        toolchain.make_variable_info,
        toolchain,
        DefaultInfo(
            executable = executable,
            runfiles = ctx.runfiles(transitive_files = toolchain.all_files),
        ),
    ]

current_shellcheck_toolchain = rule(
    doc = "Access the registered `shellcheck_toolchain` from the current configuration.",
    implementation = _current_shellcheck_toolchain_impl,
    toolchains = [TOOLCHAIN_TYPE],
    executable = True,
)
