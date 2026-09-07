enum RecommendationType {
  irrigation,
  fertilizer,
  soil,
  weather,
  crop,
  general,
}

enum RecommendationPriority {
  low,
  medium,
  high,
}

class RecommendationModel {
  final String id;
  final RecommendationType type;
  final RecommendationPriority priority;
  final String title;
  final String description;
  final String? action;
  final DateTime? createdAt;
  final bool isRead;

  const RecommendationModel({
    required this.id,
    required this.type,
    required this.priority,
    required this.title,
    required this.description,
    this.action,
    this.createdAt,
    this.isRead = false,
  });

  RecommendationModel copyWith({
    String? id,
    RecommendationType? type,
    RecommendationPriority? priority,
    String? title,
    String? description,
    String? action,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return RecommendationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      title: title ?? this.title,
      description: description ?? this.description,
      action: action ?? this.action,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  factory RecommendationModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return RecommendationModel(
      id: json['id']?.toString() ?? '',
      type: _parseType(
        json['type']?.toString(),
      ),
      priority: _parsePriority(
        json['priority']?.toString(),
      ),
      title: json['title']?.toString() ?? '',
      description:
          json['description']?.toString() ?? '',
      action: json['action']?.toString(),
      createdAt: _parseDate(
        json['createdAt'],
      ),
      isRead: json['isRead'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'priority': priority.name,
      'title': title,
      'description': description,
      'action': action,
      'createdAt':
          createdAt?.toIso8601String(),
      'isRead': isRead,
    };
  }

  RecommendationModel markAsRead() {
    return copyWith(isRead: true);
  }

  String get typeName {
    switch (type) {
      case RecommendationType.irrigation:
        return 'Irrigation';
      case RecommendationType.fertilizer:
        return 'Fertilizer';
      case RecommendationType.soil:
        return 'Soil';
      case RecommendationType.weather:
        return 'Weather';
      case RecommendationType.crop:
        return 'Crop';
      case RecommendationType.general:
        return 'General';
    }
  }

  String get priorityName {
    switch (priority) {
      case RecommendationPriority.low:
        return 'Low';
      case RecommendationPriority.medium:
        return 'Medium';
      case RecommendationPriority.high:
        return 'High';
    }
  }

  bool get isHighPriority =>
      priority == RecommendationPriority.high;

  bool get isMediumPriority =>
      priority == RecommendationPriority.medium;

  bool get isLowPriority =>
      priority == RecommendationPriority.low;

  static RecommendationType _parseType(
    String? value,
  ) {
    return RecommendationType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => RecommendationType.general,
    );
  }

  static RecommendationPriority _parsePriority(
    String? value,
  ) {
    return RecommendationPriority.values.firstWhere(
      (priority) => priority.name == value,
      orElse: () => RecommendationPriority.low,
    );
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

    return other is RecommendationModel &&
        other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}