# OmniTAK Mobile Dependencies - Quick Reference

## One-Liner Commands

```bash
# Verify configuration
./scripts/verify_dependencies.sh

# Setup all dependencies
./scripts/setup_dependencies.sh

# Clean build everything
./scripts/clean_build.sh --all

# Build OmniTAK Mobile
bazel build //modules/omnitak_mobile:omnitak_mobile
```

## Key Dependency Versions

| Component | Version |
|-----------|---------|
| MapLibre Android | 11.5.2 |
| MapLibre iOS | 6.8.0 |
| milsymbol | 2.2.0 |
| maplibre-gl (NPM) | 4.7.1 |
| @turf/turf | 7.1.0 |
| RapidJSON | 1.1.0 |
| SQLite | 3.45.1 |

## File Locations

- **Main Config:** `bzl/omnitak_dependencies.bzl`
- **Bazel Module:** `MODULE.bazel`
- **Workspace:** `WORKSPACE`
- **NPM Packages:** `package.json`
- **Documentation:** `DEPENDENCIES.md`
- **Build Files:** `third-party/*/` directories

## Common Tasks

### Add Android Dependency
```python
# In MODULE.bazel, add to maven.install artifacts:
"com.example:library:1.0.0",
```

### Add iOS Framework
```python
# In MODULE.bazel or bzl/omnitak_dependencies.bzl:
http_archive(
    name = "framework_name",
    url = "...",
    build_file = "@valdi//third-party/framework_name:framework.BUILD",
)
```

### Add NPM Package
```json
// In package.json:
{
  "dependencies": {
    "package-name": "^1.0.0"
  }
}
```
Then run: `npm install`

### Clean Specific Cache
```bash
# Bazel only
./scripts/clean_build.sh --bazel --no-build

# NPM only
./scripts/clean_build.sh --npm --no-build

# External deps
./scripts/clean_build.sh --external --no-build
```

## Troubleshooting

| Problem | Quick Fix |
|---------|-----------|
| Maven resolution failure | `bazel clean --expunge` |
| NPM install errors | `rm -rf node_modules package-lock.json && npm install` |
| Checksum mismatch | Recalculate: `shasum -a 256 file.tar.gz` |
| iOS build errors | `./scripts/clean_build.sh --all` |
| Missing Android SDK | Set `ANDROID_HOME` environment variable |

## Essential Links

- **Full Docs:** [DEPENDENCIES.md](DEPENDENCIES.md)
- **Setup Summary:** [DEPENDENCY_SETUP_SUMMARY.md](DEPENDENCY_SETUP_SUMMARY.md)
- **Build Guide:** [modules/omnitak_mobile/BUILD_GUIDE.md](modules/omnitak_mobile/BUILD_GUIDE.md)
- **MapLibre Docs:** https://maplibre.org/
