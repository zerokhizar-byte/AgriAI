import 'dart:io';

class DiseaseDetectionService {
  Future<DiseaseDetectionResult> detectDisease(
    File imageFile,
  ) async {
    if (!await imageFile.exists()) {
      throw const DiseaseDetectionException(
        'The selected image could not be found.',
      );
    }

    /*
     * Temporary development implementation.
     *
     * The trained CNN/plant-disease model will be connected here.
     * This service structure allows the UI to remain unchanged
     * when the actual model is integrated.
     */

    return const DiseaseDetectionResult(
      diseaseName: 'Analysis Pending',
      confidence: 0.0,
      isHealthy: false,
      description:
          'The plant image is ready for disease analysis.',
      treatment:
          'Connect the trained plant disease model to obtain the diagnosis and treatment recommendation.',
      prevention:
          'Maintain proper irrigation, nutrition, field sanitation, and regular crop monitoring.',
    );
  }

  Future<DiseaseDetectionResult> detectDiseaseFromPath(
    String imagePath,
  ) async {
    final file = File(imagePath);

    return detectDisease(file);
  }
}

class DiseaseDetectionResult {
  final String diseaseName;
  final double confidence;
  final bool isHealthy;
  final String description;
  final String treatment;
  final String prevention;

  const DiseaseDetectionResult({
    required this.diseaseName,
    required this.confidence,
    required this.isHealthy,
    required this.description,
    required this.treatment,
    required this.prevention,
  });

  factory DiseaseDetectionResult.fromJson(
    Map<String, dynamic> json,
  ) {
    return DiseaseDetectionResult(
      diseaseName:
          json['diseaseName']?.toString() ??
              'Unknown',
      confidence:
          _toDouble(json['confidence']),
      isHealthy:
          json['isHealthy'] == true,
      description:
          json['description']?.toString() ?? '',
      treatment:
          json['treatment']?.toString() ?? '',
      prevention:
          json['prevention']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'diseaseName': diseaseName,
      'confidence': confidence,
      'isHealthy': isHealthy,
      'description': description,
      'treatment': treatment,
      'prevention': prevention,
    };
  }

  double get confidencePercentage {
    if (confidence <= 1) {
      return confidence * 100;
    }

    return confidence;
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

class DiseaseDetectionException
    implements Exception {
  final String message;

  const DiseaseDetectionException(
    this.message,
  );

  @override
  String toString() => message;
}