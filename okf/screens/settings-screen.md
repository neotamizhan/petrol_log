---
type: Screen
title: SettingsScreen
description: Preferences hub for fuel pricing, per-type and global currency, theme, fuel type management, and CSV import.
resource: https://github.com/neotamizhan/petrol_log/blob/main/lib/screens/settings_screen.dart
tags: [screen, ui, settings]
timestamp: 2026-06-21T00:00:00Z
---

# Purpose

Manages user preferences and configuration:

- Fuel pricing and per-type currency for [FuelType](/models/fuel-type.md) entries
- Global currency symbol and theme mode (`light` / `dark` / `system`)
- Fuel type management (add / edit / soft-delete)
- CSV import via the [ImportService](/services/import-service.md)

Settings persist through the [RecordsProvider](/state/records-provider.md) to the
[storage keys](/reference/storage-keys.md). Reached from the
[HomeScreen](/screens/home-screen.md) header settings action.

# Citations

[1] [settings_screen.dart](https://github.com/neotamizhan/petrol_log/blob/main/lib/screens/settings_screen.dart)
