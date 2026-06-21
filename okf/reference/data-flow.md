---
type: Reference
title: State & Data Flow
description: The reactive update cycle and app startup sequence connecting screens, the provider, services, and SharedPreferences.
tags: [reference, state, dataflow]
timestamp: 2026-06-21T00:00:00Z
---

# Reactive Update Cycle

When the driver saves a record:

1. The [Screen](/screens/index.md) calls a [RecordsProvider](/state/records-provider.md) method (e.g. `addRecord`).
2. The provider appends to its in-memory list and updates the [Vehicle](/models/vehicle.md) `currentOdometer`.
3. The provider delegates persistence to the [StorageService](/services/storage-service.md), which writes JSON to SharedPreferences.
4. The provider calls `notifyListeners()`.
5. Widgets consuming `Consumer<RecordsProvider>` rebuild and the new data appears.

# App Startup Sequence

1. `main.dart` creates the `ChangeNotifierProvider`.
2. `RecordsProvider._loadAll()` runs in the constructor.
3. It reads all keys via the StorageService (records, fuel types, vehicles, maintenance).
4. Migrations apply if needed (see [Migrations](/reference/migrations.md)).
5. Sanitizers run: `_sanitizeFuelTypes`, `_sanitizeVehicles`, `_normalizeRecordFuelTypes`.
6. `_isLoading = false` and `notifyListeners()` — the UI renders with data.

# Multi-Dimensional Filtering

`_filteredRecordsByFuelTypeAndVehicle()` applies vehicle and fuel-type filters together
and backs every analytics method. `null` / `'all'` means no filter on that dimension; a
specific ID filters to matching records.

# Citations

[1] [ARCHITECTURE.md §6](https://github.com/neotamizhan/petrol_log/blob/main/docs/ARCHITECTURE.md)
