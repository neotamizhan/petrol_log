---
type: Reference
title: Testing Strategy
description: The unit-test coverage map mirroring the lib/ structure, and the commands to run tests and analysis.
tags: [reference, testing]
timestamp: 2026-06-21T00:00:00Z
---

# Coverage Map

Tests under `test/` mirror the `lib/` structure.

| Layer | Test File | Key Scenarios |
|---|---|---|
| [FillRecord](/models/fill-record.md) | `test/models/fill_record_test.dart` | Distance, mileage, volume, days calculations |
| [FuelType](/models/fuel-type.md) | `test/models/fuel_type_test.dart` | ID normalization, serialization, per-type currency round-trip |
| [Vehicle](/models/vehicle.md) | `test/models/vehicle_test.dart` | Equality, serialization |
| [MaintenanceRecord](/models/maintenance-record.md) | `test/models/maintenance_record_test.dart` | Due status, scheduleKey |
| [RecordsProvider](/state/records-provider.md) | `test/providers/records_provider_test.dart` | Analytics, filtering, CRUD, currency resolution |
| [ImportService](/services/import-service.md) | `test/services/import_service_test.dart` | Date format variants, edge cases |
| CurrencyUtils | `test/utils/currency_utils_test.dart` | Decimal places, formatting |

# Commands

```bash
flutter test
flutter test --coverage
flutter analyze
dart format lib test
```

# Citations

[1] [ARCHITECTURE.md §12](https://github.com/neotamizhan/petrol_log/blob/main/docs/ARCHITECTURE.md)
