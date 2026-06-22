---
type: Screen
title: LogEntryScreen
description: Unified Log screen for recording a fuel fill or a service entry, in create or edit mode, with a Fuel/Service toggle and smart defaults.
resource: https://github.com/neotamizhan/petrol_log/blob/main/lib/screens/log_entry_screen.dart
tags: [screen, ui, fuel, maintenance, form]
timestamp: 2026-06-21T00:00:00Z
---

# Purpose

The single capture surface for the [Product Vision](/reference/product-vision.md)'s "logging
must feel free" principle. Handles `{fuel | service} × {create | edit}` in one screen,
replacing the former separate add-fuel, edit-fuel, and add/edit-service screens.

# Behaviour

- **Mode toggle** — a Fuel/Service segmented control (default **Fuel**). Locked (shown as a
  static label) in edit mode, since a saved entry's type cannot change.
- **Shared fields** — [Vehicle](/models/vehicle.md), date (+ time for fuel), odometer (with a
  "Last: X km" hint from `Vehicle.currentOdometer`), cost, notes.
- **Fuel mode** — [FuelType](/models/fuel-type.md) dropdown, an **editable price/litre**
  (defaulted from the last fill via `lastFuelPriceForVehicleFuelType`), and live derived
  volume; produces a [FillRecord](/models/fill-record.md) (carrying its own `pricePerLiter`)
  via `addRecord`/`updateRecord`. This removes the recurring need to edit prices in Settings.
- **Service mode** — service type with starter-preset chips, category, optional next-due
  odometer/date; produces a [MaintenanceRecord](/models/maintenance-record.md) via
  `addMaintenanceRecord`/`updateMaintenanceRecord`.
- **Smart defaults** — vehicle = selected; fuel type = `lastFuelTypeIdForVehicle`; service
  type pre-fill via the last-used preset.
- **Edit mode** — pre-fills from the record and exposes Delete.

All persistence goes through the [RecordsProvider](/state/records-provider.md); the underlying
`FillRecord` and `MaintenanceRecord` models remain separate.

# Entry points

Reached from the [HomeScreen](/screens/home-screen.md) Log FAB (fuel), next-step cards
(service), and timeline taps (edit), and from the [MaintenanceScreen](/screens/maintenance-screen.md)
FAB and history rows. See the [Navigation Map](/reference/navigation-map.md).

# Citations

[1] [log_entry_screen.dart](https://github.com/neotamizhan/petrol_log/blob/main/lib/screens/log_entry_screen.dart)
[2] [Unified Log Flow spec](https://github.com/neotamizhan/petrol_log/blob/main/docs/specs/unified-log-flow.md)
