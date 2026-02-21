import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/fill_record.dart';
import '../models/fuel_type.dart';
import '../models/maintenance_record.dart';
import '../models/vehicle.dart';
import '../services/storage_service.dart';

class RecordsProvider with ChangeNotifier {
  final StorageService _storageService;

  List<FillRecord> _records = [];
  List<FuelType> _fuelTypes = [];
  String _selectedFuelTypeId = FuelType.defaultId;
  List<Vehicle> _vehicles = [];
  String _selectedVehicleId = 'default_vehicle';
  List<MaintenanceRecord> _maintenanceRecords = [];
  String _currency = StorageService.defaultCurrency;
  ThemeMode _themeMode = ThemeMode.system;
  bool _isLoading = true;

  RecordsProvider(this._storageService);

  List<FillRecord> get records => _records;
  List<FuelType> get fuelTypes => List<FuelType>.unmodifiable(_fuelTypes);
  List<FuelType> get activeFuelTypes =>
      _fuelTypes.where((fuelType) => fuelType.active).toList();
  String get selectedFuelTypeId => _selectedFuelTypeId;
  List<Vehicle> get vehicles => List<Vehicle>.unmodifiable(_vehicles);
  List<Vehicle> get activeVehicles =>
      _vehicles.where((vehicle) => vehicle.active).toList();
  String get selectedVehicleId => _resolveSelectedVehicleId(_selectedVehicleId);
  List<MaintenanceRecord> get maintenanceRecords =>
      List<MaintenanceRecord>.unmodifiable(_maintenanceRecords);

  FuelType? get selectedFuelType {
    for (final fuelType in _fuelTypes) {
      if (fuelType.id == _selectedFuelTypeId) {
        return fuelType;
      }
    }
    return _fuelTypes.isNotEmpty ? _fuelTypes.first : null;
  }

  Vehicle? get selectedVehicle {
    final resolvedId = selectedVehicleId;
    for (final vehicle in _vehicles) {
      if (vehicle.id == resolvedId) {
        return vehicle;
      }
    }
    return _vehicles.isNotEmpty ? _vehicles.first : null;
  }

  /// Backward-compatible getter used by existing UI.
  double get fuelPricePerLiter =>
      selectedFuelType?.pricePerLiter ?? StorageService.defaultFuelPrice;
  String get currency => _currency;
  ThemeMode get themeMode => _themeMode;
  bool get isLoading => _isLoading;

  /// Get records sorted by date (oldest first for calculations)
  List<FillRecord> get recordsByDateAsc {
    final sorted = List<FillRecord>.from(_records);
    sorted.sort((a, b) => a.date.compareTo(b.date));
    return sorted;
  }

  FuelType? getFuelTypeById(String id) {
    for (final fuelType in _fuelTypes) {
      if (fuelType.id == id) {
        return fuelType;
      }
    }
    return null;
  }

  String getFuelTypeName(String id) {
    final fuelType = getFuelTypeById(id);
    if (fuelType != null) {
      return fuelType.name;
    }
    return FuelType.defaultName;
  }

  double getFuelPriceForFuelTypeId(String id) {
    final fuelType = getFuelTypeById(id);
    if (fuelType != null && fuelType.pricePerLiter > 0) {
      return fuelType.pricePerLiter;
    }

    final selected = selectedFuelType;
    if (selected != null && selected.pricePerLiter > 0) {
      return selected.pricePerLiter;
    }

    return StorageService.defaultFuelPrice;
  }

  double getFuelPriceForRecord(FillRecord record) {
    return getFuelPriceForFuelTypeId(record.fuelTypeId);
  }

  /// Get the previous record for a given record (by date)
  FillRecord? getPreviousRecord(FillRecord record,
      {String? fuelTypeId, String? vehicleId}) {
    final sortedRecords = _filteredRecordsByFuelTypeAndVehicle(
        fuelTypeId, vehicleId ?? record.vehicleId);
    final index = sortedRecords.indexWhere((r) => r.id == record.id);
    if (index <= 0) {
      return null;
    }
    return sortedRecords[index - 1];
  }

