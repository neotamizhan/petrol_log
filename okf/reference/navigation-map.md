---
type: Reference
title: Screen Navigation Map
description: How the app's screens connect, from splash through the home dashboard to the logging, stats, and settings flows.
tags: [reference, navigation, ui]
timestamp: 2026-06-21T00:00:00Z
---

# Flow

- App launch → [SplashScreen](/screens/splash-screen.md) (1.7 s) → [HomeScreen](/screens/home-screen.md).
- **HomeScreen** is the hub: selected-vehicle switcher, care status panel, next-step
  cards (maintenance + fuel forecast), and a combined service/fuel activity timeline.

From Home:

| Action | Destination |
|---|---|
| Log Activity FAB → Service | [AddMaintenanceScreen](/screens/add-maintenance-screen.md) |
| Log Activity FAB → Fuel | [AddRecordScreen](/screens/add-record-screen.md) |
| Header insights | [StatsScreen](/screens/stats-screen.md) |
| Header settings | [SettingsScreen](/screens/settings-screen.md) |
| Vehicle switcher → Manage | [VehiclesScreen](/screens/vehicles-screen.md) |
| Tap timeline service entry | [AddMaintenanceScreen](/screens/add-maintenance-screen.md) (edit) |
| Tap timeline fuel entry | [EditRecordScreen](/screens/edit-record-screen.md) |
| Tap maintenance card | [MaintenanceScreen](/screens/maintenance-screen.md) |

From [VehiclesScreen](/screens/vehicles-screen.md): FAB → [AddVehicleScreen](/screens/add-vehicle-screen.md);
tap a vehicle → [EditVehicleScreen](/screens/edit-vehicle-screen.md). From
[MaintenanceScreen](/screens/maintenance-screen.md): FAB → AddMaintenanceScreen. Save/Delete
actions return to the originating hub.

# Citations

[1] [ARCHITECTURE.md §7](https://github.com/neotamizhan/petrol_log/blob/main/docs/ARCHITECTURE.md)
