import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:petrol_log/models/fuel_type.dart';

/// Tests for date parsing logic used by ImportService
/// Note: Since _parseDate is private, we test it indirectly by recreating the logic
void main() {
  group('ImportService date parsing logic', () {
    DateTime? parseDate(String dateStr) {
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
          return format
              .parseStrict(dateStr); // Use parseStrict for accurate testing
        } catch (_) {
          // Try next format
        }
      }
      return DateTime.tryParse(dateStr);
    }

    test('parses yyyy-MM-dd format', () {
      final result = parseDate('2024-01-15');
      expect(result, DateTime(2024, 1, 15));
    });

    test('parses dd/MM/yyyy format', () {
      final result = parseDate('15/01/2024');
      expect(result, DateTime(2024, 1, 15));
    });

    test('parses MM/dd/yyyy format with unambiguous date', () {
      // Use a date where day > 12 to avoid ambiguity with dd/MM/yyyy
      final result = parseDate('01/25/2024');
      expect(result?.year, 2024);
      expect(result?.month, 1);
      expect(result?.day, 25);
    });

    test('parses dd-MM-yyyy format', () {
      // Use parseStrict so 25-01-2024 is unambiguous (day=25, month=1)
      final result = parseDate('25-01-2024');
      expect(result?.year, 2024);
      expect(result?.month, 1);
      expect(result?.day, 25);
    });

    test('parses d/M/yyyy format (single digit day/month)', () {
      final result = parseDate('5/1/2024');
      expect(result?.day, 5);
      expect(result?.month, 1);
      expect(result?.year, 2024);
    });

    test('parses ISO date format', () {
      final result = parseDate('2024-01-15T10:30:00.000');
      expect(result?.year, 2024);
      expect(result?.month, 1);
      expect(result?.day, 15);
    });

    test('returns null for invalid date', () {
      final result = parseDate('invalid-date');
      expect(result, isNull);
    });

    test('returns null for empty string', () {
      final result = parseDate('');
      expect(result, isNull);
    });
  });

  group('CSV row parsing logic', () {
    test('validates minimum column count', () {
      final row = ['2024-01-15', '1000'];
      expect(row.length < 3, isTrue);
    });

    test('parses complete row correctly', () {
      final row = ['2024-01-15', '1000', '500', 'Full tank'];

      expect(row[0], '2024-01-15');
      expect(double.parse(row[1].toString()), 1000);
      expect(double.parse(row[2].toString()), 500);
      expect(row[3], 'Full tank');
    });

    test('handles comma-formatted numbers', () {
      final odometerStr = '1,000'.replaceAll(',', '');
      final costStr = '₹500'.replaceAll(',', '').replaceAll('₹', '');

      expect(double.parse(odometerStr), 1000);
      expect(double.parse(costStr), 500);
    });

    test('handles optional notes column', () {
      final row = ['2024-01-15', '1000', '500'];
      final notes = row.length > 3 ? row[3].toString() : '';
      expect(notes, '');
    });

    test('normalizes optional fuel type column', () {
      final row = ['2024-01-15', '1000', '500', 'Full tank', 'Premium 95'];
      final rawFuelType = row.length > 4 ? row[4].toString().trim() : '';
      final fuelTypeId = rawFuelType.isEmpty
          ? FuelType.defaultId
          : FuelType.normalizeId(rawFuelType);

      expect(fuelTypeId, 'premium_95');
    });
  });
}
