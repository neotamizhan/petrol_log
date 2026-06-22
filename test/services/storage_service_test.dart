import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:petrol_log/models/fill_record.dart';
import 'package:petrol_log/models/fuel_type.dart';
import 'package:petrol_log/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StorageService per-fill price migration', () {
    test('backfills legacy fills with their fuel type price', () async {
      const fuelType = FuelType(
        id: 'regular',
        name: 'Regular',
        pricePerLiter: 120,
        currency: '\$',
        active: true,
      );
      // A legacy fill with no pricePerLiter recorded.
      final legacy = FillRecord(
        id: '1',
        date: DateTime(2024, 1, 1),
        odometerKm: 1000,
        cost: 600,
        fuelTypeId: 'regular',
        vehicleId: 'v1',
      );

      SharedPreferences.setMockInitialValues({
        'flutter.fuel_types': FuelType.encodeFuelTypes([fuelType]),
        'flutter.fill_records': FillRecord.encodeRecords([legacy]),
        'flutter.selected_fuel_type_id': 'regular',
        'flutter.currency_symbol': '\$',
      });

      final storage = StorageService();
      await storage.init();

      final records = storage.getRecords();
      expect(records, hasLength(1));
      // Frozen at the fuel type's price at migration time.
      expect(records.first.pricePerLiter, 120);
    });

    test('leaves an already-priced fill untouched', () async {
      const fuelType = FuelType(
        id: 'regular',
        name: 'Regular',
        pricePerLiter: 120,
        currency: '\$',
        active: true,
      );
      final priced = FillRecord(
        id: '1',
        date: DateTime(2024, 1, 1),
        odometerKm: 1000,
        cost: 600,
        fuelTypeId: 'regular',
        vehicleId: 'v1',
        pricePerLiter: 90,
      );

      SharedPreferences.setMockInitialValues({
        'flutter.fuel_types': FuelType.encodeFuelTypes([fuelType]),
        'flutter.fill_records': FillRecord.encodeRecords([priced]),
        'flutter.selected_fuel_type_id': 'regular',
        'flutter.currency_symbol': '\$',
      });

      final storage = StorageService();
      await storage.init();

      expect(storage.getRecords().first.pricePerLiter, 90);
    });
  });
}
