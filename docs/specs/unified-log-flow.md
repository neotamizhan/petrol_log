# Spec: Unified "Log" Flow

> **Status:** Proposed (not yet implemented). First streamlining step toward the
> [Product Vision](../VISION.md).
> **Author:** Product
> **Last updated:** 2026-06-21

## Why

The vision's #1 principle is **"logging must feel free."** Today, capture is split across
three screens and a two-option entry point, and forces fuel-type/price choices on every fill:

- [add_record_screen.dart](../../lib/screens/add_record_screen.dart) — add a fuel fill
- [edit_record_screen.dart](../../lib/screens/edit_record_screen.dart) — edit a fuel fill (+ delete)
- [add_maintenance_screen.dart](../../lib/screens/add_maintenance_screen.dart) — add **and** edit a service
- [home_screen.dart](../../lib/screens/home_screen.dart) — a "Log Activity" FAB that first makes the user pick *Service* or *Fuel*

To the user these are one act: *"something happened to my car — record it."* This spec unifies
them into a single **Log** action and one mode-aware screen, and front-loads smart defaults so a
routine fuel fill is **≤4 taps, <10 seconds**.

## Goals & success criteria

- **One entry point.** A single **Log** FAB; no "Service or Fuel?" pre-prompt.
- **One screen.** Collapse the three screens above into one `LogEntryScreen` handling
  `{fuel | service} × {create | edit}`. Net screen count 11 → 9.
- **Logging feels free.** Typical fuel fill: ≤4 taps, <10s, zero Settings detour (validated in usability testing — no telemetry).
- **No regressions.** Stats, forecasting, maintenance schedules, currency handling, and CSV import behave exactly as before.

## Scope & non-goals

- **UX-layer unification only.** Keep `FillRecord` and `MaintenanceRecord` as separate models
  and keep the provider's separate methods. This preserves the schedule logic, migrations, and
  analytics, and keeps the change low-risk.
- **No storage/key changes**, no change to `getOverallStats` / `getRefillForecast` /
  `getMaintenanceOverview`, no analytics added.
- Not addressing onboarding, Home redesign, or Stats curation here — those are later roadmap steps.

## Information architecture

### Entry points (after)

| Trigger | Opens |
|---|---|
| Home **Log** FAB | `LogEntryScreen(mode: fuel, vehicle: selected)` — create |
| Timeline fuel entry tap | `LogEntryScreen(mode: fuel, edit: record)` |
| Timeline service entry tap | `LogEntryScreen(mode: service, edit: record)` |
| Maintenance history list → tap a service row | `LogEntryScreen(mode: service, edit: record)` |
| Maintenance "due"/forecast card → "Log this service" | `LogEntryScreen(mode: service, prefill: serviceType)` |

The intermediate two-option chooser on Home is **removed**; type is chosen via an in-screen
segmented toggle, defaulting to **Fuel** (the most frequent act) unless the entry point implies
Service.

### Screen anatomy — `LogEntryScreen`

```
┌──────────────────────────────────────────────┐
│  ←        Log / Edit            [ Save ]       │
│  [ My Car ▾ ]   ← vehicle context chip         │
│                                                │
│  ┌────────────┬────────────┐                   │
│  │   Fuel ●   │   Service  │  ← segmented toggle│
│  └────────────┴────────────┘   (locked in edit)│
│                                                │
│  Date            [ 21 Jun 2026 ]               │
│  Odometer        [ ________ ] km  (last: 110415)│
│  Cost            [ KWD ____ ]                   │
│  — fuel only —                                 │
│  Fuel type       ( Regular ) ( Premium ) …     │
│  ≈ Volume        7.0 L  @ KWD0.11/L            │
│  — service only —                              │
│  Service type    [ Oil Change ]                │
│  Category        [ Service ]                   │
│  Next due (opt)  [ odo ____ ] [ date ____ ]    │
│                                                │
│  Notes           [ ____________________ ]      │
│  (edit mode)     [ Delete ]                    │
└──────────────────────────────────────────────┘
```

## Fields

### Shared (both modes)

| Field | Default | Validation |
|---|---|---|
| Vehicle | currently selected vehicle | required |
| Date | today | required; not in the future (warn) |
| Odometer | empty, placeholder = `vehicle.currentOdometer`, hint "last: X km" | numeric; **soft-warn** if below last known (allow — could be a correction or second vehicle) |
| Cost | empty | numeric; currency/decimals per the active currency |
| Notes | empty | optional, free text |

### Fuel only

