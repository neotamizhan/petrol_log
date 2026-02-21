import 'dart:convert';

class MaintenanceRecord {
  final String id;
  final String vehicleId;
  final String serviceType;
  final String category;
  final DateTime serviceDate;
  final double odometerKm;
  final double cost;
  final String notes;
  final double? nextDueOdometerKm;
  final DateTime? nextDueDate;
  final DateTime createdAt;

  const MaintenanceRecord({
    required this.id,
    required this.vehicleId,
    required this.serviceType,
    this.category = 'general',
    required this.serviceDate,
    required this.odometerKm,
    this.cost = 0,
    this.notes = '',
    this.nextDueOdometerKm,
    this.nextDueDate,
    required this.createdAt,
  });

  bool get hasDueTarget => nextDueOdometerKm != null || nextDueDate != null;

  String get normalizedServiceType => serviceType.trim().toLowerCase();

  String get scheduleKey => '$vehicleId::$normalizedServiceType';

  MaintenanceRecord copyWith({
    String? id,
    String? vehicleId,
    String? serviceType,
    String? category,
    DateTime? serviceDate,
    double? odometerKm,
    double? cost,
    String? notes,
    double? nextDueOdometerKm,
    DateTime? nextDueDate,
    bool clearNextDueOdometerKm = false,
    bool clearNextDueDate = false,
    DateTime? createdAt,
  }) {
    return MaintenanceRecord(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      serviceType: serviceType ?? this.serviceType,
      category: category ?? this.category,
      serviceDate: serviceDate ?? this.serviceDate,
      odometerKm: odometerKm ?? this.odometerKm,
      cost: cost ?? this.cost,
      notes: notes ?? this.notes,
      nextDueOdometerKm: clearNextDueOdometerKm
          ? null
          : nextDueOdometerKm ?? this.nextDueOdometerKm,
      nextDueDate: clearNextDueDate ? null : nextDueDate ?? this.nextDueDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'serviceType': serviceType,
      'category': category,
      'serviceDate': serviceDate.toIso8601String(),
      'odometerKm': odometerKm,
      'cost': cost,
      'notes': notes,
      'nextDueOdometerKm': nextDueOdometerKm,
      'nextDueDate': nextDueDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MaintenanceRecord.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    final parsedServiceDate =
        _parseDate(json['serviceDate'] ?? json['date'], fallback: now);
    final parsedCreatedAt =
        _parseDate(json['createdAt'], fallback: parsedServiceDate);

    final serviceType =
        (json['serviceType'] as String?)?.trim().isNotEmpty == true
            ? (json['serviceType'] as String).trim()
            : 'Service';

    final category = (json['category'] as String?)?.trim().isNotEmpty == true
        ? (json['category'] as String).trim()
        : 'general';

    return MaintenanceRecord(
      id: json['id'] as String,
      vehicleId: (json['vehicleId'] as String?)?.trim().isNotEmpty == true
          ? (json['vehicleId'] as String).trim()
          : 'default_vehicle',
      serviceType: serviceType,
      category: category,
      serviceDate: parsedServiceDate,
      odometerKm: (json['odometerKm'] as num?)?.toDouble() ?? 0,
      cost: (json['cost'] as num?)?.toDouble() ?? 0,
      notes: json['notes'] as String? ?? '',
      nextDueOdometerKm: (json['nextDueOdometerKm'] as num?)?.toDouble(),
      nextDueDate: _parseNullableDate(json['nextDueDate']),
      createdAt: parsedCreatedAt,
    );
  }

  static DateTime _parseDate(dynamic value, {required DateTime fallback}) {
    if (value is String && value.trim().isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return fallback;
      }
    }
    return fallback;
  }

  static DateTime? _parseNullableDate(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static String encodeRecords(List<MaintenanceRecord> records) {
    return jsonEncode(records.map((record) => record.toJson()).toList());
  }

  static List<MaintenanceRecord> decodeRecords(String jsonString) {
    if (jsonString.isEmpty) {
      return [];
    }
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList
        .map((json) => MaintenanceRecord.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
