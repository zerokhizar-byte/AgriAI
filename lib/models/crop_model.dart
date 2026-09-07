class CropModel {
  final String id;
  final String name;
  final String scientificName;
  final String season;
  final String category;
  final String? imageAsset;
  final double? expectedYield;
  final String? yieldUnit;
  final String? description;

  const CropModel({
    required this.id,
    required this.name,
    required this.scientificName,
    required this.season,
    required this.category,
    this.imageAsset,
    this.expectedYield,
    this.yieldUnit,
    this.description,
  });

  CropModel copyWith({
    String? id,
    String? name,
    String? scientificName,
    String? season,
    String? category,
    String? imageAsset,
    double? expectedYield,
    String? yieldUnit,
    String? description,
  }) {
    return CropModel(
      id: id ?? this.id,
      name: name ?? this.name,
      scientificName:
          scientificName ?? this.scientificName,
      season: season ?? this.season,
      category: category ?? this.category,
      imageAsset: imageAsset ?? this.imageAsset,
      expectedYield:
          expectedYield ?? this.expectedYield,
      yieldUnit: yieldUnit ?? this.yieldUnit,
      description:
          description ?? this.description,
    );
  }

  factory CropModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return CropModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      scientificName:
          json['scientificName']?.toString() ?? '',
      season: json['season']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      imageAsset:
          json['imageAsset']?.toString(),
      expectedYield:
          _toDouble(json['expectedYield']),
      yieldUnit:
          json['yieldUnit']?.toString(),
      description:
          json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'scientificName': scientificName,
      'season': season,
      'category': category,
      'imageAsset': imageAsset,
      'expectedYield': expectedYield,
      'yieldUnit': yieldUnit,
      'description': description,
    };
  }

  static double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is CropModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}