| Field | Default | Notes |
|---|---|---|
| Fuel type | **last fuel type used for this vehicle**, else selected/default | drives price & currency |
| Volume (derived) | computed live | `cost / pricePerLiter` via existing `FillRecord.getFuelAddedLiters`; display-only |

Currency = the fuel type's currency (existing `getCurrencyForFuelTypeId`).

### Service only

| Field | Default | Notes |
|---|---|---|
| Service type | last used for this vehicle, else common presets (Oil Change, Inspection, Tires…) | feeds `scheduleKey` |
| Category | last used / inferred | existing field |
| Next due odometer / date | empty (optional) | sets `hasDueTarget`; powers maintenance due status |

Currency = global `provider.currency` (services have no fuel type — existing behavior). The
screen should label which currency is in play so the mix is never surprising.

## State & wiring

`LogEntryScreen` is parameterised:

```dart
LogEntryScreen({
  required LogMode initialMode,         // fuel | service
  required String vehicleId,
  FillRecord? editFillRecord,           // edit mode (fuel)
  MaintenanceRecord? editMaintenanceRecord, // edit mode (service)
  String? prefillServiceType,           // e.g. from a "due" card
})
```

On **Save**, branch to the **existing** provider methods — no new persistence code:

- Fuel create/edit → `addRecord` / `updateRecord`
- Service create/edit → `addMaintenanceRecord` / `updateMaintenanceRecord`
- Delete (edit mode) → `deleteRecord` / `deleteMaintenanceRecord`

Two small **read-only** provider conveniences make the defaults trivial (optional, additive):

- `String? lastFuelTypeIdForVehicle(String vehicleId)`
- `String? lastServiceTypeForVehicle(String vehicleId)`

Reuse existing input widgets and the currency-input pattern from the current Add screens
([currency_utils.dart](../../lib/utils/currency_utils.dart)) and the date picker.

## Edge cases

- **Mode is locked in edit mode** — a saved fuel entry can't be flipped to a service (would
  orphan its data). The toggle renders read-only.
- **Odometer below last known** → inline warning, not a hard block.
- **No fuel types configured** → offer inline "use default" / quick create rather than bouncing to Settings.
- **First entry for a vehicle** (no prior odometer) → no derived distance/mileage; expected.
- **Deletion** reuses the existing confirmation affordances.

## Rollout (phased, one PR)

1. Build `LogEntryScreen` shell: header, vehicle chip, segmented toggle, shared fields.
2. Port fuel fields + live derived volume from `AddRecordScreen`.
3. Port service fields + next-due from `AddMaintenanceScreen`.
4. Wire smart defaults (last fuel type, last odometer placeholder, last service type).
5. Repoint all entry points (Home FAB, timeline taps, due/forecast cards); **delete**
   `add_record_screen.dart`, `edit_record_screen.dart`, `add_maintenance_screen.dart`.
6. Update docs **in the same commit** (per `CLAUDE.md`): `ARCHITECTURE.md` component diagram +
   navigation map + screen count; OKF — replace the `add-record` / `edit-record` /
   `add-maintenance` screen concepts with a single `log-entry` concept, update
   `navigation-map.md`, regenerate indexes, validate.
7. Tests: widget tests for fuel-create, service-create, and edit/delete in each mode, plus
   smart-default assertions. Provider tests unchanged (methods reused).

## Decisions

Resolved with product (2026-06-21):

1. **Default mode — Fuel.** The screen opens in Fuel mode. Explicit Service entry points (e.g.
   a "service due" / forecast card) still deep-link straight into Service — that is an explicit
   override, not the default.
2. **Type is locked on edit.** A saved entry keeps its type; the segmented toggle is read-only
   in edit mode (changing type would orphan data).
3. **Ship a starter list of service presets.** The Service-type field offers a built-in starter
   list plus free text for anything else, with the last-used type floating to the top (smart
   default). Proposed starter set: *Oil Change, Tire Rotation, Tire Replacement, Brake Service,
   Battery, Air Filter, Inspection, Insurance, Registration, General Service.*

4. **Edit affordances — timeline + contextual lists.** Every edit opens the same unified Log
   screen, reached from the Home activity timeline **and** from contextual listing screens
   (e.g. the Maintenance history screen tapping a service row). More ways in; the Maintenance
   screen stays useful as a place to fix a service inline. All routes converge on
   `LogEntryScreen(edit: …)`.

## Traceability

- Vision: [docs/VISION.md](../VISION.md) → "Now: unify capture."
- Touches screens: `add_record`, `edit_record`, `add_maintenance`, `home`.
- Reuses: `RecordsProvider` CRUD, `CurrencyUtils`, `FillRecord`/`MaintenanceRecord` models — all unchanged.
