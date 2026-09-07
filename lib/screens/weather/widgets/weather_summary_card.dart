import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../models/weather_model.dart';

class WeatherSummaryCard extends StatelessWidget {
  final WeatherModel weather;

  const WeatherSummaryCard({
    super.key,
    required this.weather,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.82),
          ],
        ),
        borderRadius: BorderRadius.circular(
          AppDimensions.radius22,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(
              alpha: 0.18,
            ),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _locationName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const Icon(
                Icons.wb_sunny_outlined,
                size: 22,
                color: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      _temperature,
                      style: const TextStyle(
                        fontSize: 48,
                        height: 0.95,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(
                        top: 3,
                      ),
                      child: Text(
                        '°C',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.14,
                  ),
                  borderRadius:
                      BorderRadius.circular(18),
                ),
                child: Icon(
                  _weatherIcon,
                  size: 34,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _condition,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            height: 1,
            color: Colors.white.withValues(
              alpha: 0.18,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _WeatherMetric(
                  icon: Icons.water_drop_outlined,
                  label: 'Humidity',
                  value: _humidity,
                ),
              ),
              Expanded(
                child: _WeatherMetric(
                  icon: Icons.air_rounded,
                  label: 'Wind',
                  value: _windSpeed,
                ),
              ),
              Expanded(
                child: _WeatherMetric(
                  icon: Icons.umbrella_outlined,
                  label: 'Rain',
                  value: _rainfall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String get _temperature {
    final value = _readDouble([
      _valueFromModel('temperature'),
      _valueFromModel('temp'),
    ]);

    return value == null
        ? '--'
        : value.toStringAsFixed(0);
  }

  String get _humidity {
    final value = _readDouble([
      _valueFromModel('humidity'),
    ]);

    return value == null
        ? '--'
        : '${value.toStringAsFixed(0)}%';
  }

  String get _windSpeed {
    final value = _readDouble([
      _valueFromModel('windSpeed'),
      _valueFromModel('wind'),
    ]);

    return value == null
        ? '--'
        : '${value.toStringAsFixed(1)} km/h';
  }

  String get _rainfall {
    final value = _readDouble([
      _valueFromModel('rainfall'),
      _valueFromModel('rain'),
      _valueFromModel('precipitation'),
    ]);

    return value == null
        ? '--'
        : '${value.toStringAsFixed(1)} mm';
  }

  String get _condition {
    final value = _valueFromModel('condition') ??
        _valueFromModel('description') ??
        _valueFromModel('weatherDescription');

    if (value == null || value.trim().isEmpty) {
      return 'Current Weather';
    }

    return value;
  }

  String get _locationName {
    final value = _valueFromModel('location') ??
        _valueFromModel('city') ??
        _valueFromModel('cityName');

    if (value == null || value.trim().isEmpty) {
      return 'Current Location';
    }

    return value;
  }

  IconData get _weatherIcon {
    final condition = _condition.toLowerCase();

    if (condition.contains('rain') ||
        condition.contains('drizzle') ||
        condition.contains('shower')) {
      return Icons.umbrella_outlined;
    }

    if (condition.contains('cloud') ||
        condition.contains('overcast')) {
      return Icons.cloud_outlined;
    }

    if (condition.contains('storm') ||
        condition.contains('thunder')) {
      return Icons.thunderstorm_outlined;
    }

    if (condition.contains('snow')) {
      return Icons.ac_unit_rounded;
    }

    if (condition.contains('fog') ||
        condition.contains('mist')) {
      return Icons.cloud_queue_outlined;
    }

    return Icons.wb_sunny_outlined;
  }

  String? _valueFromModel(String property) {
    final dynamic model = weather;

    try {
      switch (property) {
        case 'temperature':
          return model.temperature?.toString();
        case 'temp':
          return model.temp?.toString();
        case 'humidity':
          return model.humidity?.toString();
        case 'windSpeed':
          return model.windSpeed?.toString();
        case 'wind':
          return model.wind?.toString();
        case 'rainfall':
          return model.rainfall?.toString();
        case 'rain':
          return model.rain?.toString();
        case 'precipitation':
          return model.precipitation?.toString();
        case 'condition':
          return model.condition?.toString();
        case 'description':
          return model.description?.toString();
        case 'weatherDescription':
          return model.weatherDescription?.toString();
        case 'location':
          return model.location?.toString();
        case 'city':
          return model.city?.toString();
        case 'cityName':
          return model.cityName?.toString();
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  double? _readDouble(List<String?> values) {
    for (final value in values) {
      if (value == null) {
        continue;
      }

      final parsed = double.tryParse(value);

      if (parsed != null) {
        return parsed;
      }
    }

    return null;
  }
}

class _WeatherMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _WeatherMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: Colors.white.withValues(
                alpha: 0.85,
              ),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(
                    alpha: 0.75,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}