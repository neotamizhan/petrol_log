import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../models/fill_record.dart';
import '../services/storage_service.dart';

class RecordsProvider with ChangeNotifier {
  final StorageService _storageService;

  List<FillRecord> _records = [];
  double _fuelPricePerLiter = StorageService.defaultFuelPrice;
  String _currency = StorageService.defaultCurrency;
  ThemeMode _themeMode = ThemeMode.system;
  bool _isLoading = true;

  RecordsProvider(this._storageService);

  List<FillRecord> get records => _records;
  double get fuelPricePerLiter => _fuelPricePerLiter;
  String get currency => _currency;
  ThemeMode get themeMode => _themeMode;
  bool get isLoading => _isLoading;

  /// Get records sorted by date (oldest first for calculations)
  List<FillRecord> get recordsByDateAsc {
    final sorted = List<FillRecord>.from(_records);
    sorted.sort((a, b) => a.date.compareTo(b.date));
    return sorted;
  }

  /// Get the previous record for a given record (by date)
  FillRecord? getPreviousRecord(FillRecord record) {
    final sortedRecords = recordsByDateAsc;
    final index = sortedRecords.indexWhere((r) => r.id == record.id);
    if (index <= 0) return null;
    return sortedRecords[index - 1];
  }

  /// Initialize the provider by loading data from storage
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    await _storageService.init();
    _records = _storageService.getRecords();
    _fuelPricePerLiter = _storageService.getFuelPrice();
    _currency = _storageService.getCurrency();
    _themeMode = _parseThemeMode(_storageService.getThemeMode());

