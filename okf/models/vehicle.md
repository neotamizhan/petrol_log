---
type: Data Model
title: Vehicle
description: Immutable vehicle entity that owns fuel and maintenance records, with an odometer kept current by the provider.
resource: https://github.com/neotamizhan/petrol_log/blob/main/lib/models/vehicle.dart
tags: [model, vehicle, immutable]
timestamp: 2026-06-21T00:00:00Z
---

# Schema

| Field | Type | Description |
|---|---|---|
| `id` | String | Primary key |
| `name` | String | User-facing label |
| `make` | String | Manufacturer |
| `model` | String | Model name |
| `year` | int | Model year |
| `plateNumber` | String | Registration plate |
| `currentOdometer` | double | Latest known odometer; updated on each fill add |
| `isDefault` | bool | Marks the default vehicle |
| `active` | bool | Soft-delete flag |
| `createdAt` | DateTime | Creation timestamp |

# Behaviour

- A vehicle owns many [FillRecord](/models/fill-record.md) and
  [MaintenanceRecord](/models/maintenance-record.md) entries.
- `currentOdometer` is **not** edited directly during logging — the
  [RecordsProvider](/state/records-provider.md) advances it when a fill is added.
- Vehicles with existing records are **soft-deleted** (`active=false`) to keep history intact.
- Pre-vehicle data is assigned a default `My Vehicle` by the
  [vehicle-support migration](/reference/migrations.md).

# Citations

[1] [vehicle.dart](https://github.com/neotamizhan/petrol_log/blob/main/lib/models/vehicle.dart)
[2] [vehicle_test.dart](https://github.com/neotamizhan/petrol_log/blob/main/test/models/vehicle_test.dart)
