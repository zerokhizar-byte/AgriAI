class DiseaseModel {
  final String id;
  final String diseaseName;
  final String cropName;
  final double confidence;
  final bool isHealthy;
  final String description;
  final String treatment;
  final String prevention;
  final String? imagePath;
  final DateTime? detectedAt;

  const DiseaseModel({
    required this.id,
    required this.diseaseName,
    required this.cropName,
    required this.confidence,
    required this.isHealthy,
    required this.description,
    required this.treatment,
    required this.prevention,
    this.imagePath,
    this.detectedAt,
  });

  DiseaseModel copyWith({
    String? id,
    String? diseaseName,
    String? cropName,
    double? confidence,
    bool? isHealthy,
    String? description,
    String? treatment,
    String? prevention,
    String? imagePath,
    DateTime? detectedAt,
  }) {
    return DiseaseModel(
      id: id ?? this.id,
      diseaseName: diseaseName ?? this.diseaseName,
      cropName: cropName ?? this.cropName,
      confidence: confidence ?? this.confidence,
      isHealthy: isHealthy ?? this.isHealthy,
      description: description ?? this.description,
      treatment: treatment ?? this.treatment,
      prevention: prevention ?? this.prevention,
      imagePath: imagePath ?? this.imagePath,
      detectedAt: detectedAt ?? this.detectedAt,
    );
  }

  factory DiseaseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return DiseaseModel(
      id: json['id']?.toString() ?? '',
      diseaseName:
          json['diseaseName']?.toString() ?? 'Unknown',
      cropName:
          json['cropName']?.toString() ?? 'Unknown',
      confidence: _toDouble(
        json['confidence'],
      ),
      isHealthy:
          json['isHealthy'] == true,
      description:
          json['description']?.toString() ?? '',
      treatment:
          json['treatment']?.toString() ?? '',
      prevention:
          json['prevention']?.toString() ?? '',
      imagePath:
          json['imagePath']?.toString(),
      detectedAt:
          _parseDate(json['detectedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'diseaseName': diseaseName,
      'cropName': cropName,
      'confidence': confidence,
      'isHealthy': isHealthy,
      'description': description,
      'treatment': treatment,
      'prevention': prevention,
      'imagePath': imagePath,
      'detectedAt':
          detectedAt?.toIso8601String(),
    };
  }

  double get confidencePercentage {
    if (confidence <= 1) {
      return confidence * 100;
    }

    return confidence;
  }

  String get confidenceDisplay {
    return '${confidencePercentage.toStringAsFixed(1)}%';
  }

  String get healthStatus {
    return isHealthy ? 'Healthy' : 'Disease Detected';
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

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is DiseaseModel &&
        other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}