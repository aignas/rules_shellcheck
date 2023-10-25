# Shellcheck rules for bazel

Now you do not need to depend on the system shellcheck version in your bazel-managed (mono)repos.

[![Build Status](https://github.com/aignas/rules_shellcheck/workflows/CI/badge.svg)](https://github.com/aignas/rules_shellcheck/actions)

Adding it to your `WORKSPACE`:

```starlark
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "rules_shellcheck",
    sha256 = "4e7cc56d344d0adfd20283f7ad8cb4fba822c0b15ce122665b00dd87a27a74b6",
    strip_prefix = "rules_shellcheck-0.1.1",
    url = "https://github.com/aignas/rules_shellcheck/archive/refs/tags/v0.1.1.tar.gz",
)

load("@rules_shellcheck//:deps.bzl", "shellcheck_dependencies")

shellcheck_dependencies()
```

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
