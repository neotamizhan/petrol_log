import 'package:flutter_test/flutter_test.dart';
import 'package:petrol_log/models/maintenance_record.dart';

void main() {
  group('MaintenanceRecord', () {
    test('toJson and fromJson roundtrip preserves fields', () {
      final original = MaintenanceRecord(
        id: 'm1',
        vehicleId: 'v1',
        serviceType: 'Oil Change',
        category: 'oil_change',
        serviceDate: DateTime(2024, 1, 15, 9, 30),
        odometerKm: 12250,
        cost: 1450.5,
        notes: 'Changed filter too',
        nextDueOdometerKm: 17250,
        nextDueDate: DateTime(2024, 4, 15),
        createdAt: DateTime(2024, 1, 15, 9, 35),
      );

      final restored = MaintenanceRecord.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.vehicleId, original.vehicleId);
      expect(restored.serviceType, original.serviceType);
      expect(restored.category, original.category);
      expect(restored.serviceDate, original.serviceDate);
      expect(restored.odometerKm, original.odometerKm);
      expect(restored.cost, original.cost);
      expect(restored.notes, original.notes);
      expect(restored.nextDueOdometerKm, original.nextDueOdometerKm);
      expect(restored.nextDueDate, original.nextDueDate);
      expect(restored.createdAt, original.createdAt);
    });

    test('copyWith can clear optional due fields', () {
      final original = MaintenanceRecord(
        id: 'm2',
        vehicleId: 'v1',
        serviceType: 'Brake Pads',
        serviceDate: DateTime(2024, 2, 1),
        odometerKm: 13000,
        nextDueOdometerKm: 20000,
        nextDueDate: DateTime(2024, 7, 1),
        createdAt: DateTime(2024, 2, 1),
      );

      final cleared = original.copyWith(
        clearNextDueOdometerKm: true,
        clearNextDueDate: true,
      );

      expect(cleared.nextDueOdometerKm, isNull);
      expect(cleared.nextDueDate, isNull);
      expect(cleared.hasDueTarget, isFalse);
    });

    test('encodeRecords and decodeRecords roundtrip', () {
      final records = [
        MaintenanceRecord(
          id: 'm1',
          vehicleId: 'v1',
          serviceType: 'Oil Change',
          serviceDate: DateTime(2024, 1, 1),
          odometerKm: 10000,
          createdAt: DateTime(2024, 1, 1),
        ),
        MaintenanceRecord(
          id: 'm2',
          vehicleId: 'v1',
          serviceType: 'Tire Rotation',
          serviceDate: DateTime(2024, 2, 1),
          odometerKm: 12000,
          nextDueOdometerKm: 17000,
          createdAt: DateTime(2024, 2, 1),
        ),
      ];

      final encoded = MaintenanceRecord.encodeRecords(records);
      final decoded = MaintenanceRecord.decodeRecords(encoded);

      expect(decoded.length, 2);
      expect(decoded.first.id, 'm1');
      expect(decoded.last.serviceType, 'Tire Rotation');
      expect(decoded.last.nextDueOdometerKm, 17000);
    });
  });
}
