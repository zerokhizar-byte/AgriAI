class YieldPredictionModel {
  final String id;
  final String crop;
  final double predictedYield;
  final String yieldUnit;
  final double confidence;
  final double farmArea;
  final double totalProduction;
  final DateTime? predictedAt;

  const YieldPredictionModel({
    required this.id,
    required this.crop,
    required this.predictedYield,
    required this.yieldUnit,
    required this.confidence,
    required this.farmArea,
    required this.totalProduction,
    this.predictedAt,
  });

  YieldPredictionModel copyWith({
    String? id,
    String? crop,
    double? predictedYield,
    String? yieldUnit,
    double? confidence,
    double? farmArea,
    double? totalProduction,
    DateTime? predictedAt,
  }) {
    return YieldPredictionModel(
      id: id ?? this.id,
      crop: crop ?? this.crop,
      predictedYield:
          predictedYield ?? this.predictedYield,
      yieldUnit: yieldUnit ?? this.yieldUnit,
      confidence: confidence ?? this.confidence,
      farmArea: farmArea ?? this.farmArea,
      totalProduction:
          totalProduction ?? this.totalProduction,
      predictedAt: predictedAt ?? this.predictedAt,
    );
  }

  factory YieldPredictionModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return YieldPredictionModel(
      id: json['id']?.toString() ?? '',
      crop: json['crop']?.toString() ?? '',
      predictedYield: _toDouble(
        json['predictedYield'],
      ),
      yieldUnit:
          json['yieldUnit']?.toString() ??
              'tonnes/hectare',
      confidence: _toDouble(
        json['confidence'],
      ),
      farmArea: _toDouble(
        json['farmArea'],
      ),
      totalProduction: _toDouble(
        json['totalProduction'],
      ),
      predictedAt: _parseDate(
        json['predictedAt'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'crop': crop,
      'predictedYield': predictedYield,
      'yieldUnit': yieldUnit,
      'confidence': confidence,
      'farmArea': farmArea,
      'totalProduction': totalProduction,
      'predictedAt':
          predictedAt?.toIso8601String(),
    };
  }

  double get confidencePercentage {
    if (confidence <= 1) {
      return confidence * 100;
    }

    return confidence;
  }

  String get confidenceDisplay {
    return '${confidencePercentage.toStringAsFixed(1)}%';
  }

  String get yieldDisplay {
    return '${predictedYield.toStringAsFixed(2)} $yieldUnit';
  }

  String get productionDisplay {
    return '${totalProduction.toStringAsFixed(2)} tonnes';
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

    return other is YieldPredictionModel &&
        other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}