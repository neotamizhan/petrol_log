---
type: Data Model
title: MaintenanceRecord
description: Immutable service/maintenance event with optional next-due targets, grouped into schedules per vehicle and service type.
resource: https://github.com/neotamizhan/petrol_log/blob/main/lib/models/maintenance_record.dart
tags: [model, maintenance, immutable]
timestamp: 2026-06-21T00:00:00Z
---

# Schema

| Field | Type | Description |
|---|---|---|
| `id` | String | Primary key |
| `vehicleId` | String | FK → [Vehicle](/models/vehicle.md) |
| `serviceType` | String | e.g. Oil Change, Inspection |
| `category` | String | Grouping category |
| `serviceDate` | DateTime | When the service was performed |
| `odometerKm` | double | Odometer at service time |
| `cost` | double | Service cost |
| `notes` | String | Free-text notes |
| `nextDueOdometerKm` | double | Optional odometer target for next service |
| `nextDueDate` | DateTime | Optional date target for next service |
| `createdAt` | DateTime | Creation timestamp |

# Computed Properties

- `hasDueTarget` — whether a next-due odometer or date is set
- `normalizedServiceType` — stable form of the service type string
- `scheduleKey` — `(vehicleId, normalizedServiceType)`, the identity of a maintenance *schedule*

# Schedules

Records sharing a `scheduleKey` form one schedule. A newer record **supersedes**
older ones: superseded records report `completed` rather than recomputing overdue
status from stale targets. See [Maintenance Due Status](/metrics/maintenance-due-status.md).

# Citations

[1] [maintenance_record.dart](https://github.com/neotamizhan/petrol_log/blob/main/lib/models/maintenance_record.dart)
[2] [maintenance_record_test.dart](https://github.com/neotamizhan/petrol_log/blob/main/test/models/maintenance_record_test.dart)
