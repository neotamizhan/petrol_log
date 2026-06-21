---
type: Screen
title: AddMaintenanceScreen
description: Form for logging a service event with next-due targets; doubles as the edit screen for existing maintenance records.
resource: https://github.com/neotamizhan/petrol_log/blob/main/lib/screens/add_maintenance_screen.dart
tags: [screen, ui, maintenance, form]
timestamp: 2026-06-21T00:00:00Z
---

# Purpose

Form for a service event: service type, date, odometer, cost, optional next-due
odometer/date targets, and notes. Produces a [MaintenanceRecord](/models/maintenance-record.md)
via the [RecordsProvider](/state/records-provider.md); newer records supersede older ones
in the same schedule. Also used in **edit mode** when tapping a service entry on the
[HomeScreen](/screens/home-screen.md) timeline.

# Citations

[1] [add_maintenance_screen.dart](https://github.com/neotamizhan/petrol_log/blob/main/lib/screens/add_maintenance_screen.dart)