  /// Initialize the provider by loading data from storage
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    await _storageService.init();
    _fuelTypes = _sanitizeFuelTypes(_storageService.getFuelTypes());
    _selectedFuelTypeId = _resolveSelectedFuelTypeId(
      _storageService.getSelectedFuelTypeId(),
    );
    _vehicles = _sanitizeVehicles(_storageService.getVehicles());
    _selectedVehicleId = _resolveSelectedVehicleId(
      _storageService.getSelectedVehicleId(),
    );
    _records = _normalizeRecordFuelTypes(_storageService.getRecords());
    _maintenanceRecords = _storageService.getMaintenanceRecords();
    _currency = _storageService.getCurrency();
    _themeMode = _parseThemeMode(_storageService.getThemeMode());

    await _storageService.saveFuelTypes(_fuelTypes);
    await _storageService.setSelectedFuelTypeId(_selectedFuelTypeId);
    await _storageService.saveVehicles(_vehicles);
    if (_vehicles.isNotEmpty) {
      await _storageService.setSelectedVehicle(_selectedVehicleId);
    }
    await _storageService.saveRecords(_records);
    await _storageService.saveMaintenanceRecords(_maintenanceRecords);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _persistFuelTypeSettings() async {
    await _storageService.saveFuelTypes(_fuelTypes);
    await _storageService.setSelectedFuelTypeId(_selectedFuelTypeId);
  }

  List<FuelType> _sanitizeFuelTypes(List<FuelType> incoming) {
    final Map<String, FuelType> byId = {};

    for (final fuelType in incoming) {
      final normalizedId = FuelType.normalizeId(fuelType.id);
      final normalizedName = fuelType.name.trim().isNotEmpty
          ? fuelType.name.trim()
          : FuelType.defaultName;
      final normalizedPrice = fuelType.pricePerLiter > 0
          ? fuelType.pricePerLiter
          : StorageService.defaultFuelPrice;

      byId[normalizedId] = fuelType.copyWith(
        id: normalizedId,
        name: normalizedName,
        pricePerLiter: normalizedPrice,
      );
    }

    if (!byId.containsKey(FuelType.defaultId)) {
      byId[FuelType.defaultId] = FuelType(
        id: FuelType.defaultId,
        name: FuelType.defaultName,
        pricePerLiter: StorageService.defaultFuelPrice,
        active: true,
      );
    }

    final result = byId.values.toList();
    if (result.every((fuelType) => !fuelType.active)) {
      result[0] = result[0].copyWith(active: true);
    }

    return result;
  }

  String _resolveSelectedFuelTypeId(String preferredId) {
    final preferred = getFuelTypeById(preferredId);
    if (preferred != null && preferred.active) {
      return preferred.id;
    }

    final active = activeFuelTypes;
    if (active.isNotEmpty) {
      return active.first.id;
    }

    return _fuelTypes.first.id;
  }

  List<Vehicle> _sanitizeVehicles(List<Vehicle> incoming) {
    final Map<String, Vehicle> byId = {};

    for (final vehicle in incoming) {
      final normalizedId = vehicle.id.trim();
      if (normalizedId.isEmpty) {
        continue;
      }

      final normalizedName =
          vehicle.name.trim().isNotEmpty ? vehicle.name.trim() : 'Vehicle';

      byId[normalizedId] = vehicle.copyWith(
        id: normalizedId,
        name: normalizedName,
      );
    }

    final result = byId.values.toList();
    if (result.isNotEmpty && result.every((vehicle) => !vehicle.active)) {
      result[0] = result[0].copyWith(active: true);
    }
    return result;
  }

  String _resolveSelectedVehicleId(String preferredId) {
    final preferred =
        _vehicles.where((vehicle) => vehicle.id == preferredId).toList();
    if (preferred.length == 1 && preferred.first.active) {
      return preferred.first.id;
    }

    final active = activeVehicles;
    if (active.isNotEmpty) {
      return active.first.id;
    }

    if (_vehicles.isNotEmpty) {
      return _vehicles.first.id;
    }

    return preferredId;
  }

