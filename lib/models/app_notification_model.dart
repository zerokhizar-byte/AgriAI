class AppNotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationPriority priority;
  final DateTime createdAt;
  final bool isRead;
  final String? actionRoute;

  const AppNotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    required this.createdAt,
    this.isRead = false,
    this.actionRoute,
  });

  AppNotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    NotificationPriority? priority,
    DateTime? createdAt,
    bool? isRead,
    String? actionRoute,
  }) {
    return AppNotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      actionRoute: actionRoute ?? this.actionRoute,
    );
  }

  factory AppNotificationModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AppNotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: _parseType(
        json['type']?.toString(),
      ),
      priority: _parsePriority(
        json['priority']?.toString(),
      ),
      createdAt: _parseDate(
        json['createdAt'],
      ),
      isRead: json['isRead'] == true,
      actionRoute:
          json['actionRoute']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.name,
      'priority': priority.name,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'actionRoute': actionRoute,
    };
  }

  AppNotificationModel markAsRead() {
    return copyWith(isRead: true);
  }

  AppNotificationModel markAsUnread() {
    return copyWith(isRead: false);
  }

  String get typeName {
    switch (type) {
      case NotificationType.weather:
        return 'Weather';
      case NotificationType.irrigation:
        return 'Irrigation';
      case NotificationType.disease:
        return 'Disease';
      case NotificationType.yield:
        return 'Crop Yield';
      case NotificationType.soil:
        return 'Soil';
      case NotificationType.fertilizer:
        return 'Fertilizer';
      case NotificationType.general:
        return 'General';
    }
  }

  String get priorityName {
    switch (priority) {
      case NotificationPriority.low:
        return 'Low';
      case NotificationPriority.medium:
        return 'Medium';
      case NotificationPriority.high:
        return 'High';
    }
  }

  bool get isHighPriority =>
      priority == NotificationPriority.high;

  bool get isUnread => !isRead;

  static NotificationType _parseType(
    String? value,
  ) {
    return NotificationType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => NotificationType.general,
    );
  }

  static NotificationPriority _parsePriority(
    String? value,
  ) {
    return NotificationPriority.values.firstWhere(
      (priority) => priority.name == value,
      orElse: () => NotificationPriority.low,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(
          value?.toString() ?? '',
        ) ??
        DateTime.now();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is AppNotificationModel &&
        other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

enum NotificationType {
  weather,
  irrigation,
  disease,
  yield,
  soil,
  fertilizer,
  general,
}

enum NotificationPriority {
  low,
  medium,
  high,
}