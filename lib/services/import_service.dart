import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../models/fill_record.dart';
import '../models/fuel_type.dart';

class ImportService {
  /// Import records from a CSV file
  /// Expected columns: Date, Odometer (km), Cost, Notes (optional), Fuel Type (optional)
  /// Date formats supported: yyyy-MM-dd, dd/MM/yyyy, MM/dd/yyyy, dd-MM-yyyy
  Future<ImportResult> importFromCsv() async {
    try {
      // Pick CSV file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return ImportResult(
          success: false,
          message: 'No file selected',
          records: [],
        );
      }

      final file = result.files.first;
      if (file.bytes == null) {
        return ImportResult(
          success: false,
          message: 'Could not read file',
          records: [],
        );
      }

      // Parse CSV
      final csvString = utf8.decode(file.bytes!);
      final List<List<dynamic>> rows =
          const CsvToListConverter().convert(csvString);

      if (rows.isEmpty) {
        return ImportResult(
          success: false,
          message: 'CSV file is empty',
          records: [],
        );
      }

      // Skip header row and parse data
      final records = <FillRecord>[];
      final errors = <String>[];

      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty ||
            (row.length == 1 && row[0].toString().trim().isEmpty)) {
          continue; // Skip empty rows
        }

        try {
          final record = _parseRow(row, i);
          if (record != null) {
            records.add(record);
          }
        } catch (e) {
          errors.add('Row ${i + 1}: $e');
        }
      }

      if (records.isEmpty && errors.isNotEmpty) {
        return ImportResult(
          success: false,
          message: 'Failed to import: ${errors.join(", ")}',
          records: [],
        );
      }

      return ImportResult(
        success: true,
        message:
            'Imported ${records.length} records${errors.isNotEmpty ? " (${errors.length} rows skipped)" : ""}',
        records: records,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        message: 'Import failed: $e',
        records: [],
      );
    }
  }

  FillRecord? _parseRow(List<dynamic> row, int rowIndex) {
    if (row.length < 3) {
      throw Exception(
          'Not enough columns (need at least Date, Odometer, Cost)');
    }

    // Parse date
    final dateStr = row[0].toString().trim();
    final date = _parseDate(dateStr);
    if (date == null) {
      throw Exception('Invalid date format: $dateStr');
    }

    // Parse odometer
    final odometerStr = row[1].toString().replaceAll(',', '').trim();
    final odometer = double.tryParse(odometerStr);
    if (odometer == null) {
      throw Exception('Invalid odometer: ${row[1]}');
    }

    // Parse cost
    final costStr =
        row[2].toString().replaceAll(',', '').replaceAll('₹', '').trim();
    final cost = double.tryParse(costStr);
    if (cost == null) {
      throw Exception('Invalid cost: ${row[2]}');
    }

    // Parse notes (optional)
    final notes = row.length > 3 ? row[3].toString().trim() : '';
    final rawFuelType = row.length > 4 ? row[4].toString().trim() : '';
    final fuelTypeId = rawFuelType.isEmpty
        ? FuelType.defaultId
        : FuelType.normalizeId(rawFuelType);

    return FillRecord(
      id: '${date.millisecondsSinceEpoch}_$rowIndex',
      date: date,
      odometerKm: odometer,
      cost: cost,
      notes: notes,
      fuelTypeId: fuelTypeId,
    );
  }

  DateTime? _parseDate(String dateStr) {
    // Try various date formats
    final formats = [
      DateFormat('yyyy-MM-dd'),
      DateFormat('dd/MM/yyyy'),
      DateFormat('MM/dd/yyyy'),
      DateFormat('dd-MM-yyyy'),
      DateFormat('d/M/yyyy'),
      DateFormat('M/d/yyyy'),
      DateFormat('yyyy/MM/dd'),
    ];

    for (final format in formats) {
      try {
        return format.parse(dateStr);
      } catch (_) {
        // Try next format
      }
    }

    // Try parsing as ISO date
    return DateTime.tryParse(dateStr);
  }
}

class ImportResult {
  final bool success;
  final String message;
  final List<FillRecord> records;

  ImportResult({
    required this.success,
    required this.message,
    required this.records,
  });
}
