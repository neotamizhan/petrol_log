import 'dart:convert';

class FuelType {
  static const String defaultId = 'regular';
  static const String defaultName = 'Regular';
  static const String defaultCurrency = '₹';

  final String id;
  final String name;
  final double pricePerLiter;
  final String currency;
  final bool active;

  const FuelType({
    required this.id,
    required this.name,
    required this.pricePerLiter,
    this.currency = defaultCurrency,
    this.active = true,
  });

  FuelType copyWith({
    String? id,
    String? name,
    double? pricePerLiter,
    String? currency,
    bool? active,
  }) {
    return FuelType(
      id: id ?? this.id,
      name: name ?? this.name,
      pricePerLiter: pricePerLiter ?? this.pricePerLiter,
      currency: currency ?? this.currency,
      active: active ?? this.active,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'pricePerLiter': pricePerLiter,
      'currency': currency,
      'active': active,
    };
  }

  factory FuelType.fromJson(Map<String, dynamic> json) {
    return FuelType(
      id: (json['id'] as String?)?.trim().isNotEmpty == true
          ? (json['id'] as String).trim()
          : defaultId,
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? (json['name'] as String).trim()
          : defaultName,
      pricePerLiter: (json['pricePerLiter'] as num?)?.toDouble() ?? 0,
      currency: (json['currency'] as String?)?.trim().isNotEmpty == true
          ? (json['currency'] as String).trim()
          : defaultCurrency,
      active: json['active'] as bool? ?? true,
    );
  }

  static String normalizeId(String rawName) {
    final sanitized = rawName
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return sanitized.isEmpty ? defaultId : sanitized;
  }

  static String encodeFuelTypes(List<FuelType> fuelTypes) {
    return jsonEncode(fuelTypes.map((fuelType) => fuelType.toJson()).toList());
  }

  static List<FuelType> decodeFuelTypes(String jsonString) {
    if (jsonString.isEmpty) {
      return [];
    }

    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList
        .map((json) => FuelType.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
