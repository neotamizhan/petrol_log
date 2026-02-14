import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:petrol_log/models/fill_record.dart';
import 'package:petrol_log/providers/records_provider.dart';
import 'package:petrol_log/services/storage_service.dart';

class MockStorageService extends Mock implements StorageService {}

void main() {
  late MockStorageService mockStorageService;
  late RecordsProvider provider;

  setUp(() {
    mockStorageService = MockStorageService();
    when(() => mockStorageService.init()).thenAnswer((_) async {});
    when(() => mockStorageService.getThemeMode()).thenReturn('system');
  });

  group('RecordsProvider', () {
    group('recordsByDateAsc', () {
      test('returns records sorted by date ascending', () async {
        final records = [
          FillRecord(
              id: '3', date: DateTime(2024, 3, 1), odometerKm: 3000, cost: 500),
          FillRecord(
              id: '1', date: DateTime(2024, 1, 1), odometerKm: 1000, cost: 500),
          FillRecord(
              id: '2', date: DateTime(2024, 2, 1), odometerKm: 2000, cost: 500),
        ];

        when(() => mockStorageService.getRecords()).thenReturn(records);
        when(() => mockStorageService.getFuelPrice()).thenReturn(100.0);
        when(() => mockStorageService.getCurrency()).thenReturn('₹');

        provider = RecordsProvider(mockStorageService);
        await provider.init();

        final sorted = provider.recordsByDateAsc;

        expect(sorted[0].id, '1');
        expect(sorted[1].id, '2');
        expect(sorted[2].id, '3');
      });
    });

    group('getPreviousRecord', () {
      test('returns null for the first record', () async {
        final records = [
          FillRecord(
              id: '1', date: DateTime(2024, 1, 1), odometerKm: 1000, cost: 500),
          FillRecord(
              id: '2', date: DateTime(2024, 2, 1), odometerKm: 2000, cost: 500),
        ];

        when(() => mockStorageService.getRecords()).thenReturn(records);
        when(() => mockStorageService.getFuelPrice()).thenReturn(100.0);
        when(() => mockStorageService.getCurrency()).thenReturn('₹');

        provider = RecordsProvider(mockStorageService);
        await provider.init();

        final previousRecord = provider.getPreviousRecord(records[0]);
        expect(previousRecord, isNull);
      });

      test('returns correct previous record', () async {
        final records = [
          FillRecord(
              id: '1', date: DateTime(2024, 1, 1), odometerKm: 1000, cost: 500),
          FillRecord(
              id: '2', date: DateTime(2024, 2, 1), odometerKm: 2000, cost: 500),
          FillRecord(
              id: '3', date: DateTime(2024, 3, 1), odometerKm: 3000, cost: 500),
        ];

        when(() => mockStorageService.getRecords()).thenReturn(records);
        when(() => mockStorageService.getFuelPrice()).thenReturn(100.0);
        when(() => mockStorageService.getCurrency()).thenReturn('₹');

        provider = RecordsProvider(mockStorageService);
        await provider.init();

        final previousRecord = provider.getPreviousRecord(records[2]);
        expect(previousRecord?.id, '2');
      });
    });

    group('getRecordStats', () {
      test('calculates correct stats for a record with previous record',
          () async {
        final records = [
          FillRecord(
              id: '1', date: DateTime(2024, 1, 1), odometerKm: 1000, cost: 400),
          FillRecord(
              id: '2',
              date: DateTime(2024, 1, 15),
              odometerKm: 1200,
              cost: 500),
        ];

        when(() => mockStorageService.getRecords()).thenReturn(records);
        when(() => mockStorageService.getFuelPrice()).thenReturn(100.0);
        when(() => mockStorageService.getCurrency()).thenReturn('₹');

        provider = RecordsProvider(mockStorageService);
        await provider.init();

        final stats = provider.getRecordStats(records[1]);

        // Distance: 1200 - 1000 = 200 km
        expect(stats['distanceKm'], 200);
        // Fuel: 500 / 100 = 5 liters
        expect(stats['fuelLiters'], 5);
        // Mileage: 200 / 5 = 40 km/l
        expect(stats['mileage'], 40);
        // Days: Jan 1 to Jan 15 = 14 days
        expect(stats['daysSinceLastFill'], 14);
        expect(stats['isFirstRecord'], false);
      });

      test('returns isFirstRecord true for first record', () async {
        final records = [
          FillRecord(
              id: '1', date: DateTime(2024, 1, 1), odometerKm: 1000, cost: 500),
        ];

        when(() => mockStorageService.getRecords()).thenReturn(records);
        when(() => mockStorageService.getFuelPrice()).thenReturn(100.0);
        when(() => mockStorageService.getCurrency()).thenReturn('₹');

        provider = RecordsProvider(mockStorageService);
        await provider.init();

        final stats = provider.getRecordStats(records[0]);

        expect(stats['isFirstRecord'], true);
        expect(stats['distanceKm'], 0);
      });
    });

    group('getOverallStats', () {
      test('returns empty stats when no records', () async {
        when(() => mockStorageService.getRecords()).thenReturn([]);
        when(() => mockStorageService.getFuelPrice()).thenReturn(100.0);
        when(() => mockStorageService.getCurrency()).thenReturn('₹');

        provider = RecordsProvider(mockStorageService);
        await provider.init();

        final stats = provider.getOverallStats();

        expect(stats['totalRecords'], 0);
        expect(stats['totalSpent'], 0.0);
        expect(stats['averageMileage'], 0.0);
      });

      test('calculates correct overall stats', () async {
        final records = [
          FillRecord(
              id: '1', date: DateTime(2024, 1, 1), odometerKm: 1000, cost: 400),
          FillRecord(
              id: '2',
              date: DateTime(2024, 1, 15),
              odometerKm: 1200,
              cost: 500),
          FillRecord(
              id: '3', date: DateTime(2024, 2, 1), odometerKm: 1400, cost: 600),
        ];

        when(() => mockStorageService.getRecords()).thenReturn(records);
        when(() => mockStorageService.getFuelPrice()).thenReturn(100.0);
        when(() => mockStorageService.getCurrency()).thenReturn('₹');

        provider = RecordsProvider(mockStorageService);
        await provider.init();

        final stats = provider.getOverallStats();

        expect(stats['totalRecords'], 3);
        // Total spent: 400 + 500 + 600 = 1500
        expect(stats['totalSpent'], 1500);
        // Total fuel: 400/100 + 500/100 + 600/100 = 4 + 5 + 6 = 15 liters
        expect(stats['totalFuelLiters'], 15);
        // Total distance: (1200-1000) + (1400-1200) = 200 + 200 = 400 km
        expect(stats['totalDistance'], 400);
        // Average fill cost: 1500 / 3 = 500
        expect(stats['averageFillCost'], 500);
      });

      test('calculates monthly spending correctly', () async {
        final records = [
          FillRecord(
              id: '1', date: DateTime(2024, 1, 1), odometerKm: 1000, cost: 400),
          FillRecord(
              id: '2',
              date: DateTime(2024, 1, 15),
              odometerKm: 1200,
              cost: 500),
          FillRecord(
              id: '3', date: DateTime(2024, 2, 1), odometerKm: 1400, cost: 600),
        ];

        when(() => mockStorageService.getRecords()).thenReturn(records);
        when(() => mockStorageService.getFuelPrice()).thenReturn(100.0);
        when(() => mockStorageService.getCurrency()).thenReturn('₹');

        provider = RecordsProvider(mockStorageService);
        await provider.init();

        final stats = provider.getOverallStats();
        final monthlySpending = stats['monthlySpending'] as Map<String, double>;

        expect(monthlySpending['2024-01'], 900); // 400 + 500
        expect(monthlySpending['2024-02'], 600);
      });
    });

    group('getRefillForecast', () {
      test('returns null when there are not enough records', () async {
        final records = [
          FillRecord(
              id: '1', date: DateTime(2024, 1, 1), odometerKm: 1000, cost: 500),
        ];

        when(() => mockStorageService.getRecords()).thenReturn(records);
        when(() => mockStorageService.getFuelPrice()).thenReturn(100.0);
        when(() => mockStorageService.getCurrency()).thenReturn('₹');

        provider = RecordsProvider(mockStorageService);
        await provider.init();

        final forecast = provider.getRefillForecast(now: DateTime(2024, 1, 2));
        expect(forecast, isNull);
      });

      test('predicts refill timing, cost and odometer from recent intervals',
          () async {
        final records = [
          FillRecord(
              id: '1', date: DateTime(2024, 1, 1), odometerKm: 1000, cost: 400),
          FillRecord(
              id: '2', date: DateTime(2024, 1, 8), odometerKm: 1200, cost: 420),
          FillRecord(
              id: '3',
              date: DateTime(2024, 1, 15),
              odometerKm: 1400,
              cost: 410),
          FillRecord(
              id: '4',
              date: DateTime(2024, 1, 22),
              odometerKm: 1600,
              cost: 430),
        ];

        when(() => mockStorageService.getRecords()).thenReturn(records);
        when(() => mockStorageService.getFuelPrice()).thenReturn(100.0);
        when(() => mockStorageService.getCurrency()).thenReturn('₹');

        provider = RecordsProvider(mockStorageService);
        await provider.init();

        final forecast = provider.getRefillForecast(now: DateTime(2024, 1, 24));
        expect(forecast, isNotNull);

        final result = forecast!;
        expect(result['forecastDays'], 7);
        expect(result['daysUntilRefill'], 5);
        expect(result['status'], 'on_track');
        expect((result['projectedOdometerKm'] as double), closeTo(1800, 0.01));
        expect((result['expectedCost'] as double), closeTo(420, 12));
        expect((result['confidence'] as double), greaterThan(0.7));
      });

      test('marks forecast as overdue when predicted date has passed',
          () async {
        final records = [
          FillRecord(
              id: '1', date: DateTime(2024, 1, 1), odometerKm: 1000, cost: 400),
          FillRecord(
              id: '2', date: DateTime(2024, 1, 8), odometerKm: 1200, cost: 420),
          FillRecord(
              id: '3',
              date: DateTime(2024, 1, 15),
              odometerKm: 1400,
              cost: 410),
          FillRecord(
              id: '4',
              date: DateTime(2024, 1, 22),
              odometerKm: 1600,
              cost: 430),
        ];

        when(() => mockStorageService.getRecords()).thenReturn(records);
        when(() => mockStorageService.getFuelPrice()).thenReturn(100.0);
        when(() => mockStorageService.getCurrency()).thenReturn('₹');

        provider = RecordsProvider(mockStorageService);
        await provider.init();

        final forecast = provider.getRefillForecast(now: DateTime(2024, 2, 4));
        expect(forecast, isNotNull);

        final result = forecast!;
        expect(result['status'], 'overdue');
        expect(result['daysUntilRefill'], lessThan(0));
      });
    });
  });
}
