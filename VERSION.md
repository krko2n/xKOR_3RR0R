# xKOR_3RR0R Version Management

Current version: **2.0.1-beta.1**

---

## Version Bumping

Use the automated version bump script to increment versions across all files:

```bash
./scripts/bump-version.sh [TYPE]
```

### Version Types

| Type | Description | Example |
|------|-------------|---------|
| `patch` | Bug fixes, minor updates | 2.0.0 → 2.0.1 |
| `minor` | New features, non-breaking | 2.0.0 → 2.1.0 |
| `major` | Breaking changes | 2.0.0 → 3.0.0 |
| `pre` | Pre-release increment | 2.0.0-beta.1 → 2.0.0-beta.2 |
| `release` | Remove pre-release tag | 2.0.0-beta.1 → 2.0.0 |

### Examples

```bash
# Bug fix release
./scripts/bump-version.sh patch

# New feature
./scripts/bump-version.sh minor

# Major release
./scripts/bump-version.sh major

# Beta increment
./scripts/bump-version.sh pre

# Stable release
./scripts/bump-version.sh release
```

---

## Release Workflow

### 1. Bump Version

```bash
./scripts/bump-version.sh patch
```

### 2. Review Changes

```bash
git diff
```

### 3. Commit

```bash
git commit -am "chore(release): bump version to X.Y.Z"
```

### 4. Tag

```bash
git tag vX.Y.Z
```

### 5. Push

```bash
git push && git push --tags
```

---

## Versioned Files

The bump script automatically updates:

- `package.json`
- `src-tauri/Cargo.toml`
- `src-tauri/tauri.conf.json`
- `install.sh`
- `upgrade.sh`
- `uninstall.sh`
- `xkor-doctor.sh`

---

## Version History

### 2.0.1-beta.1 (2026-05-23)
- ✨ Premium upgrade UI with animated spinners
- ✨ Auto-versioning system with bump-version.sh
- 🐛 Fixed boot sequence script loading order
- 🐛 Added debug logging and boot bypass (ESC key)
- 🐛 Added failsafe timeout for boot animation

### 2.0.0-beta.1 (2026-05-XX)
- ✨ Professional installation system (multi-distro)
- ✨ Smart upgrade with automatic backup/rollback
- ✨ System diagnostics with auto-fix
- ✨ Safe uninstall with config preservation
- 🎨 Modular frontend architecture
- 🎨 Theme system with JSON configs
- 🎨 5-terminal orchestration
- 🎨 Event-driven audio system
- 🎨 Three.js WebGL globe renderer

---

## Semantic Versioning

xKOR_3RR0R follows [Semantic Versioning 2.0.0](https://semver.org/):

**MAJOR.MINOR.PATCH[-PRERELEASE]**

- **MAJOR**: Incompatible API changes
- **MINOR**: Backward-compatible functionality
- **PATCH**: Backward-compatible bug fixes
- **PRERELEASE**: alpha, beta, rc (optional)

---

## Pre-release Stages

| Stage | Description | Example |
|-------|-------------|---------|
| `alpha` | Early development, unstable | 2.0.0-alpha.1 |
| `beta` | Feature-complete, testing | 2.0.0-beta.1 |
| `rc` | Release candidate, final testing | 2.0.0-rc.1 |
| (none) | Stable release | 2.0.0 |

---

## Support

- **GitHub**: https://github.com/krko2n/xKOR_3RR0R
- **Issues**: https://github.com/krko2n/xKOR_3RR0R/issues
- **Releases**: https://github.com/krko2n/xKOR_3RR0R/releases
