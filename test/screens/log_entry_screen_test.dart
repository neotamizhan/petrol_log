import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:petrol_log/models/fill_record.dart';
import 'package:petrol_log/models/fuel_type.dart';
import 'package:petrol_log/models/maintenance_record.dart';
import 'package:petrol_log/models/vehicle.dart';
import 'package:petrol_log/providers/records_provider.dart';
import 'package:petrol_log/screens/log_entry_screen.dart';
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

  final vehicle = Vehicle(
    id: 'v1',
    name: 'My Car',
    currentOdometer: 1200,
    createdAt: DateTime(2024, 1, 1),
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
    when(() => storage.init()).thenAnswer((_) async {});
    when(() => storage.getThemeMode()).thenReturn('light');
    when(() => storage.getRecords()).thenReturn(<FillRecord>[]);
    when(() => storage.getFuelTypes()).thenReturn(const [regular]);
    when(() => storage.getSelectedFuelTypeId()).thenReturn('regular');
    when(() => storage.getCurrency()).thenReturn('\$');
    when(() => storage.getVehicles()).thenReturn([vehicle]);
    when(() => storage.getSelectedVehicleId()).thenReturn('v1');
    when(() => storage.getMaintenanceRecords())
        .thenReturn(<MaintenanceRecord>[]);
    when(() => storage.saveFuelTypes(any())).thenAnswer((_) async {});
    when(() => storage.setSelectedFuelTypeId(any())).thenAnswer((_) async {});
    when(() => storage.saveRecords(any())).thenAnswer((_) async {});
    when(() => storage.saveVehicles(any())).thenAnswer((_) async {});
    when(() => storage.setSelectedVehicle(any())).thenAnswer((_) async {});
    when(() => storage.saveMaintenanceRecords(any())).thenAnswer((_) async {});
    when(() => storage.addRecord(any())).thenAnswer((_) async {});
    when(() => storage.updateRecord(any())).thenAnswer((_) async {});
    when(() => storage.deleteRecord(any())).thenAnswer((_) async {});
    when(() => storage.addMaintenanceRecord(any())).thenAnswer((_) async {});
    when(() => storage.updateMaintenanceRecord(any())).thenAnswer((_) async {});
    when(() => storage.deleteMaintenanceRecord(any())).thenAnswer((_) async {});
  });

  // Launch the screen via a pushed route so save (which pops) returns to a
  // parent. The provider sits above MaterialApp so pushed routes can read it.
  Future<void> openScreen(WidgetTester tester, Widget screen) async {
    final provider = RecordsProvider(storage);
    await provider.init();
    await tester.pumpWidget(
      ChangeNotifierProvider<RecordsProvider>.value(
        value: provider,
        child: MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => screen),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  // Fields live in a lazy ListView; scroll a keyed field into view, then type.
  Future<void> enterByKey(WidgetTester tester, String key, String text) async {
    await tester.scrollUntilVisible(
      find.byKey(Key(key)),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byKey(Key(key)), text);
  }

  testWidgets('fuel mode saves a fill record', (tester) async {
    await openScreen(tester, const LogEntryScreen(initialMode: LogMode.fuel));

    await enterByKey(tester, 'log-odometer', '1500');
    await enterByKey(tester, 'log-cost', '30');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    verify(() => storage.addRecord(any())).called(1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('service mode saves a maintenance record', (tester) async {
    await openScreen(
        tester, const LogEntryScreen(initialMode: LogMode.service));

    await enterByKey(tester, 'log-service-type', 'Oil Change');
    await enterByKey(tester, 'log-odometer', '1500');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    verify(() => storage.addMaintenanceRecord(any())).called(1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('service mode offers starter presets', (tester) async {
    await openScreen(
        tester, const LogEntryScreen(initialMode: LogMode.service));

    expect(find.widgetWithText(ActionChip, 'Oil Change'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, 'Brake Service'), findsOneWidget);
  });

  testWidgets('edit mode locks the type and pre-fills the record',
      (tester) async {
    final record = FillRecord(
      id: 'f1',
      date: DateTime(2024, 1, 10),
      odometerKm: 1234,
      cost: 40,
      fuelTypeId: 'regular',
      vehicleId: 'v1',
    );
    await openScreen(tester, LogEntryScreen(editFillRecord: record));

    // Type toggle is hidden (locked) in edit mode; delete is available.
    expect(find.byType(SegmentedButton<LogMode>), findsNothing);
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    // Odometer pre-filled from the record.
    expect(find.text('1234'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Save Changes'));
    await tester.pumpAndSettle();
    verify(() => storage.updateRecord(any())).called(1);
  });
}
