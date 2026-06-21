---
type: Screen
title: StatsScreen
description: Analytics dashboard presenting fuel, cost, cadence, forecast, and cost-of-ownership stats, filterable by vehicle and fuel type.
resource: https://github.com/neotamizhan/petrol_log/blob/main/lib/screens/stats_screen.dart
tags: [screen, ui, analytics, charts]
timestamp: 2026-06-21T00:00:00Z
---

# Purpose

Analytics dashboard rendering [Overall Stats](/metrics/overall-stats.md) and the
[Refill Forecast](/metrics/refill-forecast.md). Filters by [Vehicle](/models/vehicle.md)
and [FuelType](/models/fuel-type.md), backed by the provider's combined filter. Reached
from the [HomeScreen](/screens/home-screen.md) header insights action.

# Sections

Top to bottom:

- **Overview grid** — total fills, total spent, distance, total fuel, avg mileage, duration.
- **Spending** — cost/km, cost/litre, avg fill, plus priciest/cheapest fill.
- **Efficiency** — average mileage gauge with best/worst trip.
- **Spend by Fuel Type** — `fl_chart` donut of `spendByFuelType`; shown only when no
  fuel-type filter is active and ≥2 fuel types have spend.
- **Monthly Spend** — `fl_chart` bar chart of recent months with touch tooltips.
- **Fill Cadence** — avg days between fills, fills/month, active-since date, tracked span.
- **Next Refill Forecast** — reuses [getRefillForecast](/metrics/refill-forecast.md); hidden
  when fewer than two records exist.
- **Cost of Ownership** — fuel + [maintenance](/metrics/maintenance-due-status.md) spend split
  (uses `getMaintenanceOverview`); shown only when no fuel-type filter is active, because
  maintenance has no fuel type and uses the global currency.

Charts are rendered with the [`fl_chart`](/reference/dependencies.md) package.

# Citations

[1] [stats_screen.dart](https://github.com/neotamizhan/petrol_log/blob/main/lib/screens/stats_screen.dart)
