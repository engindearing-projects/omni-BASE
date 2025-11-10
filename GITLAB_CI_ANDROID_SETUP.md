# GitLab CI/CD for Android Auto-Build

**Date**: 2025-11-10
**Status**: Configured
**Branch**: `claude/gitlab-ci-android-build-011CUyfbXemDaq1fJ7YrmZ37`

## Overview

This document describes the GitLab CI/CD pipeline configuration for automatically building the OmniTAK Android application. The pipeline is based on [GitLab's Mobile DevOps best practices](https://docs.gitlab.com/ci/mobile_devops/mobile_devops_tutorial_android/) and adapted for this Bazel-based project.

## Pipeline Architecture

### Stages

The CI/CD pipeline consists of 6 stages:

```
1. setup          → Install Bazel, Rust, Android SDK/NDK
2. validate       → Verify project structure and dependencies
3. build_native   → Build Rust libraries for Android ABIs
4. build_app      → Build Android APK with Bazel
5. test           → Run verification and tests
6. package        → Package artifacts for distribution
```

### Jobs

| Job | Stage | Description | Artifacts |
|-----|-------|-------------|-----------|
| `setup_environment` | setup | Installs Bazel, Rust toolchain, Android targets | Bazel installer |
| `validate_project` | validate | Checks project structure and required files | None |
| `build_rust_libraries` | build_native | Builds Rust native libraries for all Android ABIs | Native libraries (.a files) |
| `build_android_apk` | build_app | Builds debug APK with Bazel | Debug APK |
| `build_android_release` | build_app | Builds optimized release APK (main/tags only) | Release APK |
| `verify_build` | test | Runs verification script and APK analysis | None |
| `package_artifacts` | package | Creates distribution package with build info | Distribution package |

## Configuration

### Docker Image

The pipeline uses `mingc/android-build-box:latest` which includes:
- Android SDK and NDK
- Build tools
- Java/Kotlin
- Common build utilities

**Alternative images you can use:**
- `fabernovel/android:api-34-v1.7.0` - Official GitLab recommended
- `jangrewe/gitlab-ci-android` - Lightweight alternative
- Custom image with Bazel pre-installed

### Environment Variables

Configured in `.gitlab-ci.yml`:

```yaml
ANDROID_COMPILE_SDK: "34"
ANDROID_BUILD_TOOLS: "34.0.0"
ANDROID_SDK_TOOLS: "9477386"
ANDROID_NDK_VERSION: "25.1.8937393"
BAZEL_VERSION: "7.2.1"
ANDROID_PACKAGE_NAME: "com.engindearing.omnitak"
APP_NAME: "OmniTAK"
```

### Caching

The pipeline caches the following to speed up builds:

- `.gradle/` - Gradle dependencies
- `.bazel-cache/` - Bazel build cache
- `modules/omnitak_mobile/android/native/lib/` - Rust native libraries
- `third-party/` - Third-party dependencies

**Cache key**: `${CI_COMMIT_REF_SLUG}` (per-branch caching)

### Artifacts

Build artifacts are preserved for:

| Artifact | Retention | Access |
|----------|-----------|--------|
| Debug APK | 1 week | All branches |
| Release APK | 1 month | main/master/tags only |
| Distribution package | 1 month | All branches |
| Native libraries | 1 day | All branches |

## Setup Instructions

### 1. GitLab Runner Configuration

Ensure your GitLab Runner has sufficient resources:

**Minimum requirements:**
- **CPU**: 4 cores
- **RAM**: 8 GB
- **Disk**: 50 GB free space
- **Executor**: Docker

**Recommended:**
- **CPU**: 8 cores
- **RAM**: 16 GB
- **Disk**: 100 GB SSD

### 2. GitLab CI/CD Variables (Optional)

Configure in GitLab: **Settings → CI/CD → Variables**

| Variable | Description | Required | Protected |
|----------|-------------|----------|-----------|
| `OMNI_TAK_REPO_URL` | URL to omni-TAK repository (if separate) | No | Yes |
| `OMNI_TAK_DEPLOY_KEY` | SSH key for omni-TAK repo access | No | Yes |
| `ANDROID_KEYSTORE_FILE` | Base64-encoded release keystore | No | Yes |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password | No | Yes |
| `ANDROID_KEY_ALIAS` | Signing key alias | No | Yes |
| `ANDROID_KEY_PASSWORD` | Key password | No | Yes |

### 3. Rust Library Handling

The pipeline has three options for handling Rust native libraries:

#### Option A: Pre-built Libraries (Current Default)

Libraries are cached and reused across builds:

```yaml
build_rust_libraries:
  script:
    - # Check cache for existing libraries
    - # Skip build if found
```

**To use**: Build libraries locally and commit to repo or cache them in first pipeline run.

#### Option B: Build from Separate Repository

Clone and build from omni-TAK repository:

```yaml
build_rust_libraries:
  before_script:
    - git clone ${OMNI_TAK_REPO_URL} /tmp/omni-TAK
    - export OMNI_TAK_DIR=/tmp/omni-TAK
  script:
    - cd modules/omnitak_mobile
    - ./build_android.sh
```

**Requirements**:
- Set `OMNI_TAK_REPO_URL` CI/CD variable
- Configure deploy key if private repository

#### Option C: Build from Submodule

If omni-TAK is a Git submodule:

```yaml
variables:
  GIT_SUBMODULE_STRATEGY: recursive

build_rust_libraries:
  script:
    - export OMNI_TAK_DIR=${CI_PROJECT_DIR}/omni-TAK
    - cd modules/omnitak_mobile
    - ./build_android.sh
```

### 4. Enable Pipeline

The pipeline is configured to run on:

- **All branches**: Debug builds, validation, testing
- **main/master branches**: Release builds
- **Tags**: Release builds with extended artifact retention

**Trigger conditions:**
```yaml
only:
  - branches  # All branches
  - tags      # All tags
```

## Usage

### Automatic Builds

Builds trigger automatically on:
- Push to any branch
- Merge request creation/update
- Tag creation

### Manual Builds

Trigger a pipeline manually:

1. Navigate to **CI/CD → Pipelines**
2. Click **Run Pipeline**
3. Select branch/tag
4. Click **Run Pipeline**

### Downloading Artifacts

After a successful build:

1. Navigate to **CI/CD → Pipelines**
2. Click on the pipeline ID
3. Click on job (e.g., `build_android_apk`)
4. Click **Download** next to artifacts

**Or use GitLab API:**
```bash
curl --header "PRIVATE-TOKEN: <your_token>" \
  "https://gitlab.com/api/v4/projects/<project_id>/jobs/artifacts/<branch>/download?job=build_android_apk" \
  --output omnitak-android.zip
```

## Customization

### Change Target SDK Version

Edit `.gitlab-ci.yml`:

```yaml
variables:
  ANDROID_COMPILE_SDK: "35"  # Change to desired API level
  ANDROID_BUILD_TOOLS: "35.0.0"
```

### Build for Specific ABIs Only

To reduce build time and APK size:

```yaml
build_android_apk:
  script:
    - bazel build //apps/omnitak_android --fat_apk_cpu=arm64-v8a
```

Supported ABIs:
- `arm64-v8a` - 64-bit ARM (modern devices)
- `armeabi-v7a` - 32-bit ARM (older devices)
- `x86_64` - 64-bit Intel (emulators)
- `x86` - 32-bit Intel (legacy)

### Add Code Signing for Release

Update `build_android_release` job:

```yaml
build_android_release:
  script:
    - bazel build -c opt //apps/omnitak_android

    # Decode keystore from CI/CD variable
    - echo "$ANDROID_KEYSTORE_FILE" | base64 -d > release.keystore

    # Sign APK
    - jarsigner -verbose \
        -sigalg SHA256withRSA \
        -digestalg SHA-256 \
        -keystore release.keystore \
        -storepass "$ANDROID_KEYSTORE_PASSWORD" \
        -keypass "$ANDROID_KEY_PASSWORD" \
        bazel-bin/apps/omnitak_android/omnitak_android.apk \
        "$ANDROID_KEY_ALIAS"

    # Zipalign
    - zipalign -v 4 \
        bazel-bin/apps/omnitak_android/omnitak_android.apk \
        build-outputs/omnitak-release-signed.apk
```

### Add Deployment Stage

Deploy to Firebase App Distribution, Google Play, or internal server:

```yaml
deploy_firebase:
  stage: deploy
  dependencies:
    - build_android_release
  script:
    - npm install -g firebase-tools
    - firebase appdistribution:distribute \
        build-outputs/omnitak-release-signed.apk \
        --app "$FIREBASE_APP_ID" \
        --groups "internal-testers" \
        --token "$FIREBASE_TOKEN"
  only:
    - tags
  when: manual
```

## Troubleshooting

### Pipeline Fails at `setup_environment`

**Issue**: Bazel or Rust installation fails

**Solution**:
- Check Docker image compatibility
- Verify network access for downloads
- Consider using custom Docker image with pre-installed tools

### Pipeline Fails at `build_rust_libraries`

**Issue**: Rust libraries not found or build fails

**Solutions**:
1. **Pre-build libraries locally** and commit to repository
2. **Configure access** to omni-TAK repository (see Option B above)
3. **Use cached libraries** from previous successful build

### Pipeline Fails at `build_android_apk`

**Issue**: Bazel build errors

**Common causes:**
- Missing native libraries → Check `build_rust_libraries` artifacts
- Wrong Bazel version → Verify `BAZEL_VERSION` matches `.bazelversion`
- Insufficient disk space → Increase runner disk allocation
- Memory issues → Increase runner RAM allocation

**Debug commands to add:**
```yaml
script:
  - bazel version  # Verify Bazel version
  - bazel info  # Check Bazel configuration
  - find modules/omnitak_mobile/android/native/lib/ -name "*.a"  # Verify libraries
  - bazel build //apps/omnitak_android --verbose_failures  # Detailed errors
```

### APK Size Too Large

**Issue**: APK includes all ABIs and is 30+ MB

**Solutions:**
1. **Build split APKs** for each ABI:
   ```yaml
   script:
     - bazel build //apps/omnitak_android --fat_apk_cpu=arm64-v8a
     - bazel build //apps/omnitak_android --fat_apk_cpu=armeabi-v7a
   ```

2. **Enable ProGuard/R8** for release builds:
   ```groovy
   // modules/omnitak_mobile/android/build.gradle
   buildTypes {
       release {
           minifyEnabled true
           shrinkResources true
       }
   }
   ```

### Build Takes Too Long

**Issue**: Pipeline exceeds time limits

**Solutions:**
1. **Optimize cache usage** - Ensure caching is working
2. **Use faster runner** - Dedicated runner with more resources
3. **Parallel builds** - Build different ABIs in parallel jobs
4. **Skip unnecessary stages** - Use `rules:` to skip stages for draft MRs

Example parallel ABI builds:
```yaml
build_android_arm64:
  extends: .build_apk_template
  script:
    - bazel build //apps/omnitak_android --fat_apk_cpu=arm64-v8a
  parallel:
    matrix:
      - ABI: [arm64-v8a, armeabi-v7a, x86_64]
```

## Performance Optimization

### Build Times

Expected build times (8-core runner):

| Job | First Run | Cached Run |
|-----|-----------|------------|
| setup_environment | ~5 min | ~1 min |
| validate_project | ~30 sec | ~20 sec |
| build_rust_libraries | ~20 min | ~30 sec (cached) |
| build_android_apk | ~15 min | ~5 min |
| **Total** | **~40 min** | **~7 min** |

### Cache Optimization

Increase cache hit rate:

```yaml
cache:
  key:
    files:
      - MODULE.bazel
      - apps/omnitak_android/BUILD.bazel
      - modules/omnitak_mobile/BUILD.bazel
  paths:
    - .gradle/
    - .bazel-cache/
    - $HOME/.cache/bazel
```

### Runner Tags

Use specific runners for Android builds:

```yaml
build_android_apk:
  tags:
    - android
    - docker
    - high-memory
```

## Security Considerations

### Secrets Management

**Never commit:**
- Signing keystores
- API keys
- Passwords
- Private keys

**Use GitLab CI/CD variables instead:**
- Mark sensitive variables as "Protected" and "Masked"
- Use File-type variables for keystores
- Limit access to main/protected branches

### Docker Image Security

**Recommendations:**
1. Use specific image tags (not `latest`)
2. Scan images for vulnerabilities
3. Use private registry for custom images
4. Regularly update base images

### APK Signing

**Best practices:**
1. Use separate signing keys for debug/release
2. Store release keystore in secure vault (HashiCorp Vault, AWS Secrets Manager)
3. Rotate signing keys periodically
4. Use Google Play App Signing for production

## Monitoring and Notifications

### Pipeline Status Badges

Add to README.md:

```markdown
[![Pipeline Status](https://gitlab.com/<namespace>/<project>/badges/<branch>/pipeline.svg)](https://gitlab.com/<namespace>/<project>/-/commits/<branch>)
```

### Email Notifications

Configure in `.gitlab-ci.yml`:

```yaml
build_android_apk:
  after_script:
    - |
      if [ "$CI_JOB_STATUS" == "failed" ]; then
        # Send notification (configure email service)
        echo "Build failed for commit ${CI_COMMIT_SHORT_SHA}"
      fi
```

### Slack/Discord Notifications

Use webhooks:

```yaml
notify_slack:
  stage: .post
  script:
    - |
      curl -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"Android build completed: ${CI_PIPELINE_URL}\"}" \
        "${SLACK_WEBHOOK_URL}"
  when: always
```

## Next Steps

### Immediate

- [x] Create `.gitlab-ci.yml` configuration
- [ ] Test pipeline on GitLab
- [ ] Configure CI/CD variables (if needed)
- [ ] Verify artifact downloads work

### Short-term

- [ ] Add APK signing for release builds
- [ ] Set up deployment to Firebase App Distribution
- [ ] Configure automated testing (unit tests, instrumented tests)
- [ ] Add code quality checks (lint, static analysis)
- [ ] Set up automatic version bumping

### Long-term

- [ ] Implement split APKs for reduced size
- [ ] Add App Bundle (.aab) generation for Google Play
- [ ] Configure automatic Play Store deployment
- [ ] Set up performance monitoring integration
- [ ] Add screenshot testing
- [ ] Implement nightly builds with extended tests

## References

- [GitLab Mobile DevOps Tutorial - Android](https://docs.gitlab.com/ci/mobile_devops/mobile_devops_tutorial_android/)
- [GitLab CI/CD Variables](https://docs.gitlab.com/ee/ci/variables/)
- [GitLab CI/CD Caching](https://docs.gitlab.com/ee/ci/caching/)
- [Android Build Tools](https://developer.android.com/studio/releases/build-tools)
- [Bazel Build System](https://bazel.build/)
- [Valdi Framework Documentation](https://github.com/Snapchat/valdi)

## Support

For issues with the CI/CD pipeline:

1. Check pipeline logs in GitLab UI
2. Review this documentation
3. Check `ANDROID_BUILD_SETUP.md` for build prerequisites
4. File an issue in the repository with:
   - Pipeline URL
   - Error messages
   - Runner configuration

---

**Created**: 2025-11-10
**Last Updated**: 2025-11-10
**Maintainer**: Development Team
