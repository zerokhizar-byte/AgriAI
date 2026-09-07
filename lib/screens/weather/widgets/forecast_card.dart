import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../models/weather_model.dart';

class ForecastCard extends StatelessWidget {
  final WeatherModel weather;
  final String? dayLabel;

  const ForecastCard({
    super.key,
    required this.weather,
    this.dayLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(
          AppDimensions.radius18,
        ),
        border: Border.all(
          color: AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(
              alpha: 0.06,
            ),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.cardGreen,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _weatherIcon,
              size: 25,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  dayLabel ?? _dateLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _condition,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _temperature,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _humidity,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
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

    if (value == null) {
      return '--°C';
    }

    return '${value.toStringAsFixed(0)}°C';
  }

  String get _humidity {
    final value = _readDouble([
      _valueFromModel('humidity'),
    ]);

    if (value == null) {
      return '--';
    }

    return 'Humidity ${value.toStringAsFixed(0)}%';
  }

  String get _condition {
    final value = _valueFromModel('condition') ??
        _valueFromModel('description') ??
        _valueFromModel('weatherDescription');

    if (value == null || value.trim().isEmpty) {
      return 'Weather forecast';
    }

    return value;
  }

  String get _dateLabel {
    final value = _valueFromModel('date') ??
        _valueFromModel('forecastDate') ??
        _valueFromModel('datetime');

    if (value == null || value.trim().isEmpty) {
      return 'Forecast';
    }

    final parsed = DateTime.tryParse(value);

    if (parsed == null) {
      return value;
    }

    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return days[parsed.weekday - 1];
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
        case 'condition':
          return model.condition?.toString();
        case 'description':
          return model.description?.toString();
        case 'weatherDescription':
          return model.weatherDescription?.toString();
        case 'date':
          return model.date?.toString();
        case 'forecastDate':
          return model.forecastDate?.toString();
        case 'datetime':
          return model.datetime?.toString();
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