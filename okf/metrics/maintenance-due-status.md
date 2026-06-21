---
type: Metric
title: Maintenance Due Status
description: Per-schedule maintenance status (overdue, due soon, on track, completed) evaluated only for the newest record in each schedule.
tags: [metric, maintenance, alerting]
timestamp: 2026-06-21T00:00:00Z
---

# Definition

`getMaintenanceDueStatus` on the [RecordsProvider](/state/records-provider.md)
evaluates the status of each maintenance schedule. Schedules are keyed by
`(vehicleId, normalizedServiceType)` — the `scheduleKey` of a
[MaintenanceRecord](/models/maintenance-record.md).

Only the **newest** record in a schedule is evaluated. Older records are superseded
history and return `completed` rather than recomputing from stale due targets. For the
newest record, the odometer and date dimensions are evaluated **independently** and the
more urgent dimension wins.

| Condition | Status |
|---|---|
| Newer record exists for same vehicle/service schedule | `completed` |
| No due target set | `completed` |
| Past due odometer **or** past due date | `overdue` |
| Within 500 km **or** within 14 days of a target | `due_soon` |
| Has a target and not near | `on_track` |

Surfaced on the [Maintenance screen](/screens/maintenance-screen.md) status badges and
the [Home screen](/screens/home-screen.md) care panel.

# Citations

[1] [records_provider.dart](https://github.com/neotamizhan/petrol_log/blob/main/lib/providers/records_provider.dart)
