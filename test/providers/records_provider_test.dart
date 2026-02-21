import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:petrol_log/models/fill_record.dart';
import 'package:petrol_log/models/fuel_type.dart';
import 'package:petrol_log/models/maintenance_record.dart';
import 'package:petrol_log/models/vehicle.dart';
import 'package:petrol_log/providers/records_provider.dart';
import 'package:petrol_log/services/storage_service.dart';

class MockStorageService extends Mock implements StorageService {}

class FakeFillRecord extends Fake implements FillRecord {}

class FakeFuelType extends Fake implements FuelType {}

class FakeVehicle extends Fake implements Vehicle {}

class FakeMaintenanceRecord extends Fake implements MaintenanceRecord {}

void main() {
  late MockStorageService mockStorageService;
  late RecordsProvider provider;

  const regularFuelType = FuelType(
    id: 'regular',
    name: 'Regular',
    pricePerLiter: 100,
    active: true,
  );
  const premiumFuelType = FuelType(
    id: 'premium_95',
    name: 'Premium 95',
    pricePerLiter: 200,
    active: true,
  );

  setUpAll(() {
    registerFallbackValue(FakeFillRecord());
    registerFallbackValue(<FillRecord>[]);
    registerFallbackValue(FakeFuelType());
    registerFallbackValue(<FuelType>[]);
    registerFallbackValue(FakeVehicle());
    registerFallbackValue(<Vehicle>[]);
    registerFallbackValue(FakeMaintenanceRecord());
    registerFallbackValue(<MaintenanceRecord>[]);
  });

  void stubStorage({
    List<FillRecord>? records,
    List<FuelType>? fuelTypes,
    List<Vehicle>? vehicles,
    List<MaintenanceRecord>? maintenanceRecords,
    String selectedFuelTypeId = 'regular',
    String currency = '₹',
  }) {
    final resolvedRecords = records ?? <FillRecord>[];
    final resolvedFuelTypes = fuelTypes ?? const [regularFuelType];
    final resolvedVehicles = vehicles ?? <Vehicle>[];
    final resolvedMaintenanceRecords =
        maintenanceRecords ?? <MaintenanceRecord>[];

    when(() => mockStorageService.init()).thenAnswer((_) async {});
    when(() => mockStorageService.getThemeMode()).thenReturn('system');
    when(() => mockStorageService.getRecords()).thenReturn(resolvedRecords);
    when(() => mockStorageService.getFuelTypes()).thenReturn(resolvedFuelTypes);
    when(() => mockStorageService.getSelectedFuelTypeId())
        .thenReturn(selectedFuelTypeId);
    when(() => mockStorageService.getCurrency()).thenReturn(currency);

    when(() => mockStorageService.saveFuelTypes(any()))
        .thenAnswer((_) async {});
    when(() => mockStorageService.setSelectedFuelTypeId(any()))
        .thenAnswer((_) async {});
    when(() => mockStorageService.saveRecords(any())).thenAnswer((_) async {});
    when(() => mockStorageService.getVehicles()).thenReturn(resolvedVehicles);
    when(() => mockStorageService.getSelectedVehicleId()).thenReturn(
        resolvedVehicles.isNotEmpty
            ? resolvedVehicles.first.id
            : 'default_vehicle');
    when(() => mockStorageService.saveVehicles(any())).thenAnswer((_) async {});
    when(() => mockStorageService.setSelectedVehicle(any()))
        .thenAnswer((_) async {});
    when(() => mockStorageService.getMaintenanceRecords())
        .thenReturn(resolvedMaintenanceRecords);
    when(() => mockStorageService.saveMaintenanceRecords(any()))
        .thenAnswer((_) async {});

    when(() => mockStorageService.addRecord(any())).thenAnswer((_) async {});
    when(() => mockStorageService.updateRecord(any())).thenAnswer((_) async {});
    when(() => mockStorageService.deleteRecord(any())).thenAnswer((_) async {});
    when(() => mockStorageService.addMaintenanceRecord(any()))
        .thenAnswer((_) async {});
    when(() => mockStorageService.updateMaintenanceRecord(any()))
        .thenAnswer((_) async {});
    when(() => mockStorageService.deleteMaintenanceRecord(any()))
        .thenAnswer((_) async {});

    when(() => mockStorageService.setFuelPrice(any())).thenAnswer((_) async {});
    when(() => mockStorageService.setCurrency(any())).thenAnswer((_) async {});
    when(() => mockStorageService.setThemeMode(any())).thenAnswer((_) async {});
  }

  setUp(() {
    mockStorageService = MockStorageService();
  });

  group('RecordsProvider', () {
    test('recordsByDateAsc returns records sorted oldest to newest', () async {
      final records = [
        FillRecord(
            id: '3', date: DateTime(2024, 3, 1), odometerKm: 3000, cost: 500),
        FillRecord(
            id: '1', date: DateTime(2024, 1, 1), odometerKm: 1000, cost: 500),
        FillRecord(
            id: '2', date: DateTime(2024, 2, 1), odometerKm: 2000, cost: 500),
      ];
      stubStorage(records: records);

      provider = RecordsProvider(mockStorageService);
      await provider.init();

      final sorted = provider.recordsByDateAsc;
      expect(sorted.map((r) => r.id).toList(), ['1', '2', '3']);
    });

    test('getRecordStats uses matching fuel type price', () async {
      final records = [
        FillRecord(
          id: '1',
          date: DateTime(2024, 1, 1),
          odometerKm: 1000,
          cost: 400,
          fuelTypeId: 'regular',
        ),
        FillRecord(
          id: '2',
          date: DateTime(2024, 1, 10),
          odometerKm: 1200,
          cost: 400,
          fuelTypeId: 'premium_95',
        ),
      ];
      stubStorage(
          records: records,
          fuelTypes: const [regularFuelType, premiumFuelType]);

      provider = RecordsProvider(mockStorageService);
      await provider.init();

      final stats = provider.getRecordStats(records[1]);

      expect(stats['pricePerLiter'], 200.0);
      expect(stats['fuelLiters'], 2.0); // 400 / 200
      expect(stats['distanceKm'], 200.0);
      expect(stats['mileage'], 100.0); // 200 / 2
      expect(stats['fuelTypeName'], 'Premium 95');
    });

    test('getOverallStats supports fuel type filtering', () async {
      final records = [
        FillRecord(
          id: '1',
          date: DateTime(2024, 1, 1),
          odometerKm: 1000,
          cost: 500,
          fuelTypeId: 'regular',
        ),
        FillRecord(
          id: '2',
          date: DateTime(2024, 1, 15),
          odometerKm: 1200,
          cost: 600,
          fuelTypeId: 'premium_95',
        ),
        FillRecord(
          id: '3',
          date: DateTime(2024, 2, 1),
          odometerKm: 1400,
          cost: 600,
          fuelTypeId: 'premium_95',
        ),
      ];
      stubStorage(
          records: records,
          fuelTypes: const [regularFuelType, premiumFuelType]);

      provider = RecordsProvider(mockStorageService);
      await provider.init();

      final allStats = provider.getOverallStats();
      expect(allStats['totalRecords'], 3);
      expect(allStats['totalSpent'], 1700.0);

      final premiumStats = provider.getOverallStats(fuelTypeId: 'premium_95');
      expect(premiumStats['totalRecords'], 2);
      expect(premiumStats['totalSpent'], 1200.0);
      expect(premiumStats['totalDistance'], 200.0); // 1400 - 1200
      expect(premiumStats['fuelTypeFilter'], 'premium_95');
    });

    test('getRefillForecast can forecast for a selected fuel type only',
        () async {
      final records = [
        FillRecord(
          id: '1',
          date: DateTime(2024, 1, 1),
          odometerKm: 1000,
          cost: 500,
          fuelTypeId: 'regular',
        ),
        FillRecord(
          id: '2',
          date: DateTime(2024, 1, 5),
          odometerKm: 1100,
          cost: 400,
          fuelTypeId: 'premium_95',
        ),
        FillRecord(
          id: '3',
          date: DateTime(2024, 1, 10),
          odometerKm: 1200,
          cost: 420,
          fuelTypeId: 'premium_95',
        ),
        FillRecord(
          id: '4',
          date: DateTime(2024, 1, 15),
          odometerKm: 1300,
          cost: 410,
          fuelTypeId: 'premium_95',
        ),
      ];
      stubStorage(
          records: records,
          fuelTypes: const [regularFuelType, premiumFuelType]);

      provider = RecordsProvider(mockStorageService);
      await provider.init();

      final premiumForecast = provider.getRefillForecast(
        now: DateTime(2024, 1, 16),
        fuelTypeId: 'premium_95',
      );

      expect(premiumForecast, isNotNull);
      expect(premiumForecast!['forecastDays'], 5);
      expect((premiumForecast['projectedOdometerKm'] as double),
          closeTo(1400.0, 0.01));
      expect(premiumForecast['status'], 'on_track');
    });

    test('deleteFuelType archives used type and keeps it in list', () async {
      final records = [
        FillRecord(
          id: '1',
          date: DateTime(2024, 1, 1),
          odometerKm: 1000,
          cost: 500,
          fuelTypeId: 'premium_95',
        ),
      ];
      stubStorage(
        records: records,
        fuelTypes: const [regularFuelType, premiumFuelType],
        selectedFuelTypeId: 'premium_95',
      );

      provider = RecordsProvider(mockStorageService);
      await provider.init();

      await provider.deleteFuelType('premium_95');

      final premium = provider.getFuelTypeById('premium_95');
      expect(premium, isNotNull);
      expect(premium!.active, isFalse);
      expect(provider.selectedFuelTypeId, isNot('premium_95'));
    });

    test('setSelectedFuelType updates selected type', () async {
      stubStorage(fuelTypes: const [regularFuelType, premiumFuelType]);

      provider = RecordsProvider(mockStorageService);
      await provider.init();

      await provider.setSelectedFuelType('premium_95');

      expect(provider.selectedFuelTypeId, 'premium_95');
      expect(provider.fuelPricePerLiter, 200.0);
    });

    test('setThemeMode delegates and updates local themeMode', () async {
      stubStorage();

      provider = RecordsProvider(mockStorageService);
      await provider.init();

      await provider.setThemeMode(ThemeMode.dark);

      verify(() => mockStorageService.setThemeMode('dark')).called(1);
      expect(provider.themeMode, ThemeMode.dark);
    });

    test('maintenance overview marks overdue schedule using odometer and date',
        () async {
      final vehicle = Vehicle(
        id: 'v1',
        name: 'Civic',
        currentOdometer: 15500,
        createdAt: DateTime(2024, 1, 1),
      );
      final maintenance = MaintenanceRecord(
        id: 'm1',
        vehicleId: 'v1',
        serviceType: 'Oil Change',
        category: 'oil_change',
        serviceDate: DateTime(2024, 1, 1),
        odometerKm: 12000,
        cost: 1500,
        nextDueOdometerKm: 15000,
        nextDueDate: DateTime(2024, 2, 1),
        createdAt: DateTime(2024, 1, 1),
      );
      stubStorage(
        vehicles: [vehicle],
        maintenanceRecords: [maintenance],
      );

      provider = RecordsProvider(mockStorageService);
      await provider.init();

      final overview = provider.getMaintenanceOverview(
        vehicleId: 'v1',
        now: DateTime(2024, 3, 1),
      );

      expect(overview['overdueCount'], 1);
      expect(overview['dueSoonCount'], 0);
      expect(overview['scheduledItems'], 1);
      expect(overview['needsAttention'], isTrue);
    });

    test('addMaintenanceRecord updates vehicle odometer when higher', () async {
      final vehicle = Vehicle(
        id: 'v1',
        name: 'Civic',
        currentOdometer: 10000,
        createdAt: DateTime(2024, 1, 1),
      );
      final maintenance = MaintenanceRecord(
        id: 'm1',
        vehicleId: 'v1',
        serviceType: 'Brake Service',
        category: 'brake',
        serviceDate: DateTime(2024, 1, 10),
        odometerKm: 12000,
        cost: 2000,
        createdAt: DateTime(2024, 1, 10),
      );
      stubStorage(
        vehicles: [vehicle],
        maintenanceRecords: [maintenance],
      );

      provider = RecordsProvider(mockStorageService);
      await provider.init();

      await provider.addMaintenanceRecord(maintenance);

      verify(() => mockStorageService.saveVehicles(any())).called(2);
      expect(provider.getVehicleById('v1')?.currentOdometer, 12000);
    });
  });
}