  List<FillRecord> _normalizeRecordFuelTypes(List<FillRecord> incoming) {
    final validIds = _fuelTypes.map((fuelType) => fuelType.id).toSet();
    final fallbackId = _selectedFuelTypeId;

    return incoming.map((record) {
      if (validIds.contains(record.fuelTypeId)) {
        return record;
      }
      return record.copyWith(fuelTypeId: fallbackId);
    }).toList();
  }

  FillRecord _normalizeRecord(FillRecord record) {
    final valid =
        _fuelTypes.any((fuelType) => fuelType.id == record.fuelTypeId);
    if (valid) {
      return record;
    }
    return record.copyWith(fuelTypeId: _selectedFuelTypeId);
  }

  List<FillRecord> _filteredRecordsByFuelTypeAndVehicle(
      String? fuelTypeId, String? vehicleId) {
    final sorted = recordsByDateAsc;
    var filtered = sorted;

    if (vehicleId != null && vehicleId != 'all') {
      filtered =
          filtered.where((record) => record.vehicleId == vehicleId).toList();
    }

    if (fuelTypeId != null && fuelTypeId != 'all') {
      filtered =
          filtered.where((record) => record.fuelTypeId == fuelTypeId).toList();
    }

    return filtered;
  }

  /// Add a new fill record
  Future<void> addRecord(FillRecord record) async {
    final normalized = _normalizeRecord(record);
    await _storageService.addRecord(normalized);
    _records = _storageService.getRecords();

    // Update vehicle's current odometer
    final vehicle = getVehicleById(normalized.vehicleId);
    if (vehicle != null && normalized.odometerKm > vehicle.currentOdometer) {
      final updatedVehicle =
          vehicle.copyWith(currentOdometer: normalized.odometerKm);
      _vehicles = _vehicles
          .map((v) => v.id == vehicle.id ? updatedVehicle : v)
          .toList();
      await _storageService.saveVehicles(_vehicles);
    }

    notifyListeners();
  }

  /// Update an existing record
  Future<void> updateRecord(FillRecord record) async {
    final normalized = _normalizeRecord(record);
    await _storageService.updateRecord(normalized);
    _records = _storageService.getRecords();
    notifyListeners();
  }

  /// Delete a record
  Future<void> deleteRecord(String id) async {
    await _storageService.deleteRecord(id);
    _records = _storageService.getRecords();
    notifyListeners();
  }

  Future<void> setSelectedFuelType(String fuelTypeId) async {
    _selectedFuelTypeId = _resolveSelectedFuelTypeId(fuelTypeId);
    await _storageService.setSelectedFuelTypeId(_selectedFuelTypeId);
    notifyListeners();
  }

  Future<void> addFuelType({
    required String name,
    required double pricePerLiter,
  }) async {
    final baseId = FuelType.normalizeId(name);
    String nextId = baseId;
    int suffix = 2;
    while (_fuelTypes.any((fuelType) => fuelType.id == nextId)) {
      nextId = '${baseId}_$suffix';
      suffix++;
    }

    _fuelTypes = [
      ..._fuelTypes,
      FuelType(
        id: nextId,
        name: name.trim(),
        pricePerLiter: pricePerLiter,
        active: true,
      ),
    ];

    await _persistFuelTypeSettings();
    notifyListeners();
  }

  Future<void> updateFuelType(FuelType updatedFuelType) async {
    _fuelTypes = _fuelTypes.map((fuelType) {
      if (fuelType.id == updatedFuelType.id) {
        return updatedFuelType.copyWith(
          name: updatedFuelType.name.trim(),
          pricePerLiter: updatedFuelType.pricePerLiter > 0
              ? updatedFuelType.pricePerLiter
              : fuelType.pricePerLiter,
        );
      }
      return fuelType;
    }).toList();

    _fuelTypes = _sanitizeFuelTypes(_fuelTypes);
    _selectedFuelTypeId = _resolveSelectedFuelTypeId(_selectedFuelTypeId);
    await _persistFuelTypeSettings();
    notifyListeners();
  }

