---
type: Metric
title: Overall Stats
description: Aggregate fuel and cost statistics computed over the filtered set of fuel fill records.
tags: [metric, analytics, fuel, cost]
timestamp: 2026-06-21T00:00:00Z
---

# Definition

`getOverallStats` on the [RecordsProvider](/state/records-provider.md) aggregates the
[FillRecord](/models/fill-record.md) set (after vehicle/fuel-type filtering) into a
summary `Map`:

| Output | Calculation |
|---|---|
| `totalSpent` | Sum of all `FillRecord.cost` |
| `totalFuelLiters` | Sum of `cost / pricePerLiter` per record |
| `totalDistance` | Sum of `getDistanceSinceLastFill()` over consecutive pairs |
| `averageMileage` | `totalDistance / totalFuelLiters` |
| `bestMileage` / `worstMileage` | Max/min per-record mileage, with the associated record |
| `monthlySpending` | `Map<"YYYY-MM", double>` keyed by fill month |

Fuel volume depends on each [FuelType](/models/fuel-type.md)'s `pricePerLiter`.
Surfaced on the [Stats screen](/screens/stats-screen.md).

# Citations

[1] [records_provider.dart](https://github.com/neotamizhan/petrol_log/blob/main/lib/providers/records_provider.dart)
