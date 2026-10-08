import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationPriority priority;
  final DateTime createdAt;
  final bool isRead;

  /// Route or destination used when the notification is tapped.
  final String? actionRoute;

  /// UID of the user who caused the notification.
  final String? senderUid;

  /// Display name of the user who caused the notification.
  final String? senderName;

  /// Profile image of the user who caused the notification.
  final String? senderPhotoUrl;

  /// Post ID for like/comment notifications.
  final String? postId;

  /// Conversation ID for DM notifications.
  final String? conversationId;

  /// Connection request ID for connection notifications.
  final String? connectionRequestId;

  const AppNotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    required this.createdAt,
    this.isRead = false,
    this.actionRoute,
    this.senderUid,
    this.senderName,
    this.senderPhotoUrl,
    this.postId,
    this.conversationId,
    this.connectionRequestId,
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
    String? senderUid,
    String? senderName,
    String? senderPhotoUrl,
    String? postId,
    String? conversationId,
    String? connectionRequestId,
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
      senderUid: senderUid ?? this.senderUid,
      senderName: senderName ?? this.senderName,
      senderPhotoUrl: senderPhotoUrl ?? this.senderPhotoUrl,
      postId: postId ?? this.postId,
      conversationId: conversationId ?? this.conversationId,
      connectionRequestId: connectionRequestId ?? this.connectionRequestId,
    );
  }

  factory AppNotificationModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AppNotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: _parseType(json['type']?.toString()),
      priority: _parsePriority(json['priority']?.toString()),
      createdAt: _parseDate(json['createdAt']),
      isRead: json['isRead'] == true,
      actionRoute: json['actionRoute']?.toString(),
      senderUid: json['senderUid']?.toString(),
      senderName: json['senderName']?.toString(),
      senderPhotoUrl: json['senderPhotoUrl']?.toString(),
      postId: json['postId']?.toString(),
      conversationId: json['conversationId']?.toString(),
      connectionRequestId: json['connectionRequestId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'message': message,
      'type': type.name,
      'priority': priority.name,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'actionRoute': actionRoute,
      'senderUid': senderUid,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'postId': postId,
      'conversationId': conversationId,
      'connectionRequestId': connectionRequestId,
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

      case NotificationType.connectionRequest:
        return 'Connection Request';

      case NotificationType.connectionAccepted:
        return 'Connection Accepted';

      case NotificationType.message:
        return 'Message';

      case NotificationType.like:
        return 'Like';

      case NotificationType.comment:
        return 'Comment';

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

  bool get isHighPriority {
    return priority == NotificationPriority.high;
  }

  bool get isUnread {
    return !isRead;
  }

  bool get isSocialNotification {
    switch (type) {
      case NotificationType.connectionRequest:
      case NotificationType.connectionAccepted:
      case NotificationType.message:
      case NotificationType.like:
      case NotificationType.comment:
        return true;

      case NotificationType.weather:
      case NotificationType.irrigation:
      case NotificationType.disease:
      case NotificationType.yield:
      case NotificationType.soil:
      case NotificationType.fertilizer:
      case NotificationType.general:
        return false;
    }
  }

  static NotificationType _parseType(String? value) {
    return NotificationType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => NotificationType.general,
    );
  }

  static NotificationPriority _parsePriority(String? value) {
    return NotificationPriority.values.firstWhere(
      (priority) => priority.name == value,
      orElse: () => NotificationPriority.low,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }

    return DateTime.now();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is AppNotificationModel && other.id == id;
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

  // Social notifications
  connectionRequest,
  connectionAccepted,
  message,
  like,
  comment,

  general,
}

enum NotificationPriority {
  low,
  medium,
  high,
}