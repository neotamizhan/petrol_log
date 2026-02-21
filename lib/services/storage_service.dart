import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/fill_record.dart';
import '../models/fuel_type.dart';
import '../models/maintenance_record.dart';
import '../models/vehicle.dart';

class StorageService {
  static const String _recordsKey = 'fill_records';
  static const String _fuelPriceKey = 'fuel_price_per_liter';
  static const String _currencyKey = 'currency_symbol';
  static const String _themeModeKey = 'theme_mode';
  static const String _fuelTypesKey = 'fuel_types';
  static const String _selectedFuelTypeKey = 'selected_fuel_type_id';
  static const String _vehiclesKey = 'vehicles';
  static const String _selectedVehicleKey = 'selected_vehicle_id';
  static const String _maintenanceRecordsKey = 'maintenance_records';

  static const double defaultFuelPrice = 100.0;
  static const String defaultCurrency = '₹';
  static const String defaultThemeMode = 'system';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _migrateLegacyFuelSettings();
    await _migrateToVehicleSupport();
  }

  Future<void> _migrateLegacyFuelSettings() async {
    final existingFuelTypes = _prefs.getString(_fuelTypesKey);
    if (existingFuelTypes == null || existingFuelTypes.isEmpty) {
      final legacyPrice = _prefs.getDouble(_fuelPriceKey) ?? defaultFuelPrice;
      final defaultFuelType = FuelType(
        id: FuelType.defaultId,
        name: FuelType.defaultName,
        pricePerLiter: legacyPrice,
        active: true,
      );
      await _prefs.setString(
          _fuelTypesKey, FuelType.encodeFuelTypes([defaultFuelType]));
    }

    if ((_prefs.getString(_selectedFuelTypeKey) ?? '').isEmpty) {
      await _prefs.setString(_selectedFuelTypeKey, FuelType.defaultId);
    }

    final rawRecords = _prefs.getString(_recordsKey);
    if (rawRecords == null || rawRecords.isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(rawRecords);
      if (decoded is! List) {
        return;
      }

      bool changed = false;
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          if ((item['fuelTypeId'] as String?)?.trim().isNotEmpty != true) {
            item['fuelTypeId'] = FuelType.defaultId;
            changed = true;
          }
        } else if (item is Map) {
          if ((item['fuelTypeId'] as String?)?.trim().isNotEmpty != true) {
            item['fuelTypeId'] = FuelType.defaultId;
            changed = true;
          }
        }
      }

      if (changed) {
        await _prefs.setString(_recordsKey, jsonEncode(decoded));
      }
    } catch (_) {
      // Keep existing data untouched if migration parsing fails.
    }
  }

  /// Get all stored fill records, sorted by date (newest first)
  List<FillRecord> getRecords() {
    final String? jsonString = _prefs.getString(_recordsKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

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

  /// Get all stored maintenance records, sorted by service date (newest first)
  List<MaintenanceRecord> getMaintenanceRecords() {
    final jsonString = _prefs.getString(_maintenanceRecordsKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    final records = MaintenanceRecord.decodeRecords(jsonString);
    records.sort((a, b) => b.serviceDate.compareTo(a.serviceDate));
    return records;
  }

  /// Save all maintenance records
  Future<void> saveMaintenanceRecords(List<MaintenanceRecord> records) async {
    final jsonString = MaintenanceRecord.encodeRecords(records);
    await _prefs.setString(_maintenanceRecordsKey, jsonString);
  }

  /// Add a maintenance record
  Future<void> addMaintenanceRecord(MaintenanceRecord record) async {
    final records = getMaintenanceRecords();
    records.add(record);
    await saveMaintenanceRecords(records);
  }

  /// Update an existing maintenance record
  Future<void> updateMaintenanceRecord(MaintenanceRecord updatedRecord) async {
    final records = getMaintenanceRecords();
    final index = records.indexWhere((record) => record.id == updatedRecord.id);
    if (index != -1) {
      records[index] = updatedRecord;
      await saveMaintenanceRecords(records);
    }
  }

  /// Delete a maintenance record by ID
  Future<void> deleteMaintenanceRecord(String id) async {
    final records = getMaintenanceRecords();
    records.removeWhere((record) => record.id == id);
    await saveMaintenanceRecords(records);
  }

  /// Get all configured fuel types
  List<FuelType> getFuelTypes() {
    final jsonString = _prefs.getString(_fuelTypesKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [
        FuelType(
          id: FuelType.defaultId,
          name: FuelType.defaultName,
          pricePerLiter: _prefs.getDouble(_fuelPriceKey) ?? defaultFuelPrice,
          active: true,
        ),
      ];
    }

    final fuelTypes = FuelType.decodeFuelTypes(jsonString);
    if (fuelTypes.isEmpty) {
      return [
        FuelType(
          id: FuelType.defaultId,
          name: FuelType.defaultName,
          pricePerLiter: _prefs.getDouble(_fuelPriceKey) ?? defaultFuelPrice,
          active: true,
        ),
      ];
    }
    return fuelTypes;
  }

  Future<void> saveFuelTypes(List<FuelType> fuelTypes) async {
    await _prefs.setString(_fuelTypesKey, FuelType.encodeFuelTypes(fuelTypes));
  }

  String getSelectedFuelTypeId() {
    final selected = _prefs.getString(_selectedFuelTypeKey);
    if ((selected ?? '').isNotEmpty) {
      return selected!;
    }

    final fuelTypes = getFuelTypes();
    final active = fuelTypes.where((fuelType) => fuelType.active).toList();
    return active.isNotEmpty ? active.first.id : fuelTypes.first.id;
  }

  Future<void> setSelectedFuelTypeId(String id) async {
    await _prefs.setString(_selectedFuelTypeKey, id);
  }

  /// Backward-compatible getter: returns selected fuel type price.
  double getFuelPrice() {
    final fuelTypes = getFuelTypes();
    final selectedId = getSelectedFuelTypeId();
    final selected =
        fuelTypes.where((fuelType) => fuelType.id == selectedId).toList();

    if (selected.isNotEmpty) {
      return selected.first.pricePerLiter;
    }

    final active = fuelTypes.where((fuelType) => fuelType.active).toList();
    if (active.isNotEmpty) {
      return active.first.pricePerLiter;
    }

    return _prefs.getDouble(_fuelPriceKey) ?? defaultFuelPrice;
  }

  /// Backward-compatible setter: updates selected fuel type price.
  Future<void> setFuelPrice(double price) async {
    final fuelTypes = getFuelTypes();
    final selectedId = getSelectedFuelTypeId();

    bool updated = false;
    final updatedFuelTypes = fuelTypes.map((fuelType) {
      if (fuelType.id == selectedId) {
        updated = true;
        return fuelType.copyWith(pricePerLiter: price);
      }
      return fuelType;
    }).toList();

    if (!updated) {
      updatedFuelTypes.add(
        FuelType(
          id: FuelType.defaultId,
          name: FuelType.defaultName,
          pricePerLiter: price,
          active: true,
        ),
      );
      await setSelectedFuelTypeId(FuelType.defaultId);
    }

    await saveFuelTypes(updatedFuelTypes);
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

  /// Get saved theme mode
  String getThemeMode() {
    return _prefs.getString(_themeModeKey) ?? defaultThemeMode;
  }

  /// Set app theme mode
  Future<void> setThemeMode(String themeMode) async {
    await _prefs.setString(_themeModeKey, themeMode);
  }

  /// Get all vehicles
  List<Vehicle> getVehicles() {
    final jsonString = _prefs.getString(_vehiclesKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    return Vehicle.decodeVehicles(jsonString);
  }

  /// Save all vehicles
  Future<void> saveVehicles(List<Vehicle> vehicles) async {
    final jsonString = Vehicle.encodeVehicles(vehicles);
    await _prefs.setString(_vehiclesKey, jsonString);
  }

  /// Get the selected vehicle ID
  String getSelectedVehicleId() {
    final selected = _prefs.getString(_selectedVehicleKey);
    if (selected != null && selected.isNotEmpty) {
      return selected;
    }

    // Default to first vehicle if none selected
    final vehicles = getVehicles();
    if (vehicles.isNotEmpty) {
      return vehicles.first.id;
    }

    return 'default_vehicle';
  }

  /// Set the selected vehicle
  Future<void> setSelectedVehicle(String vehicleId) async {
    await _prefs.setString(_selectedVehicleKey, vehicleId);
  }

  /// Migrate existing data to support vehicles
  Future<void> _migrateToVehicleSupport() async {
    final vehicles = getVehicles();

    // Only migrate if no vehicles exist but records do
    if (vehicles.isEmpty && getRecords().isNotEmpty) {
      final records = getRecords();

      // Find the latest odometer reading from existing records
      final latestOdometer =
          records.isNotEmpty ? records.first.odometerKm : 0.0;

      // Create default vehicle
      final defaultVehicle = Vehicle(
        id: 'default_vehicle',
        name: 'My Vehicle',
        make: '',
        model: '',
        currentOdometer: latestOdometer,
        isDefault: true,
        active: true,
        createdAt: DateTime.now(),
      );

      await saveVehicles([defaultVehicle]);
      await setSelectedVehicle(defaultVehicle.id);

      // Update all existing records with the default vehicleId
      final updatedRecords = records.map((r) {
        return r.copyWith(vehicleId: defaultVehicle.id);
      }).toList();
      await saveRecords(updatedRecords);
    }
  }
}
