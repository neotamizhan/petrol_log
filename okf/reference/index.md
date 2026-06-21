# Concepts

* [State & Data Flow](data-flow.md) - The reactive update cycle and app startup sequence connecting screens, the provider, services, and SharedPreferences.
* [Dependency Inventory](dependencies.md) - The Dart/Flutter packages the app depends on, and why — no network, analytics, or crash-reporting SDKs.
* [Documentation Maintenance Convention](documentation-maintenance.md) - The project rule that docs/ARCHITECTURE.md and this OKF bundle are kept synchronized and updated in the same commit as any significant change.
* [Data Migrations](migrations.md) - The on-load migrations that convert legacy SharedPreferences data into the current model shape.
* [Screen Navigation Map](navigation-map.md) - How the app's screens connect, from splash through the home dashboard to the logging, stats, and settings flows.
* [Platform & Build Matrix](platform-build-matrix.md) - Supported target platforms and their release build commands, plus the static product website.
* [Product Vision](product-vision.md) - The north star for Vehicle Logbook — effortless, private peace of mind about each vehicle's cost and care — and the principles and roadmap that flow from it.
* [SharedPreferences Storage Keys](storage-keys.md) - The complete set of SharedPreferences keys used for on-device persistence, with their types and meaning.
* [Testing Strategy](testing-strategy.md) - The unit-test coverage map mirroring the lib/ structure, and the commands to run tests and analysis.
