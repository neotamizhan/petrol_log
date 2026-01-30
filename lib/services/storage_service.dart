import 'package:shared_preferences/shared_preferences.dart';
import '../models/fill_record.dart';

class StorageService {
  static const String _recordsKey = 'fill_records';
  static const String _fuelPriceKey = 'fuel_price_per_liter';
  static const String _currencyKey = 'currency_symbol';
  static const double defaultFuelPrice = 100.0; // Default price per liter
  static const String defaultCurrency = '₹'; // Default currency symbol

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get all stored fill records, sorted by date (newest first)
  List<FillRecord> getRecords() {
    final String? jsonString = _prefs.getString(_recordsKey);
    if (jsonString == null || jsonString.isEmpty) return [];
    
    final records = FillRecord.decodeRecords(jsonString);
    records.sort((a, b) => b.date.compareTo(a.date));
    return records;
  }

  /// Save all records
  Future<void> saveRecords(List<FillRecord> records) async {
    final jsonString = FillRecord.encodeRecords(records);
    await _prefs.setString(_recordsKey, jsonString);
  }

  /// Add a new record
  Future<void> addRecord(FillRecord record) async {
    final records = getRecords();
    records.add(record);
    await saveRecords(records);
  }

  /// Delete a record by ID
  Future<void> deleteRecord(String id) async {
    final records = getRecords();
    records.removeWhere((r) => r.id == id);
    await saveRecords(records);
  }

  /// Update an existing record
  Future<void> updateRecord(FillRecord updatedRecord) async {
    final records = getRecords();
    final index = records.indexWhere((r) => r.id == updatedRecord.id);
    if (index != -1) {
      records[index] = updatedRecord;
      await saveRecords(records);
    }
  }

  /// Get fuel price per liter
  double getFuelPrice() {
    return _prefs.getDouble(_fuelPriceKey) ?? defaultFuelPrice;
  }

  /// Set fuel price per liter
  Future<void> setFuelPrice(double price) async {
    await _prefs.setDouble(_fuelPriceKey, price);
  }

  /// Get currency symbol
  String getCurrency() {
    return _prefs.getString(_currencyKey) ?? defaultCurrency;
  }

  /// Set currency symbol
  Future<void> setCurrency(String currency) async {
    await _prefs.setString(_currencyKey, currency);
  }
}

