"""This file provides all user facing functions.
"""

def _impl_test(ctx):
    files = [ctx.file._shellcheck] + ctx.files.data
    cmd = " ".join([f.short_path for f in files])
    if ctx.attr.expect_fail:
        script = "{cmd} || exit 0\nexit1".format(cmd = cmd)
    else:
        script = "exec {cmd}".format(cmd = cmd)

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

shellcheck_test = rule(
    implementation = _impl_test,
    attrs = {
        "data": attr.label_list(
            allow_files = True,
        ),
        "expect_fail": attr.bool(
            default = False,
        ),
        "_shellcheck": attr.label(
            default = Label("//:shellcheck"),
            allow_single_file = True,
            cfg = "host",
            executable = True,
        ),
    },
    test = True,
)
