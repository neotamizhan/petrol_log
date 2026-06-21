---
type: System
title: Vehicle Logbook
description: Fully offline Flutter app that tracks vehicle maintenance, fuel fills, mileage, and next-refill forecasts, storing all data on-device.
resource: https://github.com/neotamizhan/petrol_log
tags: [flutter, offline, mobile, overview]
timestamp: 2026-06-21T00:00:00Z
---

# Overview

Vehicle Logbook (`petrol_log`) is a **single-user, fully offline** application built
with Flutter (Dart 3.0+). All data is stored locally on the device via
SharedPreferences. There are no backend services, no external APIs, and no network
calls at runtime — no analytics SDKs, no crash reporting.

The product intent that ties these capabilities together is captured in the
[Product Vision](/reference/product-vision.md): effortless, private peace of mind about each
vehicle's cost and care.

Core responsibilities:

- Record service, repair, inspection, and reminder activity per vehicle
- Record and persist fuel fill events per vehicle
- Calculate mileage, cost trends, and efficiency metrics
- Predict the next refill date with a weighted-average forecast
- Track maintenance schedules with due-date alerting
- Support multi-vehicle and multi-fuel-type configurations

# Architecture

A layered Flutter app with a single central state object:

| Layer | Concept | Responsibility |
|---|---|---|
| UI | [Screens](/screens/index.md) | 11 screens + reusable widgets; all user interaction |
| State | [RecordsProvider](/state/records-provider.md) | Single source of truth; reactive getters + analytics |
| Service | [StorageService](/services/storage-service.md), [ImportService](/services/import-service.md) | Persistence and CSV import |
| Domain | [Data Models](/models/index.md) | Immutable value objects with JSON serialization |

The state layer reads/writes through services; services persist JSON to
SharedPreferences under documented [storage keys](/reference/storage-keys.md).

# Data Flow

The UI reads state via `Consumer<RecordsProvider>` and calls provider methods.
The provider mutates in-memory lists, delegates persistence to the service layer,
then calls `notifyListeners()` to rebuild dependent widgets. See
[State & Data Flow](/reference/data-flow.md) for the full reactive cycle and startup
sequence.

# Analytics

Three pure-computation algorithms run over in-memory state with no I/O:
[Overall Stats](/metrics/overall-stats.md), [Refill Forecast](/metrics/refill-forecast.md),
and [Maintenance Due Status](/metrics/maintenance-due-status.md).

# Platform Support

Ships from one Dart codebase to Android, iOS, macOS, and Web, plus a static
GitHub Pages product site. See [Platform & Build Matrix](/reference/platform-build-matrix.md).

# Citations

[1] [ARCHITECTURE.md](https://github.com/neotamizhan/petrol_log/blob/main/docs/ARCHITECTURE.md)
[2] [README.md](https://github.com/neotamizhan/petrol_log/blob/main/README.md)
