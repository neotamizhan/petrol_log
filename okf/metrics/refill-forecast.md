---
type: Metric
title: Refill Forecast
description: Weighted-average prediction of the next refill date with a confidence score derived from refill-interval consistency.
tags: [metric, forecasting, fuel]
timestamp: 2026-06-21T00:00:00Z
---

# Definition

`getRefillForecast` on the [RecordsProvider](/state/records-provider.md) predicts the
next refill date from recent [FillRecord](/models/fill-record.md) intervals.

# Algorithm

1. Take the **last 6** fill intervals (days between consecutive fills).
2. Compute a **weighted average** using recency weights `1..6`.
3. Compute the coefficient of variation `CV = stddev / mean`.
4. `consistency = max(0, 1 - CV)`.
5. `confidence = 0.7 × consistency + 0.3 × sampleScore`, clamped to **0.20 – 0.95**.
6. `forecastDays = weighted average days`.
7. `nextRefillDate = lastFill + forecastDays`.

# Status

Derived from days-since-last-fill versus `forecastDays`:

| Ratio | Status |
|---|---|
| `< 80%` | `on_track` |
| `80–100%` | `soon` |
| `> 100%` | `overdue` |

**Minimum records:** 2 (one interval). Surfaced on the
[Home screen](/screens/home-screen.md) next-step cards and the
[Stats screen](/screens/stats-screen.md).

# Citations

[1] [records_provider.dart](https://github.com/neotamizhan/petrol_log/blob/main/lib/providers/records_provider.dart)
