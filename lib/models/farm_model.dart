class FarmModel {
  final String id;
  final String name;
  final String location;
  final double area;
  final String areaUnit;
  final String? cropName;
  final SoilSummary? soil;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FarmModel({
    required this.id,
    required this.name,
    required this.location,
    required this.area,
    this.areaUnit = 'hectare',
    this.cropName,
    this.soil,
    this.createdAt,
    this.updatedAt,
  });

  FarmModel copyWith({
    String? id,
    String? name,
    String? location,
    double? area,
    String? areaUnit,
    String? cropName,
    SoilSummary? soil,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FarmModel(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      area: area ?? this.area,
      areaUnit: areaUnit ?? this.areaUnit,
      cropName: cropName ?? this.cropName,
      soil: soil ?? this.soil,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory FarmModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return FarmModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      area: _toDouble(json['area']),
      areaUnit:
          json['areaUnit']?.toString() ?? 'hectare',
      cropName: json['cropName']?.toString(),
      soil: json['soil'] is Map<String, dynamic>
          ? SoilSummary.fromJson(
              json['soil'] as Map<String, dynamic>,
            )
          : null,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'area': area,
      'areaUnit': areaUnit,
      'cropName': cropName,
      'soil': soil?.toJson(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  String get areaDisplay {
    return '${area.toStringAsFixed(2)} $areaUnit';
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0.0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is FarmModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class SoilSummary {
  final double moisture;
  final double ph;
  final double nitrogen;
  final double phosphorus;
  final double potassium;

  const SoilSummary({
    required this.moisture,
    required this.ph,
    required this.nitrogen,
    required this.phosphorus,
    required this.potassium,
  });

  factory SoilSummary.fromJson(
    Map<String, dynamic> json,
  ) {
    return SoilSummary(
      moisture: _toDouble(json['moisture']),
      ph: _toDouble(json['ph']),
      nitrogen: _toDouble(json['nitrogen']),
      phosphorus: _toDouble(json['phosphorus']),
      potassium: _toDouble(json['potassium']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'moisture': moisture,
      'ph': ph,
      'nitrogen': nitrogen,
      'phosphorus': phosphorus,
      'potassium': potassium,
    };
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0.0;
  }
}