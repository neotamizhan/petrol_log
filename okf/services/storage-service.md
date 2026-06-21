---
type: Service
title: StorageService
description: Wraps SharedPreferences with typed CRUD per entity and contains the migration logic for legacy on-device data.
resource: https://github.com/neotamizhan/petrol_log/blob/main/lib/services/storage_service.dart
tags: [service, persistence, sharedpreferences]
timestamp: 2026-06-21T00:00:00Z
---

# Responsibilities

`StorageService` is the only component that touches SharedPreferences. It exposes
typed CRUD for each entity and serializes domain models to JSON strings stored under
fixed keys — see [Storage Keys](/reference/storage-keys.md).

| Method pair | Entity | Notes |
|---|---|---|
| `getRecords` / `saveRecords` | [FillRecord](/models/fill-record.md) | Returned sorted by date descending |
| `getFuelTypes` / `saveFuelTypes` | [FuelType](/models/fuel-type.md) | Includes per-type currency |
| `getVehicles` / `saveVehicles` | [Vehicle](/models/vehicle.md) | |
| `getMaintenanceRecords` / `saveMaintenanceRecords` | [MaintenanceRecord](/models/maintenance-record.md) | |
| Settings accessors | currency · theme · selected IDs | Simple scalar keys |

# Migrations

On load, the service applies the migrations described in
[Migrations](/reference/migrations.md): `_migrateLegacyFuelSettings`,
`_migrateFuelTypeCurrencies`, and `_migrateToVehicleSupport`. These run before the
[RecordsProvider](/state/records-provider.md) sanitization pass.

# Citations

[1] [storage_service.dart](https://github.com/neotamizhan/petrol_log/blob/main/lib/services/storage_service.dart)
