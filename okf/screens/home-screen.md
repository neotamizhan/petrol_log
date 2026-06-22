---
type: Screen
title: HomeScreen
description: The vehicle logbook dashboard — selected vehicle, care status, next-step cards, and a combined service/fuel timeline.
resource: https://github.com/neotamizhan/petrol_log/blob/main/lib/screens/home_screen.dart
tags: [screen, ui, dashboard]
timestamp: 2026-06-21T00:00:00Z
---

# Purpose

The app's hub. It shows:

- A selected-[Vehicle](/models/vehicle.md) switcher (manage → [VehiclesScreen](/screens/vehicles-screen.md)).
- A care status panel: odometer, open items, and this month's spend.
- Next-step cards driven by [Maintenance Due Status](/metrics/maintenance-due-status.md)
  and the [Refill Forecast](/metrics/refill-forecast.md).
- A combined activity timeline merging [maintenance](/models/maintenance-record.md) and
  [fuel](/models/fill-record.md) entries.

A single **Log Activity** FAB opens the unified [LogEntryScreen](/screens/log-entry.md) in
Fuel mode (Service is a toggle inside); next-step cards deep-link into it for service. Header
actions open [StatsScreen](/screens/stats-screen.md) and [SettingsScreen](/screens/settings-screen.md).
See [Navigation Map](/reference/navigation-map.md).

# Citations

[1] [home_screen.dart](https://github.com/neotamizhan/petrol_log/blob/main/lib/screens/home_screen.dart)
