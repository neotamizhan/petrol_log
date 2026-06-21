---
okf_version: "0.1"
---

# Vehicle Logbook — Knowledge Bundle

OKF bundle describing **Vehicle Logbook** (`petrol_log`), a fully offline Flutter app for
tracking vehicle maintenance, fuel fills, mileage, and refill forecasts. Start with the
system overview, then drill into the area you need.

* [Vehicle Logbook](system.md) - Fully offline Flutter app that tracks vehicle maintenance, fuel fills, mileage, and next-refill forecasts, storing all data on-device.

# Subdirectories

* [Models](models/) - The four immutable domain entities: FillRecord, FuelType, Vehicle, MaintenanceRecord.
* [State](state/) - RecordsProvider, the central ChangeNotifier and single source of truth.
* [Services](services/) - StorageService (persistence + migrations) and ImportService (CSV import).
* [Screens](screens/) - The 11 UI screens, from splash through the home dashboard to logging, stats, and settings.
* [Metrics](metrics/) - The analytics algorithms: overall stats, refill forecast, maintenance due status.
* [Reference](reference/) - Cross-cutting reference: storage keys, migrations, data flow, navigation, dependencies, build matrix, testing, and the documentation-maintenance convention.
