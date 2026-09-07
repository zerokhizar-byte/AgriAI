class WeatherModel {
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final double rainfall;
  final String condition;
  final String location;
  final String weatherIcon;
  final DateTime? updatedAt;

  const WeatherModel({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.rainfall,
    required this.condition,
    required this.location,
    required this.weatherIcon,
    this.updatedAt,
  });

  WeatherModel copyWith({
    double? temperature,
    double? feelsLike,
    int? humidity,
    double? windSpeed,
    double? rainfall,
    String? condition,
    String? location,
    String? weatherIcon,
    DateTime? updatedAt,
  }) {
    return WeatherModel(
      temperature: temperature ?? this.temperature,
      feelsLike: feelsLike ?? this.feelsLike,
      humidity: humidity ?? this.humidity,
      windSpeed: windSpeed ?? this.windSpeed,
      rainfall: rainfall ?? this.rainfall,
      condition: condition ?? this.condition,
      location: location ?? this.location,
      weatherIcon: weatherIcon ?? this.weatherIcon,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory WeatherModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return WeatherModel(
      temperature: _toDouble(
        json['temperature'],
      ),
      feelsLike: _toDouble(
        json['feelsLike'],
      ),
      humidity: _toInt(
        json['humidity'],
      ),
      windSpeed: _toDouble(
        json['windSpeed'],
      ),
      rainfall: _toDouble(
        json['rainfall'],
      ),
      condition:
          json['condition']?.toString() ?? 'Unknown',
      location:
          json['location']?.toString() ?? 'Unknown',
      weatherIcon:
          json['weatherIcon']?.toString() ?? 'cloudy',
      updatedAt: _parseDate(
        json['updatedAt'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'feelsLike': feelsLike,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'rainfall': rainfall,
      'condition': condition,
      'location': location,
      'weatherIcon': weatherIcon,
      'updatedAt': updatedAt?.toIso8601String(),
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

  static int _toInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }

  String get temperatureDisplay =>
      '${temperature.toStringAsFixed(0)}°C';

  String get humidityDisplay =>
      '$humidity%';

  String get windSpeedDisplay =>
      '${windSpeed.toStringAsFixed(1)} km/h';

  String get rainfallDisplay =>
      '${rainfall.toStringAsFixed(1)} mm';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is WeatherModel &&
        other.temperature == temperature &&
        other.feelsLike == feelsLike &&
        other.humidity == humidity &&
        other.windSpeed == windSpeed &&
        other.rainfall == rainfall &&
        other.condition == condition &&
        other.location == location;
  }

  @override
  int get hashCode {
    return Object.hash(
      temperature,
      feelsLike,
      humidity,
      windSpeed,
      rainfall,
      condition,
      location,
    );
  }
}