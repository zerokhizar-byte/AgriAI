class YieldPredictionService {
  Future<YieldPredictionResult> predictYield({
    required String crop,
    required double rainfall,
    required double temperature,
    required double humidity,
    required double soilMoisture,
    required double nitrogen,
    required double phosphorus,
    required double potassium,
    required double fertilizer,
    required double area,
  }) async {
    _validateInput(
      rainfall: rainfall,
      temperature: temperature,
      humidity: humidity,
      soilMoisture: soilMoisture,
      nitrogen: nitrogen,
      phosphorus: phosphorus,
      potassium: potassium,
      fertilizer: fertilizer,
      area: area,
    );

    /*
     * Temporary development calculation.
     *
     * This is NOT the final ML prediction.
     * The trained crop-yield model will replace this calculation.
     */

    double baseYield;

    switch (crop.toLowerCase()) {
      case 'rice':
        baseYield = 2.8;
        break;
      case 'wheat':
        baseYield = 3.1;
        break;
      case 'maize':
        baseYield = 3.5;
        break;
      case 'cotton':
        baseYield = 1.8;
        break;
      case 'sugarcane':
        baseYield = 70.0;
        break;
      default:
        baseYield = 2.5;
    }

    double score = 1.0;

    if (rainfall >= 400 && rainfall <= 1200) {
      score += 0.10;
    } else if (rainfall < 200) {
      score -= 0.15;
    }

    if (temperature >= 18 && temperature <= 32) {
      score += 0.08;
    }

    if (humidity >= 40 && humidity <= 80) {
      score += 0.05;
    }

    if (soilMoisture >= 30 && soilMoisture <= 70) {
      score += 0.08;
    }

    final nutrientScore =
        (nitrogen + phosphorus + potassium) / 300;

    score += nutrientScore.clamp(0.0, 0.20);

    if (fertilizer > 0) {
      score += 0.05;
    }

    final predictedYield = baseYield * score;

    final confidence = _calculateConfidence(
      rainfall: rainfall,
      temperature: temperature,
      humidity: humidity,
      soilMoisture: soilMoisture,
      nitrogen: nitrogen,
      phosphorus: phosphorus,
      potassium: potassium,
    );

    return YieldPredictionResult(
      crop: crop,
      predictedYield: predictedYield,
      unit: 'tonnes/hectare',
      confidence: confidence,
      area: area,
      totalEstimatedProduction: predictedYield * area,
    );
  }

  double _calculateConfidence({
    required double rainfall,
    required double temperature,
    required double humidity,
    required double soilMoisture,
    required double nitrogen,
    required double phosphorus,
    required double potassium,
  }) {
    double score = 60.0;

    if (rainfall >= 400 && rainfall <= 1200) {
      score += 8;
    }

    if (temperature >= 18 && temperature <= 32) {
      score += 8;
    }

    if (humidity >= 40 && humidity <= 80) {
      score += 5;
    }

    if (soilMoisture >= 30 && soilMoisture <= 70) {
      score += 7;
    }

    if (nitrogen > 0 &&
        phosphorus > 0 &&
        potassium > 0) {
      score += 7;
    }

    return score.clamp(0.0, 99.0);
  }

  void _validateInput({
    required double rainfall,
    required double temperature,
    required double humidity,
    required double soilMoisture,
    required double nitrogen,
    required double phosphorus,
    required double potassium,
    required double fertilizer,
    required double area,
  }) {
    if (rainfall < 0) {
      throw const YieldPredictionException(
        'Rainfall cannot be negative.',
      );
    }

    if (humidity < 0 || humidity > 100) {
      throw const YieldPredictionException(
        'Humidity must be between 0 and 100%.',
      );
    }

    if (soilMoisture < 0 || soilMoisture > 100) {
      throw const YieldPredictionException(
        'Soil moisture must be between 0 and 100%.',
      );
    }

    if (nitrogen < 0) {
      throw const YieldPredictionException(
        'Nitrogen value cannot be negative.',
      );
    }

    if (phosphorus < 0) {
      throw const YieldPredictionException(
        'Phosphorus value cannot be negative.',
      );
    }

    if (potassium < 0) {
      throw const YieldPredictionException(
        'Potassium value cannot be negative.',
      );
    }

    if (fertilizer < 0) {
      throw const YieldPredictionException(
        'Fertilizer value cannot be negative.',
      );
    }

    if (area <= 0) {
      throw const YieldPredictionException(
        'Farm area must be greater than zero.',
      );
    }

    if (temperature < -50 || temperature > 70) {
      throw const YieldPredictionException(
        'Temperature value is outside the valid range.',
      );
    }
  }
}

class YieldPredictionResult {
  final String crop;
  final double predictedYield;
  final String unit;
  final double confidence;
  final double area;
  final double totalEstimatedProduction;

  const YieldPredictionResult({
    required this.crop,
    required this.predictedYield,
    required this.unit,
    required this.confidence,
    required this.area,
    required this.totalEstimatedProduction,
  });

  factory YieldPredictionResult.fromJson(
    Map<String, dynamic> json,
  ) {
    return YieldPredictionResult(
      crop: json['crop']?.toString() ?? '',
      predictedYield: _toDouble(
        json['predictedYield'],
      ),
      unit: json['unit']?.toString() ??
          'tonnes/hectare',
      confidence: _toDouble(
        json['confidence'],
      ),
      area: _toDouble(
        json['area'],
      ),
      totalEstimatedProduction: _toDouble(
        json['totalEstimatedProduction'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'crop': crop,
      'predictedYield': predictedYield,
      'unit': unit,
      'confidence': confidence,
      'area': area,
      'totalEstimatedProduction':
          totalEstimatedProduction,
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

class YieldPredictionException implements Exception {
  final String message;

  const YieldPredictionException(this.message);

  @override
  String toString() => message;
}