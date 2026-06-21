---
type: Service
title: ImportService
description: Presents a file picker and parses CSV files into fuel fill records, tolerating multiple date formats.
resource: https://github.com/neotamizhan/petrol_log/blob/main/lib/services/import_service.dart
tags: [service, import, csv]
timestamp: 2026-06-21T00:00:00Z
---

# Responsibilities

`ImportService` enables bulk historical import of fuel data:

1. Presents a cross-platform file picker dialog (`file_picker`).
2. Parses the selected CSV (`csv` package) with **flexible date formats**.
3. Maps rows to [FillRecord](/models/fill-record.md) domain objects.
4. Returns an `ImportResult` carrying the parsed records plus a status message.

Imported records are handed to the [RecordsProvider](/state/records-provider.md), which
persists them via the [StorageService](/services/storage-service.md). Invoked from the
[Settings screen](/screens/settings-screen.md).

# Examples

Date-format variants and edge cases are covered in the test suite.

# Citations

[1] [import_service.dart](https://github.com/neotamizhan/petrol_log/blob/main/lib/services/import_service.dart)
[2] [import_service_test.dart](https://github.com/neotamizhan/petrol_log/blob/main/test/services/import_service_test.dart)
