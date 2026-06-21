---
type: Screen
title: AddRecordScreen
description: Fuel log form capturing date, odometer, fuel type, cost, and notes, with auto-calculated volume.
resource: https://github.com/neotamizhan/petrol_log/blob/main/lib/screens/add_record_screen.dart
tags: [screen, ui, fuel, form]
timestamp: 2026-06-21T00:00:00Z
---

# Purpose

Form for logging a fuel fill: date, odometer, [fuel type](/models/fuel-type.md), cost,
and notes. Fuel volume is auto-calculated from cost and price. On save it calls
`addRecord` on the [RecordsProvider](/state/records-provider.md), producing a new
[FillRecord](/models/fill-record.md) and advancing the vehicle odometer.

# Citations

[1] [add_record_screen.dart](https://github.com/neotamizhan/petrol_log/blob/main/lib/screens/add_record_screen.dart)
