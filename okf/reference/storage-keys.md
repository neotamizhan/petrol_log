---
type: Reference
title: SharedPreferences Storage Keys
description: The complete set of SharedPreferences keys used for on-device persistence, with their types and meaning.
tags: [reference, persistence, sharedpreferences]
timestamp: 2026-06-21T00:00:00Z
---

# Keys

All persistence flows through the [StorageService](/services/storage-service.md), which
stores JSON strings under these fixed keys:

| Key | Type | Description |
|---|---|---|
| `fill_records` | JSON array | All [FillRecord](/models/fill-record.md) objects |
| `fuel_types` | JSON array | All [FuelType](/models/fuel-type.md) objects, including per-type currency |
| `selected_fuel_type_id` | String | Currently active fuel type |
| `vehicles` | JSON array | All [Vehicle](/models/vehicle.md) objects |
| `selected_vehicle_id` | String | Currently selected vehicle |
| `maintenance_records` | JSON array | All [MaintenanceRecord](/models/maintenance-record.md) objects |
| `currency_symbol` | String | Global currency symbol (default `₹`) |
| `theme_mode` | String | `light` / `dark` / `system` |
| `fuel_price_per_liter` | double | **Legacy** key, migrated to FuelType — see [Migrations](/reference/migrations.md) |

# Citations

[1] [storage_service.dart](https://github.com/neotamizhan/petrol_log/blob/main/lib/services/storage_service.dart)
