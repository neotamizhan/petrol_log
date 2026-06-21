---
type: Data Model
title: FuelType
description: Immutable fuel type carrying a per-litre price and its own display currency, referenced by fuel fill records.
resource: https://github.com/neotamizhan/petrol_log/blob/main/lib/models/fuel_type.dart
tags: [model, fuel, currency, immutable]
timestamp: 2026-06-21T00:00:00Z
---

# Schema

| Field | Type | Description |
|---|---|---|
| `id` | String | Primary key (stable, normalized from name) |
| `name` | String | Display name, e.g. `Regular`, `Premium`, `Diesel` |
| `pricePerLiter` | double | Price per litre, used to derive fill volume |
| `currency` | String | Per-type display currency symbol |
| `active` | bool | Soft-delete flag; types with records are deactivated, not removed |

# Behaviour

- `normalizeId()` sanitizes a raw name into a stable key, so renaming display text
  does not orphan existing [FillRecord](/models/fill-record.md) references.
- Each fuel type stores its **own** `currency`, independent of the global currency
  setting — pricing and fuel record displays render in the type's currency.
- Deleting a fuel type that has records performs a **soft delete** (sets `active=false`)
  to preserve referential integrity.

The [Data Sanitizer](/state/records-provider.md) backfills missing currencies and
normalizes record fuel-type references on load (see [Migrations](/reference/migrations.md)).

# Citations

[1] [fuel_type.dart](https://github.com/neotamizhan/petrol_log/blob/main/lib/models/fuel_type.dart)
[2] [fuel_type_test.dart](https://github.com/neotamizhan/petrol_log/blob/main/test/models/fuel_type_test.dart)
