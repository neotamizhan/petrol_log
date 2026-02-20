import 'dart:convert';

class Vehicle {
  final String id;
  final String name;
  final String make;
  final String model;
  final int? year;
  final String? plateNumber;
  final double currentOdometer;
  final bool isDefault;
  final bool active;
  final DateTime createdAt;

  const Vehicle({
    required this.id,
    required this.name,
    this.make = '',
    this.model = '',
    this.year,
    this.plateNumber,
    required this.currentOdometer,
    this.isDefault = false,
    this.active = true,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'make': make,
      'model': model,
      'year': year,
      'plateNumber': plateNumber,
      'currentOdometer': currentOdometer,
      'isDefault': isDefault,
      'active': active,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as String,
      name: json['name'] as String,
      make: json['make'] as String? ?? '',
      model: json['model'] as String? ?? '',
      year: json['year'] as int?,
      plateNumber: json['plateNumber'] as String?,
      currentOdometer: (json['currentOdometer'] as num).toDouble(),
      isDefault: json['isDefault'] as bool? ?? false,
      active: json['active'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Vehicle copyWith({
    String? id,
    String? name,
    String? make,
    String? model,
    int? year,
    String? plateNumber,
    double? currentOdometer,
    bool? isDefault,
    bool? active,
    DateTime? createdAt,
  }) {
    return Vehicle(
      id: id ?? this.id,
      name: name ?? this.name,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      plateNumber: plateNumber ?? this.plateNumber,
      currentOdometer: currentOdometer ?? this.currentOdometer,
      isDefault: isDefault ?? this.isDefault,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static String encodeVehicles(List<Vehicle> vehicles) {
    return jsonEncode(vehicles.map((v) => v.toJson()).toList());
  }

  static List<Vehicle> decodeVehicles(String vehiclesJson) {
    if (vehiclesJson.isEmpty) return [];
    final List<dynamic> decoded = jsonDecode(vehiclesJson);
    return decoded.map((json) => Vehicle.fromJson(json)).toList();
  }

  @override
  String toString() {
    return 'Vehicle(id: $id, name: $name, make: $make, model: $model, year: $year, plateNumber: $plateNumber, currentOdometer: $currentOdometer, isDefault: $isDefault, active: $active)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Vehicle && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
