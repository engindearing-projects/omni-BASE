workspace(name = "valdi")

load("//bzl:workspace_prepare.bzl", "valdi_prepare_workspace")

valdi_prepare_workspace(__workspace_dir__)

load("//bzl:workspace_preinit.bzl", "valdi_preinitialize_workspace")

valdi_preinitialize_workspace()

load("@aspect_bazel_lib//lib:repositories.bzl", "aspect_bazel_lib_dependencies", "aspect_bazel_lib_register_toolchains", "register_yq_toolchains")

register_yq_toolchains()

# Required bazel-lib dependencies

aspect_bazel_lib_dependencies()

# Required rules_shell dependencies
load("@rules_shell//shell:repositories.bzl", "rules_shell_dependencies", "rules_shell_toolchains")

rules_shell_dependencies()

rules_shell_toolchains()

# Register bazel-lib toolchains

aspect_bazel_lib_register_toolchains()

# Create the host platform repository transitively required by bazel-lib

load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("@platforms//host:extension.bzl", "host_platform_repo")

maybe(
    host_platform_repo,
    name = "host_platform",
)

load("//bzl:workspace_init.bzl", "platform_dependency_rule", "valdi_initialize_workspace")

# repo rule generates target_platform.bzl
platform_dependency_rule(name = "platform_check")

load("@platform_check//:target_platform.bzl", "VALDI_PLATFORM_DEPENDENCIES")

valdi_initialize_workspace(VALDI_PLATFORM_DEPENDENCIES)

load("@valdi_npm//:repositories.bzl", "npm_repositories")

npm_repositories()

load("//bzl:workspace_postinit.bzl", "valdi_post_initialize_workspace")

valdi_post_initialize_workspace()

# OmniTAK Mobile Dependencies
load("//bzl:omnitak_dependencies.bzl", "setup_omnitak_dependencies")

setup_omnitak_dependencies(VALDI_PLATFORM_DEPENDENCIES)
