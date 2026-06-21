import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:petrol_log/models/fill_record.dart';
import 'package:petrol_log/models/fuel_type.dart';
import 'package:petrol_log/models/maintenance_record.dart';
import 'package:petrol_log/models/vehicle.dart';
import 'package:petrol_log/providers/records_provider.dart';
import 'package:petrol_log/screens/stats_screen.dart';
import 'package:petrol_log/services/storage_service.dart';

class MockStorageService extends Mock implements StorageService {}

class FakeFillRecord extends Fake implements FillRecord {}

class FakeFuelType extends Fake implements FuelType {}

class FakeVehicle extends Fake implements Vehicle {}

class FakeMaintenanceRecord extends Fake implements MaintenanceRecord {}

void main() {
  late MockStorageService storage;

  const regular = FuelType(
    id: 'regular',
    name: 'Regular',
    pricePerLiter: 100,
    currency: '\$',
    active: true,
  );
  const premium = FuelType(
    id: 'premium',
    name: 'Premium',
    pricePerLiter: 200,
    currency: '\$',
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

  setUp(() {
    storage = MockStorageService();

    final vehicle = Vehicle(
      id: 'v1',
      name: 'My Car',
      currentOdometer: 1400,
      createdAt: DateTime(2024, 1, 1),
    );
    final records = [
      FillRecord(
        id: '1',
        date: DateTime(2024, 1, 1),
        odometerKm: 1000,
        cost: 500,
        fuelTypeId: 'regular',
        vehicleId: 'v1',
      ),
      FillRecord(
        id: '2',
        date: DateTime(2024, 1, 15),
        odometerKm: 1200,
        cost: 600,
        fuelTypeId: 'premium',
        vehicleId: 'v1',
      ),
      FillRecord(
        id: '3',
        date: DateTime(2024, 2, 1),
        odometerKm: 1400,
        cost: 700,
        fuelTypeId: 'premium',
        vehicleId: 'v1',
      ),
    ];
    final maintenance = [
      MaintenanceRecord(
        id: 'm1',
        vehicleId: 'v1',
        serviceType: 'Oil Change',
        category: 'Service',
        serviceDate: DateTime(2024, 1, 10),
        odometerKm: 1100,
        cost: 300,
        createdAt: DateTime(2024, 1, 10),
      ),
    ];

    when(() => storage.init()).thenAnswer((_) async {});
    when(() => storage.getThemeMode()).thenReturn('light');
    when(() => storage.getRecords()).thenReturn(records);
    when(() => storage.getFuelTypes()).thenReturn(const [regular, premium]);
    when(() => storage.getSelectedFuelTypeId()).thenReturn('regular');
    when(() => storage.getCurrency()).thenReturn('\$');
    when(() => storage.getVehicles()).thenReturn([vehicle]);
    when(() => storage.getSelectedVehicleId()).thenReturn('v1');
    when(() => storage.getMaintenanceRecords()).thenReturn(maintenance);
    when(() => storage.saveFuelTypes(any())).thenAnswer((_) async {});
    when(() => storage.setSelectedFuelTypeId(any())).thenAnswer((_) async {});
    when(() => storage.saveRecords(any())).thenAnswer((_) async {});
    when(() => storage.saveVehicles(any())).thenAnswer((_) async {});
    when(() => storage.setSelectedVehicle(any())).thenAnswer((_) async {});
    when(() => storage.saveMaintenanceRecords(any())).thenAnswer((_) async {});
  });

  Future<void> pumpStats(WidgetTester tester) async {
    final provider = RecordsProvider(storage);
    await provider.init();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: ChangeNotifierProvider<RecordsProvider>.value(
          value: provider,
          child: const StatsScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('renders the enhanced stat sections without errors',
      (tester) async {
    await pumpStats(tester);

    expect(tester.takeException(), isNull);
    // The overview grid builds eagerly at the top of the list.
    expect(find.text('Total Spent'), findsOneWidget);

    // Each lower panel builds as it scrolls into view; reaching it without an
    // exception confirms the new charts and panels render with real data.
    for (final title in const [
      'Spending',
      'Spend by Fuel Type',
      'Monthly Spend',
      'Fill Cadence',
      'Next Refill Forecast',
      'Cost of Ownership',
    ]) {
      await tester.scrollUntilVisible(
        find.text(title),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(title), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });
}
