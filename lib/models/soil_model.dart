class SoilModel {
  final double moisture;
  final double ph;
  final double nitrogen;
  final double phosphorus;
  final double potassium;
  final double temperature;
  final String status;
  final DateTime? recordedAt;

  const SoilModel({
    required this.moisture,
    required this.ph,
    required this.nitrogen,
    required this.phosphorus,
    required this.potassium,
    required this.temperature,
    required this.status,
    this.recordedAt,
  });

  SoilModel copyWith({
    double? moisture,
    double? ph,
    double? nitrogen,
    double? phosphorus,
    double? potassium,
    double? temperature,
    String? status,
    DateTime? recordedAt,
  }) {
    return SoilModel(
      moisture: moisture ?? this.moisture,
      ph: ph ?? this.ph,
      nitrogen: nitrogen ?? this.nitrogen,
      phosphorus: phosphorus ?? this.phosphorus,
      potassium: potassium ?? this.potassium,
      temperature: temperature ?? this.temperature,
      status: status ?? this.status,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }

  factory SoilModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return SoilModel(
      moisture: _toDouble(json['moisture']),
      ph: _toDouble(json['ph']),
      nitrogen: _toDouble(json['nitrogen']),
      phosphorus: _toDouble(json['phosphorus']),
      potassium: _toDouble(json['potassium']),
      temperature: _toDouble(json['temperature']),
      status: json['status']?.toString() ?? 'Unknown',
      recordedAt: _parseDate(json['recordedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'moisture': moisture,
      'ph': ph,
      'nitrogen': nitrogen,
      'phosphorus': phosphorus,
      'potassium': potassium,
      'temperature': temperature,
      'status': status,
      'recordedAt': recordedAt?.toIso8601String(),
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

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }

  bool get isMoistureLow => moisture < 30;

  bool get isMoistureHigh => moisture > 80;

  bool get isPhAcidic => ph < 5.5;

  bool get isPhAlkaline => ph > 8.0;

  bool get hasLowNitrogen => nitrogen < 30;

  bool get hasLowPhosphorus => phosphorus < 20;

  bool get hasLowPotassium => potassium < 20;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is SoilModel &&
        other.moisture == moisture &&
        other.ph == ph &&
        other.nitrogen == nitrogen &&
        other.phosphorus == phosphorus &&
        other.potassium == potassium &&
        other.temperature == temperature;
  }

  @override
  int get hashCode {
    return Object.hash(
      moisture,
      ph,
      nitrogen,
      phosphorus,
      potassium,
      temperature,
    );
  }
}