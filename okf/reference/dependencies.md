---
type: Reference
title: Dependency Inventory
description: The Dart/Flutter packages the app depends on, and why — no network, analytics, or crash-reporting SDKs.
resource: https://github.com/neotamizhan/petrol_log/blob/main/pubspec.yaml
tags: [reference, dependencies]
timestamp: 2026-06-21T00:00:00Z
---

# Runtime

| Package | Version | Purpose |
|---|---|---|
| `provider` | ^6.1.1 | Reactive state management (ChangeNotifier) — see [RecordsProvider](/state/records-provider.md) |
| `shared_preferences` | ^2.2.2 | On-device key-value persistence — see [Storage Keys](/reference/storage-keys.md) |
| `google_fonts` | ^8.1.0 | Space Grotesk typography |
| `intl` | ^0.20.2 | Date/number formatting, localization |
| `csv` | ^8.0.0 | CSV parsing for [import](/services/import-service.md) |
| `file_picker` | ^11.0.2 | Cross-platform file selection dialog |
| `cupertino_icons` | ^1.0.6 | iOS-style icon set |

# Dev

| Package | Version | Purpose |
|---|---|---|
| `flutter_lints` | ^6.0.0 | Lint rules |
| `mocktail` | ^1.0.4 | Test mocking |

**No network packages. No analytics SDKs. No crash reporting SDKs** — consistent with the
fully offline design of the [system](/system.md).

# Citations

[1] [pubspec.yaml](https://github.com/neotamizhan/petrol_log/blob/main/pubspec.yaml)