  Future<void> deleteFuelType(String fuelTypeId) async {
    if (_fuelTypes.length <= 1) {
      return;
    }

    final usedByRecords =
        _records.any((record) => record.fuelTypeId == fuelTypeId);
    if (usedByRecords) {
      _fuelTypes = _fuelTypes.map((fuelType) {
        if (fuelType.id == fuelTypeId) {
          return fuelType.copyWith(active: false);
        }
        return fuelType;
      }).toList();
    } else {
      _fuelTypes =
          _fuelTypes.where((fuelType) => fuelType.id != fuelTypeId).toList();
    }

    _fuelTypes = _sanitizeFuelTypes(_fuelTypes);
    _selectedFuelTypeId = _resolveSelectedFuelTypeId(_selectedFuelTypeId);
    await _persistFuelTypeSettings();
    notifyListeners();
  }

  bool hasRecordsForFuelType(String fuelTypeId) {
    return _records.any((record) => record.fuelTypeId == fuelTypeId);
  }

  /// Backward-compatible method: updates currently selected fuel type price.
  Future<void> setFuelPrice(double price) async {
    if (price <= 0) {
      return;
    }

    final selectedId = _selectedFuelTypeId;
    _fuelTypes = _fuelTypes.map((fuelType) {
      if (fuelType.id == selectedId) {
        return fuelType.copyWith(pricePerLiter: price);
      }
      return fuelType;
    }).toList();

    await _persistFuelTypeSettings();
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
  Map<String, dynamic> getRecordStats(FillRecord record, {String? fuelTypeId}) {
    final previousRecord = getPreviousRecord(record, fuelTypeId: fuelTypeId);
    final pricePerLiter = getFuelPriceForRecord(record);

    return {
      'distanceKm': record.getDistanceSinceLastFill(previousRecord),
      'fuelLiters': record.getFuelAddedLiters(pricePerLiter),
      'mileage': record.getMileage(previousRecord, pricePerLiter),
      'daysSinceLastFill': record.getDaysSinceLastFill(previousRecord),
      'isFirstRecord': previousRecord == null,
      'fuelTypeId': record.fuelTypeId,
      'fuelTypeName': getFuelTypeName(record.fuelTypeId),
      'pricePerLiter': pricePerLiter,
    };
  }

  /// Get overall statistics for all records, or a specific fuel type and vehicle.
  Map<String, dynamic> getOverallStats(
      {String? fuelTypeId, String? vehicleId}) {
    final filteredRecords =
        _filteredRecordsByFuelTypeAndVehicle(fuelTypeId, vehicleId);

    if (filteredRecords.isEmpty) {
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
        'fuelTypeFilter': fuelTypeId,
        'vehicleFilter': vehicleId,
      };
    }

    final sortedRecords = List<FillRecord>.from(filteredRecords)
      ..sort((a, b) => a.date.compareTo(b.date));

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
      final pricePerLiter = getFuelPriceForRecord(record);

      totalSpent += record.cost;
      final fuelLiters = record.getFuelAddedLiters(pricePerLiter);
      totalFuelLiters += fuelLiters;

      final monthKey =
          '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}';
      monthlySpending[monthKey] =
          (monthlySpending[monthKey] ?? 0) + record.cost;

      if (previousRecord != null) {
        final distance = record.getDistanceSinceLastFill(previousRecord);
        totalDistance += distance;

        final mileage = record.getMileage(previousRecord, pricePerLiter);
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
      'totalRecords': filteredRecords.length,
      'totalSpent': totalSpent,
      'totalFuelLiters': totalFuelLiters,
      'totalDistance': totalDistance,
      'averageMileage': averageMileage,
      'bestMileage': bestMileage == 0 ? 0.0 : bestMileage,
      'worstMileage': worstMileage == double.infinity ? 0.0 : worstMileage,
      'bestMileageRecord': bestMileageRecord,
      'worstMileageRecord': worstMileageRecord,
      'averageFillCost': filteredRecords.isNotEmpty
          ? totalSpent / filteredRecords.length
          : 0.0,
      'averageDaysBetweenFills': averageDaysBetweenFills,
      'monthlySpending': monthlySpending,
      'firstFillDate': firstDate,
      'lastFillDate': lastDate,
      'totalDays': totalDays,
      'fuelTypeFilter': fuelTypeId,
      'vehicleFilter': vehicleId,
    };
  }

