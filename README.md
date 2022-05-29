# Shellcheck rules for bazel

Now you do not need to depend on the system shellcheck version in your bazel-managed (mono)repos.

[![Build Status](https://github.com/aignas/rules_shellcheck/workflows/CI/badge.svg)](https://github.com/aignas/rules_shellcheck/actions)

Adding it to your `WORKSPACE`:
```
load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

git_repository(
    name = "com_github_aignas_rules_shellcheck",
    commit = "94b231c8475f067c60f77459b2b54f4bcacc5e73",
    remote = "https://github.com/aignas/rules_shellcheck.git",
)

load("@com_github_aignas_rules_shellcheck//:deps.bzl", "shellcheck_dependencies")

shellcheck_dependencies()
```

Then `shellcheck` can be accessed by running:
```
$ bazel run @com_github_aignas_rules_shellcheck//:shellcheck -- <parameters>
```

And you can define a lint target:
```
load("@com_github_aignas_rules_shellcheck//:def.bzl", "shellcheck", "shellcheck_test")

shellcheck_test(
    name = "shellcheck_test",
    data = glob(["*.sh"]),
    tags = ["lint"],
)
```
