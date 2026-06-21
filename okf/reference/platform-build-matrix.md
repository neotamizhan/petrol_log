---
type: Reference
title: Platform & Build Matrix
description: Supported target platforms and their release build commands, plus the static product website.
tags: [reference, build, platforms]
timestamp: 2026-06-21T00:00:00Z
---

# Build Matrix

One Dart codebase ships to all app platforms; the platform folders contain only native
configuration.

| Platform | Status | Build Command |
|---|---|---|
| Android | Supported | `flutter build apk --release` |
| iOS | Supported (pending bundle ID) | `flutter build ipa --release --no-codesign` |
| macOS | Supported | `flutter build macos --release` |
| Web | Supported | `flutter build web --release` |
| GitHub Pages product site | Supported | Static site served from `docs/` |

# Development commands

```bash
flutter test              # all tests — see Testing Strategy
flutter test --coverage   # with coverage report
flutter analyze           # static analysis
dart format lib test      # format before commit
```

The public product website and store-review legal pages (privacy, support, terms,
data-control) are static HTML/CSS under `docs/`. See [Testing Strategy](/reference/testing-strategy.md).

# Citations

[1] [ARCHITECTURE.md §10](https://github.com/neotamizhan/petrol_log/blob/main/docs/ARCHITECTURE.md)
