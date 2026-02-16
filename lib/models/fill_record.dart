import 'dart:convert';
import 'fuel_type.dart';

class FillRecord {
  final String id;
  final DateTime date;
  final double odometerKm;
  final double cost;
  final String notes;
  final String fuelTypeId;

  FillRecord({
    required this.id,
    required this.date,
    required this.odometerKm,
    required this.cost,
    this.notes = '',
    this.fuelTypeId = FuelType.defaultId,
  });

  FillRecord copyWith({
    String? id,
    DateTime? date,
    double? odometerKm,
    double? cost,
    String? notes,
    String? fuelTypeId,
  }) {
    return FillRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      odometerKm: odometerKm ?? this.odometerKm,
      cost: cost ?? this.cost,
      notes: notes ?? this.notes,
      fuelTypeId: fuelTypeId ?? this.fuelTypeId,
    );
  }

  /// Calculate distance traveled since the previous fill
  double getDistanceSinceLastFill(FillRecord? previousRecord) {
    if (previousRecord == null) return 0;
    return odometerKm - previousRecord.odometerKm;
  }

  /// Calculate fuel added in liters (cost / price per liter)
  double getFuelAddedLiters(double pricePerLiter) {
    if (pricePerLiter <= 0) return 0;
    return cost / pricePerLiter;
  }

  /// Calculate mileage (km per liter)
  double getMileage(FillRecord? previousRecord, double pricePerLiter) {
    final distance = getDistanceSinceLastFill(previousRecord);
    final fuelAdded = getFuelAddedLiters(pricePerLiter);
    if (fuelAdded <= 0) return 0;
    return distance / fuelAdded;
  }

  /// Calculate days since last fill
  int getDaysSinceLastFill(FillRecord? previousRecord) {
    if (previousRecord == null) return 0;
    return date.difference(previousRecord.date).inDays;
  }

  /// Convert to JSON map for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'odometerKm': odometerKm,
      'cost': cost,
      'notes': notes,
      'fuelTypeId': fuelTypeId,
    };
  }

  /// Create from JSON map
  factory FillRecord.fromJson(Map<String, dynamic> json) {
    return FillRecord(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      odometerKm: (json['odometerKm'] as num).toDouble(),
      cost: (json['cost'] as num).toDouble(),
      notes: json['notes'] as String? ?? '',
      fuelTypeId: (json['fuelTypeId'] as String?)?.trim().isNotEmpty == true
          ? (json['fuelTypeId'] as String).trim()
          : FuelType.defaultId,
    );
  }

  /// Encode list of records to JSON string
  static String encodeRecords(List<FillRecord> records) {
    return jsonEncode(records.map((r) => r.toJson()).toList());
  }

  /// Decode JSON string to list of records
  static List<FillRecord> decodeRecords(String jsonString) {
    if (jsonString.isEmpty) return [];
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => FillRecord.fromJson(json)).toList();
  }

  @override
  String toString() {
    return 'FillRecord(id: $id, date: $date, odometerKm: $odometerKm, cost: $cost, fuelTypeId: $fuelTypeId, notes: $notes)';
  }
}
