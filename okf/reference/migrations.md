---
type: Reference
title: Data Migrations
description: The on-load migrations that convert legacy SharedPreferences data into the current model shape.
tags: [reference, migration, persistence]
timestamp: 2026-06-21T00:00:00Z
---

# Migrations

Run by the [StorageService](/services/storage-service.md) / [RecordsProvider](/state/records-provider.md)
during the startup load, before sanitization.

| Migration | Trigger | Action |
|---|---|---|
| `_migrateLegacyFuelSettings` | `fuel_price_per_liter` key exists on load | Creates a `Regular` [FuelType](/models/fuel-type.md) from the stored price and current global currency; removes the old key |
| `_migrateFuelTypeCurrencies` | Stored `fuel_types` entries missing `currency` | Backfills each fuel type with the current global currency so existing [records](/models/fill-record.md) keep a usable display currency |
| `_migrateToVehicleSupport` | `vehicles` key empty but `fill_records` exist | Creates a `My Vehicle` default [Vehicle](/models/vehicle.md); sets `vehicleId` on all existing records |
| `_migrateFillRecordPrices` | `fill_records` exist with no `pricePerLiter` | Stamps each legacy [FillRecord](/models/fill-record.md) with its fuel type's current price, freezing historical volumes against later fuel-type price changes |

See [Storage Keys](/reference/storage-keys.md) for the keys involved.

# Citations

[1] [storage_service.dart](https://github.com/neotamizhan/petrol_log/blob/main/lib/services/storage_service.dart)
