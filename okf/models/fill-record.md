---
type: Data Model
title: FillRecord
description: Immutable value object representing a single fuel fill event for a vehicle, with computed mileage and distance helpers.
resource: https://github.com/neotamizhan/petrol_log/blob/main/lib/models/fill_record.dart
tags: [model, fuel, immutable]
timestamp: 2026-06-21T00:00:00Z
---

# Schema

| Field | Type | Description |
|---|---|---|
| `id` | String | Primary key |
| `date` | DateTime | When the fill occurred |
| `odometerKm` | double | Odometer reading at fill time |
| `cost` | double | Amount paid for the fill |
| `notes` | String | Free-text notes |
| `fuelTypeId` | String | FK → [FuelType](/models/fuel-type.md) |
| `vehicleId` | String | FK → [Vehicle](/models/vehicle.md) |

# Computed Properties

- `getDistanceSinceLastFill()` — km between this fill and the previous one
- `getFuelAddedLiters()` — volume derived from `cost / pricePerLiter`
- `getMileage()` — distance per litre for this interval
- `getDaysSinceLastFill()` — elapsed days since the previous fill

Fuel volume is **derived**, not stored: it depends on the [FuelType](/models/fuel-type.md)
`pricePerLiter` in effect. Records are kept sorted by date descending by the
[StorageService](/services/storage-service.md).

These records are the primary input to [Overall Stats](/metrics/overall-stats.md) and
the [Refill Forecast](/metrics/refill-forecast.md).

# Citations

[1] [fill_record.dart](https://github.com/neotamizhan/petrol_log/blob/main/lib/models/fill_record.dart)
[2] [fill_record_test.dart](https://github.com/neotamizhan/petrol_log/blob/main/test/models/fill_record_test.dart)
