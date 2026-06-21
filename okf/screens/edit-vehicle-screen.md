---
type: Screen
title: EditVehicleScreen
description: Pre-filled vehicle form for editing an existing vehicle, with an added delete action.
resource: https://github.com/neotamizhan/petrol_log/blob/main/lib/screens/edit_vehicle_screen.dart
tags: [screen, ui, vehicle, form]
timestamp: 2026-06-21T00:00:00Z
---

# Purpose

The vehicle form pre-filled from an existing [Vehicle](/models/vehicle.md), with a Delete
action. Vehicles that have records are **soft-deleted**. Save/Delete call `updateVehicle`
/ `deleteVehicle` on the [RecordsProvider](/state/records-provider.md). Reached from
[VehiclesScreen](/screens/vehicles-screen.md).

# Citations

[1] [edit_vehicle_screen.dart](https://github.com/neotamizhan/petrol_log/blob/main/lib/screens/edit_vehicle_screen.dart)
