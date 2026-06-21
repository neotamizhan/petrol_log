---
type: Screen
title: MaintenanceScreen
description: Service history for a vehicle with Overdue / Due Soon / On Track status badges.
resource: https://github.com/neotamizhan/petrol_log/blob/main/lib/screens/maintenance_screen.dart
tags: [screen, ui, maintenance]
timestamp: 2026-06-21T00:00:00Z
---

# Purpose

Shows the [MaintenanceRecord](/models/maintenance-record.md) history per
[Vehicle](/models/vehicle.md), with status badges driven by
[Maintenance Due Status](/metrics/maintenance-due-status.md) (Overdue / Due Soon / On
Track). The FAB and history rows open the [LogEntryScreen](/screens/log-entry.md) in service
mode. Reached
from the [HomeScreen](/screens/home-screen.md) maintenance card.

# Citations

[1] [maintenance_screen.dart](https://github.com/neotamizhan/petrol_log/blob/main/lib/screens/maintenance_screen.dart)