    _isLoading = false;
    notifyListeners();
  }

  /// Add a new fill record
  Future<void> addRecord(FillRecord record) async {
    await _storageService.addRecord(record);
    _records = _storageService.getRecords();
    notifyListeners();
  }

  /// Update an existing record
  Future<void> updateRecord(FillRecord record) async {
    await _storageService.updateRecord(record);
    _records = _storageService.getRecords();
    notifyListeners();
  }

  /// Delete a record
  Future<void> deleteRecord(String id) async {
    await _storageService.deleteRecord(id);
    _records = _storageService.getRecords();
    notifyListeners();
  }

  /// Update fuel price per liter
  Future<void> setFuelPrice(double price) async {
    await _storageService.setFuelPrice(price);
    _fuelPricePerLiter = price;
    notifyListeners();
  }

  /// Update currency symbol
  Future<void> setCurrency(String currency) async {
    await _storageService.setCurrency(currency);
    _currency = currency;
    notifyListeners();
  }

  /// Update app theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    await _storageService.setThemeMode(_themeModeToString(mode));
    _themeMode = mode;
    notifyListeners();
  }

  ThemeMode _parseThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  /// Get stats for a specific record
  Map<String, dynamic> getRecordStats(FillRecord record) {
    final previousRecord = getPreviousRecord(record);

    return {
      'distanceKm': record.getDistanceSinceLastFill(previousRecord),
      'fuelLiters': record.getFuelAddedLiters(_fuelPricePerLiter),
      'mileage': record.getMileage(previousRecord, _fuelPricePerLiter),
      'daysSinceLastFill': record.getDaysSinceLastFill(previousRecord),
      'isFirstRecord': previousRecord == null,
    };
  }

  /// Get overall statistics for all records
  Map<String, dynamic> getOverallStats() {
    if (_records.isEmpty) {
      return {
        'totalRecords': 0,
        'totalSpent': 0.0,
        'totalFuelLiters': 0.0,
        'totalDistance': 0.0,
        'averageMileage': 0.0,
        'bestMileage': 0.0,
        'worstMileage': 0.0,
        'bestMileageRecord': null,
        'worstMileageRecord': null,
        'averageFillCost': 0.0,
        'averageDaysBetweenFills': 0.0,
        'monthlySpending': <String, double>{},
        'firstFillDate': null,
        'lastFillDate': null,
        'totalDays': 0,
      };
    }

    final sortedRecords = recordsByDateAsc;

    double totalSpent = 0;
    double totalFuelLiters = 0;
    double totalDistance = 0;
    List<double> mileages = [];
    List<int> daysBetweenFills = [];
    Map<String, double> monthlySpending = {};

    FillRecord? bestMileageRecord;
    FillRecord? worstMileageRecord;
    double bestMileage = 0;
    double worstMileage = double.infinity;

    for (int i = 0; i < sortedRecords.length; i++) {
      final record = sortedRecords[i];
      final previousRecord = i > 0 ? sortedRecords[i - 1] : null;

      totalSpent += record.cost;
      final fuelLiters = record.getFuelAddedLiters(_fuelPricePerLiter);
      totalFuelLiters += fuelLiters;

      // Monthly spending
      final monthKey =
          '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}';
      monthlySpending[monthKey] =
          (monthlySpending[monthKey] ?? 0) + record.cost;

      if (previousRecord != null) {
        final distance = record.getDistanceSinceLastFill(previousRecord);
        totalDistance += distance;

        final mileage = record.getMileage(previousRecord, _fuelPricePerLiter);
        if (mileage > 0) {
          mileages.add(mileage);

          if (mileage > bestMileage) {
            bestMileage = mileage;
            bestMileageRecord = record;
          }
          if (mileage < worstMileage) {
            worstMileage = mileage;
            worstMileageRecord = record;
          }
        }

        final days = record.getDaysSinceLastFill(previousRecord);
        if (days > 0) {
          daysBetweenFills.add(days);
        }
      }
    }

    final averageMileage = mileages.isNotEmpty
        ? mileages.reduce((a, b) => a + b) / mileages.length
        : 0.0;

    final averageDaysBetweenFills = daysBetweenFills.isNotEmpty
        ? daysBetweenFills.reduce((a, b) => a + b) / daysBetweenFills.length
        : 0.0;

    final firstDate = sortedRecords.first.date;
    final lastDate = sortedRecords.last.date;
    final totalDays = lastDate.difference(firstDate).inDays;

    return {
      'totalRecords': _records.length,
      'totalSpent': totalSpent,
      'totalFuelLiters': totalFuelLiters,
      'totalDistance': totalDistance,
      'averageMileage': averageMileage,
      'bestMileage': bestMileage == 0 ? 0.0 : bestMileage,
      'worstMileage': worstMileage == double.infinity ? 0.0 : worstMileage,
      'bestMileageRecord': bestMileageRecord,
      'worstMileageRecord': worstMileageRecord,
      'averageFillCost':
          _records.isNotEmpty ? totalSpent / _records.length : 0.0,
      'averageDaysBetweenFills': averageDaysBetweenFills,
      'monthlySpending': monthlySpending,
      'firstFillDate': firstDate,
      'lastFillDate': lastDate,
      'totalDays': totalDays,
    };
  }

  /// Predict when and where the next refill will likely happen.
  /// Returns null if there is not enough valid interval data.
  Map<String, dynamic>? getRefillForecast({DateTime? now}) {
    final sortedRecords = recordsByDateAsc;
    if (sortedRecords.length < 2) {
      return null;
    }

    final intervals = <Map<String, double>>[];
    for (int i = 1; i < sortedRecords.length; i++) {
      final current = sortedRecords[i];
      final previous = sortedRecords[i - 1];
      final days = current.date.difference(previous.date).inDays;
      final distance = current.getDistanceSinceLastFill(previous);
      if (days <= 0 || distance <= 0) {
        continue;
      }

      final liters = current.getFuelAddedLiters(_fuelPricePerLiter);
      final mileage = liters > 0 ? distance / liters : 0.0;
      intervals.add({
        'days': days.toDouble(),
        'distance': distance,
        'mileage': mileage,
        'cost': current.cost,
      });
    }

    if (intervals.isEmpty) {
      return null;
    }

    final recentIntervals = intervals.length > 6
        ? intervals.sublist(intervals.length - 6)
        : intervals;
    final recentDays = recentIntervals.map((i) => i['days'] ?? 0).toList();
    final recentDistances =
        recentIntervals.map((i) => i['distance'] ?? 0).toList();
    final recentCosts = recentIntervals.map((i) => i['cost'] ?? 0).toList();
    final recentMileages = recentIntervals
        .map((i) => i['mileage'] ?? 0)
        .where((mileage) => mileage > 0)
        .toList();

    final forecastDays = _weightedAverage(recentDays).clamp(1.0, 60.0).round();
    final forecastDistanceKm =
        _weightedAverage(recentDistances).clamp(1.0, 2000.0);

    final weightedMileage =
        recentMileages.isNotEmpty ? _weightedAverage(recentMileages) : 0.0;
    final weightedCost = _weightedAverage(recentCosts);
    final expectedCost = weightedMileage > 0
        ? (forecastDistanceKm / weightedMileage) * _fuelPricePerLiter
        : weightedCost;

    final latestRecord = sortedRecords.last;
    final nextRefillDate = latestRecord.date.add(Duration(days: forecastDays));
    final projectedOdometerKm = latestRecord.odometerKm + forecastDistanceKm;

    final referenceNow = now ?? DateTime.now();
    final today = DateTime(
      referenceNow.year,
      referenceNow.month,
      referenceNow.day,
    );
    final nextRefillDateOnly = DateTime(
      nextRefillDate.year,
      nextRefillDate.month,
      nextRefillDate.day,
    );
    final latestDateOnly = DateTime(
      latestRecord.date.year,
      latestRecord.date.month,
      latestRecord.date.day,
    );

    final daysUntilRefill = nextRefillDateOnly.difference(today).inDays;
    final daysSinceLastFill = today.difference(latestDateOnly).inDays;
    final progress = forecastDays > 0
        ? (daysSinceLastFill / forecastDays).clamp(0.0, 1.8)
        : 0.0;

    return {
      'nextRefillDate': nextRefillDate,
      'forecastDays': forecastDays,
      'forecastDistanceKm': forecastDistanceKm,
      'projectedOdometerKm': projectedOdometerKm,
      'expectedCost': expectedCost,
      'confidence': _forecastConfidence(recentIntervals),
      'intervalCount': recentIntervals.length,
      'daysUntilRefill': daysUntilRefill,
      'daysSinceLastFill': daysSinceLastFill,
      'progress': progress,
      'status': daysUntilRefill < 0
          ? 'overdue'
          : daysUntilRefill <= 2
              ? 'soon'
              : 'on_track',
    };
  }

  double _weightedAverage(List<double> values) {
    if (values.isEmpty) {
      return 0;
    }

    double weightedSum = 0;
    double totalWeight = 0;
    for (int i = 0; i < values.length; i++) {
      final weight = i + 1;
      weightedSum += values[i] * weight;
      totalWeight += weight;
    }

    if (totalWeight == 0) {
      return 0;
    }
    return weightedSum / totalWeight;
  }

  double _forecastConfidence(List<Map<String, double>> intervals) {
    if (intervals.isEmpty) {
      return 0.2;
    }

    final days = intervals.map((i) => i['days'] ?? 0).toList();
    final distances = intervals.map((i) => i['distance'] ?? 0).toList();
    final daysVariation = _coefficientOfVariation(days);
    final distanceVariation = _coefficientOfVariation(distances);
    final consistencyScore =
        (1 - ((daysVariation + distanceVariation) / 2)).clamp(0.0, 1.0);
    final sampleScore = (intervals.length / 6).clamp(0.0, 1.0);
    return (consistencyScore * 0.7 + sampleScore * 0.3).clamp(0.2, 0.95);
  }

  double _coefficientOfVariation(List<double> values) {
    if (values.isEmpty) {
      return 1.0;
    }

    final mean = values.reduce((a, b) => a + b) / values.length;
    if (mean <= 0) {
      return 1.0;
    }

    if (values.length == 1) {
      return 0.5;
    }

    double sumSquaredDiff = 0;
    for (final value in values) {
      final diff = value - mean;
      sumSquaredDiff += diff * diff;
    }
    final variance = sumSquaredDiff / values.length;
    final standardDeviation = math.sqrt(variance);
    return (standardDeviation / mean).clamp(0.0, 1.2);
  }
}
