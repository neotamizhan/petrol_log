import 'package:flutter_test/flutter_test.dart';
import 'package:petrol_log/models/fill_record.dart';

void main() {
  group('FillRecord', () {
    group('getDistanceSinceLastFill', () {
      test('returns 0 when previousRecord is null', () {
        final record = FillRecord(
          id: '1',
          date: DateTime(2024, 1, 15),
          odometerKm: 1000,
          cost: 500,
        );

        expect(record.getDistanceSinceLastFill(null), 0);
      });

      test('calculates distance correctly with previous record', () {
        final previousRecord = FillRecord(
          id: '1',
          date: DateTime(2024, 1, 1),
          odometerKm: 800,
          cost: 400,
        );
        final record = FillRecord(
          id: '2',
          date: DateTime(2024, 1, 15),
          odometerKm: 1000,
          cost: 500,
        );

        expect(record.getDistanceSinceLastFill(previousRecord), 200);
      });
    });

    group('getFuelAddedLiters', () {
      test('calculates fuel correctly with valid price', () {
        final record = FillRecord(
          id: '1',
          date: DateTime(2024, 1, 15),
          odometerKm: 1000,
          cost: 500,
        );

        // 500 / 100 = 5 liters
        expect(record.getFuelAddedLiters(100), 5);
      });

      test('returns 0 when price is zero', () {
        final record = FillRecord(
          id: '1',
          date: DateTime(2024, 1, 15),
          odometerKm: 1000,
          cost: 500,
        );

        expect(record.getFuelAddedLiters(0), 0);
      });

      test('returns 0 when price is negative', () {
        final record = FillRecord(
          id: '1',
          date: DateTime(2024, 1, 15),
          odometerKm: 1000,
          cost: 500,
        );

        expect(record.getFuelAddedLiters(-10), 0);
      });
    });

    group('getMileage', () {
      test('calculates mileage correctly', () {
        final previousRecord = FillRecord(
          id: '1',
          date: DateTime(2024, 1, 1),
          odometerKm: 800,
          cost: 400,
        );
        final record = FillRecord(
          id: '2',
          date: DateTime(2024, 1, 15),
          odometerKm: 1000,
          cost: 500,
        );

        // Distance: 200 km, Fuel: 500/100 = 5 liters
        // Mileage: 200/5 = 40 km/l
        expect(record.getMileage(previousRecord, 100), 40);
      });

      test('returns 0 when previous record is null', () {
        final record = FillRecord(
          id: '1',
          date: DateTime(2024, 1, 15),
          odometerKm: 1000,
          cost: 500,
        );

        expect(record.getMileage(null, 100), 0);
      });

      test('returns 0 when fuel added is zero', () {
        final previousRecord = FillRecord(
          id: '1',
          date: DateTime(2024, 1, 1),
          odometerKm: 800,
          cost: 400,
        );
        final record = FillRecord(
          id: '2',
          date: DateTime(2024, 1, 15),
          odometerKm: 1000,
          cost: 500,
        );

        expect(record.getMileage(previousRecord, 0), 0);
      });
    });

    group('getDaysSinceLastFill', () {
      test('returns 0 when previousRecord is null', () {
        final record = FillRecord(
          id: '1',
          date: DateTime(2024, 1, 15),
          odometerKm: 1000,
          cost: 500,
        );

        expect(record.getDaysSinceLastFill(null), 0);
      });

      test('calculates days correctly', () {
        final previousRecord = FillRecord(
          id: '1',
          date: DateTime(2024, 1, 1),
          odometerKm: 800,
          cost: 400,
        );
        final record = FillRecord(
          id: '2',
          date: DateTime(2024, 1, 15),
          odometerKm: 1000,
          cost: 500,
        );

        expect(record.getDaysSinceLastFill(previousRecord), 14);
      });
    });

    group('JSON serialization', () {
      test('toJson creates correct map', () {
        final date = DateTime(2024, 1, 15, 10, 30);
        final record = FillRecord(
          id: 'test-id',
          date: date,
          odometerKm: 1000.5,
          cost: 500.25,
          notes: 'Test note',
        );

        final json = record.toJson();

        expect(json['id'], 'test-id');
        expect(json['date'], date.toIso8601String());
        expect(json['odometerKm'], 1000.5);
        expect(json['cost'], 500.25);
        expect(json['notes'], 'Test note');
        expect(json['fuelTypeId'], 'regular');
      });

      test('fromJson creates correct record', () {
        final json = {
          'id': 'test-id',
          'date': '2024-01-15T10:30:00.000',
          'odometerKm': 1000.5,
          'cost': 500.25,
          'notes': 'Test note',
          'fuelTypeId': 'premium_95',
        };

        final record = FillRecord.fromJson(json);

        expect(record.id, 'test-id');
        expect(record.date, DateTime(2024, 1, 15, 10, 30));
        expect(record.odometerKm, 1000.5);
        expect(record.cost, 500.25);
        expect(record.notes, 'Test note');
        expect(record.fuelTypeId, 'premium_95');
      });

      test('fromJson handles missing notes', () {
        final json = {
          'id': 'test-id',
          'date': '2024-01-15T10:30:00.000',
          'odometerKm': 1000,
          'cost': 500,
        };

        final record = FillRecord.fromJson(json);

        expect(record.notes, '');
        expect(record.fuelTypeId, 'regular');
      });

      test('roundtrip serialization preserves data', () {
        final original = FillRecord(
          id: 'test-id',
          date: DateTime(2024, 1, 15, 10, 30),
          odometerKm: 1000.5,
          cost: 500.25,
          notes: 'Test note',
          fuelTypeId: 'premium_95',
        );

        final json = original.toJson();
        final restored = FillRecord.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.date, original.date);
        expect(restored.odometerKm, original.odometerKm);
        expect(restored.cost, original.cost);
        expect(restored.notes, original.notes);
        expect(restored.fuelTypeId, original.fuelTypeId);
      });
    });

    group('List encoding/decoding', () {
      test('encodeRecords and decodeRecords roundtrip', () {
        final records = [
          FillRecord(
            id: '1',
            date: DateTime(2024, 1, 1),
            odometerKm: 800,
            cost: 400,
          ),
          FillRecord(
            id: '2',
            date: DateTime(2024, 1, 15),
            odometerKm: 1000,
            cost: 500,
            notes: 'Full tank',
            fuelTypeId: 'premium_95',
          ),
        ];

        final encoded = FillRecord.encodeRecords(records);
        final decoded = FillRecord.decodeRecords(encoded);

        expect(decoded.length, 2);
        expect(decoded[0].id, '1');
        expect(decoded[1].id, '2');
        expect(decoded[1].notes, 'Full tank');
        expect(decoded[1].fuelTypeId, 'premium_95');
      });

      test('decodeRecords handles empty string', () {
        final decoded = FillRecord.decodeRecords('');
        expect(decoded, isEmpty);
      });
    });
  });
}
