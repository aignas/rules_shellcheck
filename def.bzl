def _impl(ctx):
    ctx.actions.symlink(
        output = ctx.outputs.executable,
        target_file = ctx.file._shellcheck,
    )
    return [
        DefaultInfo(
            executable = ctx.outputs.executable,
            runfiles = ctx.runfiles(files = [ctx.file._shellcheck]),
        ),
    ]

def _impl_test(ctx):
    files = [ctx.file._shellcheck] + ctx.files.data
    script = "exec " + " ".join([f.short_path for f in files])

    ctx.actions.write(
        output = ctx.outputs.executable,
        content = script,
    )

    return [
        DefaultInfo(
            executable = ctx.outputs.executable,
            runfiles = ctx.runfiles(files = files),
        ),
    ]

shellcheck = rule(
    implementation = _impl,
    attrs = {
        "_shellcheck": attr.label(
            default = Label("@shellcheck"),
            allow_single_file = True,
            cfg = "host",
            executable = True,
        ),
    },
    executable = True,
)

shellcheck_test = rule(
    implementation = _impl_test,
    attrs = {
        "data": attr.label_list(
            allow_files = True,
        ),
        "_shellcheck": attr.label(
            default = Label("@shellcheck"),
            allow_single_file = True,
            cfg = "host",
            executable = True,
        ),
    },
    test = True,
)
