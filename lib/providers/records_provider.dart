import 'package:flutter/foundation.dart';
import '../models/fill_record.dart';
import '../services/storage_service.dart';

class RecordsProvider with ChangeNotifier {
  final StorageService _storageService;
  
  List<FillRecord> _records = [];
  double _fuelPricePerLiter = StorageService.defaultFuelPrice;
  String _currency = StorageService.defaultCurrency;
  bool _isLoading = true;

  RecordsProvider(this._storageService);

  List<FillRecord> get records => _records;
  double get fuelPricePerLiter => _fuelPricePerLiter;
  String get currency => _currency;
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
      final monthKey = '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}';
      monthlySpending[monthKey] = (monthlySpending[monthKey] ?? 0) + record.cost;
      
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
      'averageFillCost': _records.isNotEmpty ? totalSpent / _records.length : 0.0,
      'averageDaysBetweenFills': averageDaysBetweenFills,
      'monthlySpending': monthlySpending,
      'firstFillDate': firstDate,
      'lastFillDate': lastDate,
      'totalDays': totalDays,
    };
  }
}

