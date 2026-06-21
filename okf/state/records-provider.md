---
type: State Container
title: RecordsProvider
description: Central ChangeNotifier that is the single source of truth for all app state, exposing reactive getters, CRUD, and analytics methods.
resource: https://github.com/neotamizhan/petrol_log/blob/main/lib/providers/records_provider.dart
tags: [state, provider, changenotifier]
timestamp: 2026-06-21T00:00:00Z
---

# Responsibilities

`RecordsProvider` (a `ChangeNotifier`, ~1110 lines) holds all in-memory state and
mediates between the [Screens](/screens/index.md) and the
[service layer](/services/index.md). UI reads it via `Consumer<RecordsProvider>` and
calls its methods; every mutation persists through a service then calls
`notifyListeners()`.

# Responsibilities by area

| Area | Methods | Notes |
|---|---|---|
| Initializer | `_loadAll()` | Loads all data on startup; runs migrations + sanitization |
| Fill records | `addRecord` / `updateRecord` / `deleteRecord` | Keeps [FillRecord](/models/fill-record.md) list sorted; advances vehicle odometer on add |
| Fuel types | `addFuelType` / `updateFuelType` / `deleteFuelType` | Manages [FuelType](/models/fuel-type.md) incl. per-type currency; soft-deletes types with records |
| Vehicles | `addVehicle` / `updateVehicle` / `deleteVehicle` | Manages [Vehicle](/models/vehicle.md) registry; soft-deletes with records |
| Maintenance | `addMaintenanceRecord` / `updateMaintenanceRecord` / `deleteMaintenanceRecord` | Newer records supersede older ones in the same schedule |
| Analytics | `getOverallStats` / `getRefillForecast` / `getMaintenanceOverview` / `getMaintenanceDueStatus` | Pure computation over in-memory state; no I/O |
| Settings | `setCurrency` / `setThemeMode` / `setFuelPrice` | Persists user preferences |
| Sanitizer | `_sanitizeFuelTypes` / `_sanitizeVehicles` / `_normalizeRecordFuelTypes` | Restores referential integrity after load/migration |

# Filtering

`_filteredRecordsByFuelTypeAndVehicle()` applies vehicle and fuel-type filters
simultaneously and backs every analytics method. A `null` or `'all'` value means no
filter on that dimension; a specific ID filters to matching records.

# Analytics produced

The analytics methods implement [Overall Stats](/metrics/overall-stats.md),
[Refill Forecast](/metrics/refill-forecast.md), and
[Maintenance Due Status](/metrics/maintenance-due-status.md), returning plain `Map`s
for UI consumption.

# Citations

[1] [records_provider.dart](https://github.com/neotamizhan/petrol_log/blob/main/lib/providers/records_provider.dart)
[2] [records_provider_test.dart](https://github.com/neotamizhan/petrol_log/blob/main/test/providers/records_provider_test.dart)
