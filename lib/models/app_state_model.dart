import 'package:flutter/material.dart';

import '../core/localization/language_model.dart';
import 'dashboard_model.dart';
import 'disease_model.dart';
import 'farm_model.dart';
import 'recommendation_model.dart';
import 'soil_model.dart';
import 'user_model.dart';
import 'weather_model.dart';
import 'yield_prediction_model.dart';

class AppStateModel {
  final bool isLoading;
  final bool isInitialized;
  final bool isFirstLaunch;
  final Locale locale;
  final UserModel? user;
  final FarmModel? farm;
  final WeatherModel? weather;
  final SoilModel? soil;
  final DashboardModel? dashboard;
  final DiseaseModel? lastDiseaseResult;
  final YieldPredictionModel? lastYieldPrediction;
  final List<RecommendationModel> recommendations;
  final String? errorMessage;

  const AppStateModel({
    this.isLoading = false,
    this.isInitialized = false,
    this.isFirstLaunch = true,
    this.locale = const Locale('en'),
    this.user,
    this.farm,
    this.weather,
    this.soil,
    this.dashboard,
    this.lastDiseaseResult,
    this.lastYieldPrediction,
    this.recommendations = const [],
    this.errorMessage,
  });

  AppStateModel copyWith({
    bool? isLoading,
    bool? isInitialized,
    bool? isFirstLaunch,
    Locale? locale,
    UserModel? user,
    FarmModel? farm,
    WeatherModel? weather,
    SoilModel? soil,
    DashboardModel? dashboard,
    DiseaseModel? lastDiseaseResult,
    YieldPredictionModel? lastYieldPrediction,
    List<RecommendationModel>? recommendations,
    String? errorMessage,
    bool clearUser = false,
    bool clearFarm = false,
    bool clearWeather = false,
    bool clearSoil = false,
    bool clearDashboard = false,
    bool clearDiseaseResult = false,
    bool clearYieldPrediction = false,
    bool clearError = false,
  }) {
    return AppStateModel(
      isLoading: isLoading ?? this.isLoading,
      isInitialized:
          isInitialized ?? this.isInitialized,
      isFirstLaunch:
          isFirstLaunch ?? this.isFirstLaunch,
      locale: locale ?? this.locale,
      user: clearUser ? null : user ?? this.user,
      farm: clearFarm ? null : farm ?? this.farm,
      weather:
          clearWeather ? null : weather ?? this.weather,
      soil: clearSoil ? null : soil ?? this.soil,
      dashboard:
          clearDashboard ? null : dashboard ?? this.dashboard,
      lastDiseaseResult: clearDiseaseResult
          ? null
          : lastDiseaseResult ?? this.lastDiseaseResult,
      lastYieldPrediction: clearYieldPrediction
          ? null
          : lastYieldPrediction ?? this.lastYieldPrediction,
      recommendations:
          recommendations ?? this.recommendations,
      errorMessage:
          clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  LanguageModel get selectedLanguage {
    return LanguageModel.fromCode(
      locale.languageCode,
    );
  }

  bool get hasUser => user != null;

  bool get hasFarm => farm != null;

  bool get hasWeather => weather != null;

  bool get hasSoilData => soil != null;

  bool get hasDashboard => dashboard != null;

  bool get hasDiseaseResult =>
      lastDiseaseResult != null;

  bool get hasYieldPrediction =>
      lastYieldPrediction != null;

  bool get hasRecommendations =>
      recommendations.isNotEmpty;

  bool get hasError =>
      errorMessage != null &&
      errorMessage!.trim().isNotEmpty;

  int get unreadRecommendations {
    return recommendations
        .where((recommendation) => !recommendation.isRead)
        .length;
  }

  AppStateModel clearErrorMessage() {
    return copyWith(clearError: true);
  }

  AppStateModel markInitialized() {
    return copyWith(
      isInitialized: true,
      isLoading: false,
    );
  }

  AppStateModel markOnboardingCompleted() {
    return copyWith(
      isFirstLaunch: false,
    );
  }

  AppStateModel setLanguage(Locale newLocale) {
    return copyWith(
      locale: newLocale,
    );
  }

  AppStateModel setUser(UserModel newUser) {
    return copyWith(
      user: newUser,
    );
  }

  AppStateModel setFarm(FarmModel newFarm) {
    return copyWith(
      farm: newFarm,
    );
  }

  AppStateModel setWeather(
    WeatherModel newWeather,
  ) {
    return copyWith(
      weather: newWeather,
    );
  }

  AppStateModel setSoil(SoilModel newSoil) {
    return copyWith(
      soil: newSoil,
    );
  }

  AppStateModel setDashboard(
    DashboardModel newDashboard,
  ) {
    return copyWith(
      dashboard: newDashboard,
    );
  }

  AppStateModel setDiseaseResult(
    DiseaseModel result,
  ) {
    return copyWith(
      lastDiseaseResult: result,
    );
  }

  AppStateModel setYieldPrediction(
    YieldPredictionModel result,
  ) {
    return copyWith(
      lastYieldPrediction: result,
    );
  }

  AppStateModel setRecommendations(
    List<RecommendationModel> newRecommendations,
  ) {
    return copyWith(
      recommendations: List.unmodifiable(
        newRecommendations,
      ),
    );
  }

  AppStateModel addRecommendation(
    RecommendationModel recommendation,
  ) {
    return copyWith(
      recommendations: [
        ...recommendations,
        recommendation,
      ],
    );
  }

  AppStateModel markRecommendationAsRead(
    String recommendationId,
  ) {
    return copyWith(
      recommendations: recommendations.map(
        (recommendation) {
          if (recommendation.id == recommendationId) {
            return recommendation.markAsRead();
          }

          return recommendation;
        },
      ).toList(),
    );
  }

  AppStateModel clearSession() {
    return AppStateModel(
      locale: locale,
      isInitialized: true,
      isFirstLaunch: false,
    );
  }
}