class RecommendationService {
  Future<List<Recommendation>> getRecommendations({
    required double soilMoisture,
    required double soilPh,
    required double nitrogen,
    required double phosphorus,
    required double potassium,
    required double temperature,
    required double rainfall,
    String? crop,
  }) async {
    final recommendations = <Recommendation>[];

    _addIrrigationRecommendation(
      recommendations,
      soilMoisture,
      rainfall,
    );

    _addSoilPhRecommendation(
      recommendations,
      soilPh,
    );

    _addNitrogenRecommendation(
      recommendations,
      nitrogen,
    );

    _addPhosphorusRecommendation(
      recommendations,
      phosphorus,
    );

    _addPotassiumRecommendation(
      recommendations,
      potassium,
    );

    _addWeatherRecommendation(
      recommendations,
      temperature,
      rainfall,
    );

    if (recommendations.isEmpty) {
      recommendations.add(
        const Recommendation(
          type: RecommendationType.general,
          title: 'Farm conditions look good',
          description:
              'Current soil and weather conditions are within the expected range. Continue regular monitoring.',
          priority: RecommendationPriority.low,
        ),
      );
    }

    return recommendations;
  }

  void _addIrrigationRecommendation(
    List<Recommendation> recommendations,
    double soilMoisture,
    double rainfall,
  ) {
    if (soilMoisture < 30 && rainfall < 10) {
      recommendations.add(
        const Recommendation(
          type: RecommendationType.irrigation,
          title: 'Irrigation recommended',
          description:
              'Soil moisture is low and recent rainfall is limited. Consider irrigating the crop.',
          priority: RecommendationPriority.high,
        ),
      );
    } else if (soilMoisture > 80) {
      recommendations.add(
        const Recommendation(
          type: RecommendationType.irrigation,
          title: 'Reduce irrigation',
          description:
              'Soil moisture is high. Avoid unnecessary irrigation to reduce the risk of waterlogging.',
          priority: RecommendationPriority.high,
        ),
      );
    } else {
      recommendations.add(
        const Recommendation(
          type: RecommendationType.irrigation,
          title: 'Irrigation level is suitable',
          description:
              'Current soil moisture is within a suitable range. Continue monitoring the field.',
          priority: RecommendationPriority.low,
        ),
      );
    }
  }

  void _addSoilPhRecommendation(
    List<Recommendation> recommendations,
    double soilPh,
  ) {
    if (soilPh < 5.5) {
      recommendations.add(
        const Recommendation(
          type: RecommendationType.soil,
          title: 'Soil is acidic',
          description:
              'The soil pH is low. Consider appropriate soil amendments after soil testing and local agronomic advice.',
          priority: RecommendationPriority.medium,
        ),
      );
    } else if (soilPh > 8.0) {
      recommendations.add(
        const Recommendation(
          type: RecommendationType.soil,
          title: 'Soil is alkaline',
          description:
              'The soil pH is high. Consider suitable soil management practices based on a soil test.',
          priority: RecommendationPriority.medium,
        ),
      );
    }
  }

  void _addNitrogenRecommendation(
    List<Recommendation> recommendations,
    double nitrogen,
  ) {
    if (nitrogen < 30) {
      recommendations.add(
        const Recommendation(
          type: RecommendationType.fertilizer,
          title: 'Nitrogen may be low',
          description:
              'The available nitrogen value is low. Consider a soil-test-based nitrogen management plan.',
          priority: RecommendationPriority.medium,
        ),
      );
    }
  }

  void _addPhosphorusRecommendation(
    List<Recommendation> recommendations,
    double phosphorus,
  ) {
    if (phosphorus < 20) {
      recommendations.add(
        const Recommendation(
          type: RecommendationType.fertilizer,
          title: 'Phosphorus may be low',
          description:
              'The available phosphorus value is low. Consider phosphorus management based on soil-test results.',
          priority: RecommendationPriority.medium,
        ),
      );
    }
  }

  void _addPotassiumRecommendation(
    List<Recommendation> recommendations,
    double potassium,
  ) {
    if (potassium < 20) {
      recommendations.add(
        const Recommendation(
          type: RecommendationType.fertilizer,
          title: 'Potassium may be low',
          description:
              'The available potassium value is low. Consider potassium management based on soil-test results.',
          priority: RecommendationPriority.medium,
        ),
      );
    }
  }

  void _addWeatherRecommendation(
    List<Recommendation> recommendations,
    double temperature,
    double rainfall,
  ) {
    if (temperature > 35) {
      recommendations.add(
        const Recommendation(
          type: RecommendationType.weather,
          title: 'High temperature alert',
          description:
              'High temperature may increase crop water demand. Monitor soil moisture and crop stress.',
          priority: RecommendationPriority.medium,
        ),
      );
    }

    if (rainfall > 100) {
      recommendations.add(
        const Recommendation(
          type: RecommendationType.weather,
          title: 'Heavy rainfall monitoring',
          description:
              'Recent rainfall is high. Check field drainage and monitor crops for excess moisture.',
          priority: RecommendationPriority.medium,
        ),
      );
    }
  }
}

enum RecommendationType {
  irrigation,
  fertilizer,
  soil,
  weather,
  crop,
  general,
}

enum RecommendationPriority {
  low,
  medium,
  high,
}

class Recommendation {
  final RecommendationType type;
  final String title;
  final String description;
  final RecommendationPriority priority;

  const Recommendation({
    required this.type,
    required this.title,
    required this.description,
    required this.priority,
  });

  factory Recommendation.fromJson(
    Map<String, dynamic> json,
  ) {
    return Recommendation(
      type: _parseType(
        json['type']?.toString(),
      ),
      title: json['title']?.toString() ?? '',
      description:
          json['description']?.toString() ?? '',
      priority: _parsePriority(
        json['priority']?.toString(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'title': title,
      'description': description,
      'priority': priority.name,
    };
  }

  static RecommendationType _parseType(
    String? value,
  ) {
    return RecommendationType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => RecommendationType.general,
    );
  }

  static RecommendationPriority _parsePriority(
    String? value,
  ) {
    return RecommendationPriority.values.firstWhere(
      (priority) => priority.name == value,
      orElse: () => RecommendationPriority.low,
    );
  }
}