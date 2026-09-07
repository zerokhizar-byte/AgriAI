class DashboardModel {
  final String greeting;
  final WeatherSummary weather;
  final SoilSummaryData soil;
  final CropHealthSummary cropHealth;
  final YieldSummary yield;
  final int unreadNotifications;

  const DashboardModel({
    required this.greeting,
    required this.weather,
    required this.soil,
    required this.cropHealth,
    required this.yield,
    this.unreadNotifications = 0,
  });

  DashboardModel copyWith({
    String? greeting,
    WeatherSummary? weather,
    SoilSummaryData? soil,
    CropHealthSummary? cropHealth,
    YieldSummary? yield,
    int? unreadNotifications,
  }) {
    return DashboardModel(
      greeting: greeting ?? this.greeting,
      weather: weather ?? this.weather,
      soil: soil ?? this.soil,
      cropHealth: cropHealth ?? this.cropHealth,
      yield: yield ?? this.yield,
      unreadNotifications:
          unreadNotifications ?? this.unreadNotifications,
    );
  }

  factory DashboardModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return DashboardModel(
      greeting:
          json['greeting']?.toString() ??
              'Good morning, Farmer',
      weather: WeatherSummary.fromJson(
        _map(json['weather']),
      ),
      soil: SoilSummaryData.fromJson(
        _map(json['soil']),
      ),
      cropHealth: CropHealthSummary.fromJson(
        _map(json['cropHealth']),
      ),
      yield: YieldSummary.fromJson(
        _map(json['yield']),
      ),
      unreadNotifications:
          _toInt(json['unreadNotifications']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'greeting': greeting,
      'weather': weather.toJson(),
      'soil': soil.toJson(),
      'cropHealth': cropHealth.toJson(),
      'yield': yield.toJson(),
      'unreadNotifications': unreadNotifications,
    };
  }

  static Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    return <String, dynamic>{};
  }

  static int _toInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }
}

class WeatherSummary {
  final double temperature;
  final String condition;
  final String location;
  final String icon;

  const WeatherSummary({
    required this.temperature,
    required this.condition,
    required this.location,
    required this.icon,
  });

  factory WeatherSummary.fromJson(
    Map<String, dynamic> json,
  ) {
    return WeatherSummary(
      temperature: _toDouble(
        json['temperature'],
      ),
      condition:
          json['condition']?.toString() ??
              'Clear',
      location:
          json['location']?.toString() ??
              'Current Location',
      icon:
          json['icon']?.toString() ??
              'sunny',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'condition': condition,
      'location': location,
      'icon': icon,
    };
  }

  String get temperatureDisplay =>
      '${temperature.toStringAsFixed(0)}°C';

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

class SoilSummaryData {
  final String status;
  final double moisture;
  final double ph;

  const SoilSummaryData({
    required this.status,
    required this.moisture,
    required this.ph,
  });

  factory SoilSummaryData.fromJson(
    Map<String, dynamic> json,
  ) {
    return SoilSummaryData(
      status:
          json['status']?.toString() ??
              'Good',
      moisture: _toDouble(
        json['moisture'],
      ),
      ph: _toDouble(
        json['ph'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'moisture': moisture,
      'ph': ph,
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

class CropHealthSummary {
  final String status;
  final double score;
  final String cropName;

  const CropHealthSummary({
    required this.status,
    required this.score,
    required this.cropName,
  });

  factory CropHealthSummary.fromJson(
    Map<String, dynamic> json,
  ) {
    return CropHealthSummary(
      status:
          json['status']?.toString() ??
              'Healthy',
      score: _toDouble(
        json['score'],
      ),
      cropName:
          json['cropName']?.toString() ??
              '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'score': score,
      'cropName': cropName,
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

class YieldSummary {
  final double predictedYield;
  final String unit;
  final double confidence;
  final String cropName;

  const YieldSummary({
    required this.predictedYield,
    required this.unit,
    required this.confidence,
    required this.cropName,
  });

  factory YieldSummary.fromJson(
    Map<String, dynamic> json,
  ) {
    return YieldSummary(
      predictedYield: _toDouble(
        json['predictedYield'],
      ),
      unit:
          json['unit']?.toString() ??
              'tonnes/hectare',
      confidence: _toDouble(
        json['confidence'],
      ),
      cropName:
          json['cropName']?.toString() ??
              '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'predictedYield': predictedYield,
      'unit': unit,
      'confidence': confidence,
      'cropName': cropName,
    };
  }

  double get confidencePercentage {
    if (confidence <= 1) {
      return confidence * 100;
    }

    return confidence;
  }

  String get yieldDisplay {
    return '${predictedYield.toStringAsFixed(2)} $unit';
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