import 'api_service.dart';

class WeatherService {
  final ApiService _apiService;

  WeatherService({
    ApiService? apiService,
  }) : _apiService = apiService ?? ApiService();

  Future<WeatherData> getWeather({
    required double latitude,
    required double longitude,
  }) async {
    // Real weather API integration will be connected here.
    //
    // The service currently returns safe placeholder data so the
    // application can be developed and tested without requiring
    // an API key.

    return WeatherData(
      temperature: 28.0,
      feelsLike: 29.0,
      humidity: 62,
      windSpeed: 12.0,
      rainfall: 0.0,
      condition: 'Clear',
      location: 'Current Location',
      weatherIcon: 'sunny',
    );
  }

  Future<WeatherData> getWeatherByCity(
    String city,
  ) async {
    // Real city-based weather API integration will be connected here.

    return WeatherData(
      temperature: 28.0,
      feelsLike: 29.0,
      humidity: 62,
      windSpeed: 12.0,
      rainfall: 0.0,
      condition: 'Clear',
      location: city,
      weatherIcon: 'sunny',
    );
  }

  Future<List<WeatherForecast>> getForecast({
    required double latitude,
    required double longitude,
  }) async {
    // Placeholder forecast data for development.

    return [
      WeatherForecast(
        day: 'Today',
        temperature: 28.0,
        condition: 'Clear',
        weatherIcon: 'sunny',
      ),
      WeatherForecast(
        day: 'Tomorrow',
        temperature: 29.0,
        condition: 'Partly Cloudy',
        weatherIcon: 'partly_cloudy',
      ),
      WeatherForecast(
        day: 'Day 3',
        temperature: 27.0,
        condition: 'Cloudy',
        weatherIcon: 'cloudy',
      ),
      WeatherForecast(
        day: 'Day 4',
        temperature: 26.0,
        condition: 'Light Rain',
        weatherIcon: 'rain',
      ),
      WeatherForecast(
        day: 'Day 5',
        temperature: 28.0,
        condition: 'Clear',
        weatherIcon: 'sunny',
      ),
    ];
  }

  void dispose() {
    _apiService.dispose();
  }
}

class WeatherData {
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final double rainfall;
  final String condition;
  final String location;
  final String weatherIcon;

  const WeatherData({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.rainfall,
    required this.condition,
    required this.location,
    required this.weatherIcon,
  });

  factory WeatherData.fromJson(
    Map<String, dynamic> json,
  ) {
    return WeatherData(
      temperature:
          _toDouble(json['temperature']),
      feelsLike:
          _toDouble(json['feelsLike']),
      humidity:
          _toInt(json['humidity']),
      windSpeed:
          _toDouble(json['windSpeed']),
      rainfall:
          _toDouble(json['rainfall']),
      condition:
          json['condition']?.toString() ?? 'Unknown',
      location:
          json['location']?.toString() ?? 'Unknown',
      weatherIcon:
          json['weatherIcon']?.toString() ?? 'cloudy',
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
}

class WeatherForecast {
  final String day;
  final double temperature;
  final String condition;
  final String weatherIcon;

  const WeatherForecast({
    required this.day,
    required this.temperature,
    required this.condition,
    required this.weatherIcon,
  });

  factory WeatherForecast.fromJson(
    Map<String, dynamic> json,
  ) {
    return WeatherForecast(
      day: json['day']?.toString() ?? '',
      temperature: _toDouble(
        json['temperature'],
      ),
      condition:
          json['condition']?.toString() ?? 'Unknown',
      weatherIcon:
          json['weatherIcon']?.toString() ?? 'cloudy',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'temperature': temperature,
      'condition': condition,
      'weatherIcon': weatherIcon,
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