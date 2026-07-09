# Shellcheck rules for bazel

Now you do not need to depend on the system `shellcheck` version in your bazel-managed (mono)repos.

[![Build Status](https://github.com/aignas/rules_shellcheck/workflows/CI/badge.svg)](https://github.com/aignas/rules_shellcheck/actions)

Choose your release from the [GH Releases](https://github.com/aignas/rules_shellcheck/releases) and follow setup instructions there.

Then `shellcheck` can be accessed by running:

```shell
bazel run @rules_shellcheck//:shellcheck -- <parameters>
```

And you can define a lint target:

```starlark
load("@rules_shellcheck//:def.bzl", "shellcheck", "shellcheck_test")

shellcheck_test(
    name = "shellcheck_test",
    data = glob(["*.sh"]),
    tags = ["lint"],
    format = "gcc",
    severity = "warning",
)
```

## Configuring the shellcheck aspect

`shellcheck_aspect` runs `shellcheck` against any target that provides `ShInfo` or `ShBinaryInfo` (e.g. `sh_binary` and `sh_library` from [rules_shell]) as part of a normal `bazel build`. Enable it by adding the following to your `.bazelrc`:

```
build --aspects=@rules_shellcheck//shellcheck:shellcheck_aspect.bzl%shellcheck_aspect
build --output_groups=+shellcheck_checks
```

With those flags in place, any build that includes shell targets will also run `shellcheck` on their sources; the lint results are exposed via the `shellcheck_checks` output group.

### Output format and severity

The aspect reads two `string_flag` build settings. Override them on the command line or via `.bazelrc`:

```
build --@rules_shellcheck//shellcheck/settings:format=gcc
build --@rules_shellcheck//shellcheck/settings:severity=warning
```

- `//shellcheck/settings:format` accepts `checkstyle`, `diff`, `gcc`, `json`, `json1`, `quiet`, or `tty` (default: `shellcheck`'s built-in default).
- `//shellcheck/settings:severity` accepts `error`, `warning`, `info`, or `style` (default: `shellcheck`'s built-in default).

Because these are standard `string_flag`s, you can also flip them per-command with `--config` groups or with [`transitions`][transitions] if you want a specific target to lint under different settings.

### Skipping targets

Add any of the following tags to a target to opt it out of `shellcheck_aspect`:

- `no_shellcheck`
- `noshellcheck`
- `no_lint`
- `nolint`

Targets under external repositories (`workspace_root` starting with `external`) are always skipped.

Note: this is a simple project that allows me to learn about various bazel concepts. Feel free to create PRs contributing to the project or consider using [rules_lint].

[rules_lint]: https://github.com/aspect-build/rules_lint
[rules_shell]: https://github.com/bazelbuild/rules_shell
[transitions]: https://bazel.build/extending/config#user-defined-transitions