  /// Predict when and where the next refill will likely happen.
  /// Returns null if there is not enough valid interval data.
  Map<String, dynamic>? getRefillForecast(
      {DateTime? now, String? fuelTypeId, String? vehicleId}) {
    final sortedRecords =
        _filteredRecordsByFuelTypeAndVehicle(fuelTypeId, vehicleId);
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

      final pricePerLiter = getFuelPriceForRecord(current);
      final liters = current.getFuelAddedLiters(pricePerLiter);
      final mileage = liters > 0 ? distance / liters : 0.0;
      intervals.add({
        'days': days.toDouble(),
        'distance': distance,
        'mileage': mileage,
        'cost': current.cost,
        'price': pricePerLiter,
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
    final recentPrices = recentIntervals.map((i) => i['price'] ?? 0).toList();
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
    final weightedPrice = _weightedAverage(recentPrices);

    final expectedCost = weightedMileage > 0
        ? (forecastDistanceKm / weightedMileage) *
            (weightedPrice > 0 ? weightedPrice : fuelPricePerLiter)
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

  List<MaintenanceRecord> getMaintenanceRecordsForVehicle(String vehicleId) {
    final records = _maintenanceRecords
        .where((record) => record.vehicleId == vehicleId)
        .toList();
    records.sort((a, b) {
      final byServiceDate = b.serviceDate.compareTo(a.serviceDate);
      if (byServiceDate != 0) {
        return byServiceDate;
      }
      return b.createdAt.compareTo(a.createdAt);
    });
    return records;
  }

  bool hasMaintenanceRecordsForVehicle(String vehicleId) {
    return _maintenanceRecords.any((record) => record.vehicleId == vehicleId);
  }

  Map<String, dynamic> getMaintenanceDueStatus(
    MaintenanceRecord record, {
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final today = DateTime(reference.year, reference.month, reference.day);
    final currentOdometer =
        getVehicleById(record.vehicleId)?.currentOdometer ?? record.odometerKm;

    double? kmRemaining;
    bool overdueByKm = false;
    bool dueSoonByKm = false;
    if (record.nextDueOdometerKm != null) {
      kmRemaining = record.nextDueOdometerKm! - currentOdometer;
      overdueByKm = kmRemaining <= 0;
      dueSoonByKm = kmRemaining > 0 && kmRemaining <= 500;
    }

    int? daysRemaining;
    bool overdueByDate = false;
    bool dueSoonByDate = false;
    if (record.nextDueDate != null) {
      final dueDateOnly = DateTime(
        record.nextDueDate!.year,
        record.nextDueDate!.month,
        record.nextDueDate!.day,
      );
      daysRemaining = dueDateOnly.difference(today).inDays;
      overdueByDate = daysRemaining < 0;
      dueSoonByDate = daysRemaining >= 0 && daysRemaining <= 14;
    }

    final overdue = overdueByKm || overdueByDate;
    final dueSoon = !overdue && (dueSoonByKm || dueSoonByDate);
    final status = !record.hasDueTarget
        ? 'completed'
        : overdue
            ? 'overdue'
            : dueSoon
                ? 'due_soon'
                : 'on_track';

    return {
      'status': status,
      'currentOdometerKm': currentOdometer,
      'kmRemaining': kmRemaining,
      'daysRemaining': daysRemaining,
      'isOverdue': overdue,
      'isDueSoon': dueSoon,
      'overdueByKm': overdueByKm,
      'overdueByDate': overdueByDate,
      'dueSoonByKm': dueSoonByKm,
      'dueSoonByDate': dueSoonByDate,
      'hasDueTarget': record.hasDueTarget,
    };
  }

  List<MaintenanceRecord> _latestScheduledMaintenance(
      List<MaintenanceRecord> records) {
    final sorted = List<MaintenanceRecord>.from(records)
      ..sort((a, b) {
        final byServiceDate = b.serviceDate.compareTo(a.serviceDate);
        if (byServiceDate != 0) {
          return byServiceDate;
        }
        return b.createdAt.compareTo(a.createdAt);
      });

    final seenScheduleKeys = <String>{};
    final latest = <MaintenanceRecord>[];

    for (final record in sorted) {
      if (!record.hasDueTarget) {
        continue;
      }
      if (seenScheduleKeys.add(record.scheduleKey)) {
        latest.add(record);
      }
    }

    return latest;
  }

  Map<String, dynamic> getMaintenanceOverview({
    String? vehicleId,
    DateTime? now,
  }) {
    final filtered = (vehicleId == null || vehicleId == 'all')
        ? List<MaintenanceRecord>.from(_maintenanceRecords)
        : getMaintenanceRecordsForVehicle(vehicleId);

    if (filtered.isEmpty) {
      return {
        'totalRecords': 0,
        'scheduledItems': 0,
        'overdueCount': 0,
        'dueSoonCount': 0,
        'onTrackCount': 0,
        'totalCost': 0.0,
        'latestServiceDate': null,
        'dueItems': <Map<String, dynamic>>[],
        'needsAttention': false,
        'vehicleFilter': vehicleId,
      };
    }

    final sortedHistory = List<MaintenanceRecord>.from(filtered)
      ..sort((a, b) => b.serviceDate.compareTo(a.serviceDate));
    final totalCost =
        filtered.fold<double>(0, (sum, record) => sum + record.cost);
    final latestServiceDate = sortedHistory.first.serviceDate;

    final latestSchedules = _latestScheduledMaintenance(filtered);
    final scheduleSnapshots = latestSchedules.map((record) {
      final dueStatus = getMaintenanceDueStatus(record, now: now);
      return {
        'record': record,
        'dueStatus': dueStatus,
      };
    }).toList();

    final overdueItems = scheduleSnapshots
        .where((item) =>
            (item['dueStatus'] as Map<String, dynamic>)['status'] == 'overdue')
        .toList();
    final dueSoonItems = scheduleSnapshots
        .where((item) =>
            (item['dueStatus'] as Map<String, dynamic>)['status'] == 'due_soon')
        .toList();
    final onTrackCount = scheduleSnapshots
        .where((item) =>
            (item['dueStatus'] as Map<String, dynamic>)['status'] == 'on_track')
        .length;

    final dueItems = <Map<String, dynamic>>[
      ...overdueItems,
      ...dueSoonItems,
    ];

    return {
      'totalRecords': filtered.length,
      'scheduledItems': latestSchedules.length,
      'overdueCount': overdueItems.length,
      'dueSoonCount': dueSoonItems.length,
      'onTrackCount': onTrackCount,
      'totalCost': totalCost,
      'latestServiceDate': latestServiceDate,
      'dueItems': dueItems,
      'needsAttention': dueItems.isNotEmpty,
      'vehicleFilter': vehicleId,
    };
  }

  Future<void> addMaintenanceRecord(MaintenanceRecord record) async {
    await _storageService.addMaintenanceRecord(record);
    _maintenanceRecords = _storageService.getMaintenanceRecords();

    final vehicle = getVehicleById(record.vehicleId);
    if (vehicle != null && record.odometerKm > vehicle.currentOdometer) {
      final updatedVehicle =
          vehicle.copyWith(currentOdometer: record.odometerKm);
      _vehicles = _vehicles
          .map((v) => v.id == vehicle.id ? updatedVehicle : v)
          .toList();
      await _storageService.saveVehicles(_vehicles);
    }

    notifyListeners();
  }

  Future<void> updateMaintenanceRecord(MaintenanceRecord record) async {
    await _storageService.updateMaintenanceRecord(record);
    _maintenanceRecords = _storageService.getMaintenanceRecords();

    final vehicle = getVehicleById(record.vehicleId);
    if (vehicle != null && record.odometerKm > vehicle.currentOdometer) {
      final updatedVehicle =
          vehicle.copyWith(currentOdometer: record.odometerKm);
      _vehicles = _vehicles
          .map((v) => v.id == vehicle.id ? updatedVehicle : v)
          .toList();
      await _storageService.saveVehicles(_vehicles);
    }

    notifyListeners();
  }

  Future<void> deleteMaintenanceRecord(String id) async {
    await _storageService.deleteMaintenanceRecord(id);
    _maintenanceRecords = _storageService.getMaintenanceRecords();
    notifyListeners();
  }

  // Vehicle Management Methods

  /// Get a vehicle by ID
  Vehicle? getVehicleById(String id) {
    for (final vehicle in _vehicles) {
      if (vehicle.id == id) {
        return vehicle;
      }
    }
    return null;
  }

  /// Get all records for a specific vehicle
  List<FillRecord> getRecordsForVehicle(String vehicleId) {
    return _records.where((record) => record.vehicleId == vehicleId).toList();
  }

  /// Check if a vehicle has any associated records
  bool hasRecordsForVehicle(String vehicleId) {
    final hasFillRecords =
        _records.any((record) => record.vehicleId == vehicleId);
    return hasFillRecords || hasMaintenanceRecordsForVehicle(vehicleId);
  }

  /// Add a new vehicle
  Future<void> addVehicle(Vehicle vehicle) async {
    _vehicles = _sanitizeVehicles([..._vehicles, vehicle]);
    _selectedVehicleId = _resolveSelectedVehicleId(_selectedVehicleId);
    await _storageService.saveVehicles(_vehicles);
    if (_vehicles.isNotEmpty) {
      await _storageService.setSelectedVehicle(_selectedVehicleId);
    }
    notifyListeners();
  }

  /// Update an existing vehicle
  Future<void> updateVehicle(Vehicle updatedVehicle) async {
    _vehicles = _sanitizeVehicles(_vehicles.map((v) {
      if (v.id == updatedVehicle.id) {
        return updatedVehicle;
      }
      return v;
    }).toList());
    _selectedVehicleId = _resolveSelectedVehicleId(_selectedVehicleId);
    await _storageService.saveVehicles(_vehicles);
    if (_vehicles.isNotEmpty) {
      await _storageService.setSelectedVehicle(_selectedVehicleId);
    }
    notifyListeners();
  }

  /// Delete a vehicle (soft delete if it has records, hard delete otherwise)
  Future<void> deleteVehicle(String vehicleId) async {
    if (_vehicles.length <= 1) {
      return; // Don't delete the last vehicle
    }

    final hasRecords = hasRecordsForVehicle(vehicleId);
    if (hasRecords) {
      // Soft delete: mark as inactive
      _vehicles = _vehicles.map((v) {
        if (v.id == vehicleId) {
          return v.copyWith(active: false);
        }
        return v;
      }).toList();
    } else {
      // Hard delete: remove from list
      _vehicles = _vehicles.where((v) => v.id != vehicleId).toList();
    }

    _vehicles = _sanitizeVehicles(_vehicles);
    _selectedVehicleId = _resolveSelectedVehicleId(
      _selectedVehicleId == vehicleId ? '' : _selectedVehicleId,
    );

    await _storageService.saveVehicles(_vehicles);
    if (_vehicles.isNotEmpty) {
      await _storageService.setSelectedVehicle(_selectedVehicleId);
    }
    notifyListeners();
  }

  /// Set the currently selected vehicle
  Future<void> setSelectedVehicle(String vehicleId) async {
    final vehicle = getVehicleById(vehicleId);
    if (vehicle != null && vehicle.active) {
      _selectedVehicleId = vehicleId;
      await _storageService.setSelectedVehicle(vehicleId);
      notifyListeners();
    }
  }

  /// Get the highest odometer reading for a specific vehicle
  double getHighestOdometerForVehicle(String vehicleId) {
    final fillReadings =
        getRecordsForVehicle(vehicleId).map((record) => record.odometerKm);
    final maintenanceReadings = getMaintenanceRecordsForVehicle(vehicleId)
        .map((record) => record.odometerKm);
    final allReadings = [...fillReadings, ...maintenanceReadings];

    if (allReadings.isEmpty) {
      return 0.0;
    }
    return allReadings.reduce(math.max);
  }
}
