import 'package:flutter_test/flutter_test.dart';
import 'package:petrol_log/models/fuel_type.dart';

void main() {
  group('FuelType', () {
    test('normalizeId converts display name to stable id', () {
      expect(FuelType.normalizeId('Premium 95'), 'premium_95');
      expect(FuelType.normalizeId('   Diesel+  '), 'diesel');
    });

    test('fromJson applies defaults for missing values', () {
      final fuelType = FuelType.fromJson({});

      expect(fuelType.id, FuelType.defaultId);
      expect(fuelType.name, FuelType.defaultName);
      expect(fuelType.pricePerLiter, 0);
      expect(fuelType.active, isTrue);
    });

    test('encode/decode roundtrip preserves values', () {
      final fuelTypes = [
        const FuelType(id: 'regular', name: 'Regular', pricePerLiter: 100),
        const FuelType(
            id: 'premium_95', name: 'Premium 95', pricePerLiter: 130),
      ];

      final encoded = FuelType.encodeFuelTypes(fuelTypes);
      final decoded = FuelType.decodeFuelTypes(encoded);

      expect(decoded.length, 2);
      expect(decoded[1].id, 'premium_95');
      expect(decoded[1].name, 'Premium 95');
      expect(decoded[1].pricePerLiter, 130);
    });
  });
}
