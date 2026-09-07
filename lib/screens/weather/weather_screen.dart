import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../models/weather_model.dart';
import 'widgets/forecast_card.dart';
import 'widgets/weather_summary_card.dart';

class WeatherScreen extends StatelessWidget {
  final WeatherModel? weather;
  final List<WeatherModel> forecast;
  final VoidCallback? onRefresh;
  final bool isLoading;
  final String? errorMessage;

  const WeatherScreen({
    super.key,
    this.weather,
    this.forecast = const [],
    this.onRefresh,
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Weather'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          if (onRefresh != null)
            IconButton(
              onPressed: isLoading ? null : onRefresh,
              tooltip: 'Refresh',
              icon: const Icon(
                Icons.refresh_rounded,
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            if (onRefresh != null && !isLoading) {
              onRefresh!();
            }
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  28,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      if (isLoading)
                        const _WeatherLoadingCard()
                      else if (errorMessage != null &&
                          errorMessage!.trim().isNotEmpty)
                        _WeatherErrorCard(
                          message: errorMessage!,
                          onRetry: onRefresh,
                        )
                      else if (weather != null)
                        WeatherSummaryCard(
                          weather: weather!,
                        )
                      else
                        const _NoWeatherCard(),
                      if (forecast.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'Forecast',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...forecast.map(
                          (item) => Padding(
                            padding:
                                const EdgeInsets.only(
                              bottom: 10,
                            ),
                            child: ForecastCard(
                              weather: item,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeatherLoadingCard extends StatelessWidget {
  const _WeatherLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(
          AppDimensions.radius22,
        ),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: const Column(
        children: [
          SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 14),
          Text(
            'Loading weather...',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _WeatherErrorCard({
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(
          AppDimensions.radius22,
        ),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.cloud_off_outlined,
              color: Color(0xFFE28A28),
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Unable to load weather',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(
                Icons.refresh_rounded,
                size: 18,
              ),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radius14,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NoWeatherCard extends StatelessWidget {
  const _NoWeatherCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(
          AppDimensions.radius22,
        ),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.cloud_outlined,
            size: 42,
            color: AppColors.primary,
          ),
          SizedBox(height: 12),
          Text(
            'No weather data available',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Weather information will appear here when available.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}