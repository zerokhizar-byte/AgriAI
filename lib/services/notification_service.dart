import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/app_notification_model.dart';

class NotificationService {
  NotificationService._();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static final FirebaseAuth _auth =
      FirebaseAuth.instance;

  static final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  static final FlutterLocalNotificationsPlugin
      _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static bool _localNotificationsInitialized = false;

  // ===========================================================================
  // NOTIFICATION TAP BRIDGE
  // ===========================================================================

  /// Holds notification tap data until the appropriate screen
  /// is ready to process it.
  static final ValueNotifier<Map<String, dynamic>?>
      notificationTap =
      ValueNotifier<Map<String, dynamic>?>(null);

  /// Publishes notification tap data to the application.
  ///
  /// This allows main.dart to pass notification information
  /// to HomeScreen or another appropriate screen.
  static void publishNotificationTap(
    Map<String, dynamic> data,
  ) {
    notificationTap.value =
        Map<String, dynamic>.from(data);

    debugPrintNotification(
      'Notification tap published: $data',
    );
  }

  // ===========================================================================
  // LOCAL NOTIFICATION INITIALIZATION
  // ===========================================================================

  /// Initializes the local notification system.
  static Future<void>
      initializeLocalNotifications() async {
    if (_localNotificationsInitialized) {
      return;
    }

    try {
      const AndroidInitializationSettings
          androidSettings =
          AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      const DarwinInitializationSettings
          iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings settings =
          InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        settings: settings,
        onDidReceiveNotificationResponse:
            _onLocalNotificationTapped,
      );

      final AndroidFlutterLocalNotificationsPlugin?
          androidPlugin =
          _localNotifications
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin
            .requestNotificationsPermission();

        const AndroidNotificationChannel channel =
            AndroidNotificationChannel(
          'agriai_notifications',
          'AgriAI Notifications',
          description:
              'Notifications from AgriAI',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        );

        await androidPlugin
            .createNotificationChannel(
          channel,
        );
      }

      final IOSFlutterLocalNotificationsPlugin?
          iosPlugin =
          _localNotifications
              .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin>();

      if (iosPlugin != null) {
        await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      _localNotificationsInitialized = true;

      debugPrintNotification(
        'Local notifications initialized.',
      );
    } catch (error) {
      debugPrintNotification(
        'Local notification initialization error: $error',
      );
    }
  }

  // ===========================================================================
  // SHOW LOCAL NOTIFICATION
  // ===========================================================================

  /// Displays a notification on the device.
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await initializeLocalNotifications();

    if (!_localNotificationsInitialized) {
      return;
    }

    try {
      const AndroidNotificationDetails
          androidDetails =
          AndroidNotificationDetails(
        'agriai_notifications',
        'AgriAI Notifications',
        channelDescription:
            'Notifications from AgriAI',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails
          iosDetails =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details =
          NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        id: DateTime.now()
                .millisecondsSinceEpoch %
            2147483647,
        title: title.trim().isEmpty
            ? 'AgriAI'
            : title.trim(),
        body: body.trim(),
        notificationDetails: details,
        payload: payload,
      );

      debugPrintNotification(
        'Local notification displayed: $title',
      );
    } catch (error) {
      debugPrintNotification(
        'Unable to display local notification: $error',
      );
    }
  }

  // ===========================================================================
  // LOCAL NOTIFICATION TAP
  // ===========================================================================

  static void _onLocalNotificationTapped(
    NotificationResponse response,
  ) {
    final String? payload =
        response.payload;

    debugPrintNotification(
      'Local notification tapped. '
      'Payload: ${payload ?? 'none'}',
    );

    if (payload == null ||
        payload.trim().isEmpty) {
      return;
    }

    final List<String> parts =
        payload.split('|');

    if (parts.isEmpty) {
      return;
    }

    final String type =
        parts[0].trim();

    if (type.isEmpty) {
      return;
    }

    final Map<String, dynamic> data =
        <String, dynamic>{
      'type': type,
    };

    if (parts.length > 1 &&
        parts[1].trim().isNotEmpty) {
      data['actionRoute'] =
          parts[1].trim();
    }

    if (parts.length > 2 &&
        parts[2].trim().isNotEmpty) {
      data['newsId'] =
          parts[2].trim();
    }

    if (parts.length > 3 &&
        parts[3].trim().isNotEmpty) {
      data['newsUrl'] =
          parts[3].trim();
    }

    if (parts.length > 4 &&
        parts[4].trim().isNotEmpty) {
      data['postId'] =
          parts[4].trim();
    }

    if (parts.length > 5 &&
        parts[5].trim().isNotEmpty) {
      data['conversationId'] =
          parts[5].trim();
    }

    if (parts.length > 6 &&
        parts[6].trim().isNotEmpty) {
      data['connectionRequestId'] =
          parts[6].trim();
    }

    publishNotificationTap(data);
  }

  // ===========================================================================
  // FIREBASE CLOUD MESSAGING
  // ===========================================================================

  /// Initializes Firebase Cloud Messaging for the
  /// currently signed-in user.
  static Future<void>
      initializeForCurrentUser() async {
    if (_initialized) {
      return;
    }

    final User? currentUser =
        _auth.currentUser;

    if (currentUser == null) {
      debugPrintNotification(
        'No authenticated user.',
      );
      return;
    }

    debugPrintNotification(
      'Authenticated user detected: '
      '${currentUser.uid}',
    );

    try {
      await initializeLocalNotifications();

      final NotificationSettings settings =
          await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrintNotification(
        'Permission status: '
        '${settings.authorizationStatus.name}',
      );

      final String? token =
          await _messaging.getToken();

      if (token != null &&
          token.trim().isNotEmpty) {
        await saveFcmToken(
          uid: currentUser.uid,
          token: token,
        );
      }

      _messaging.onTokenRefresh.listen(
        (String refreshedToken) async {
          final User? user =
              _auth.currentUser;

          if (user == null) {
            return;
          }

          try {
            await saveFcmToken(
              uid: user.uid,
              token: refreshedToken,
            );

            debugPrintNotification(
              'FCM token refreshed and saved.',
            );
          } catch (error) {
            debugPrintNotification(
              'Unable to save refreshed FCM token: '
              '$error',
            );
          }
        },
      );

      _initialized = true;

      debugPrintNotification(
        'FCM initialized for user '
        '${currentUser.uid}.',
      );
    } catch (error) {
      debugPrintNotification(
        'FCM user initialization error: $error',
      );
    }
  }

  // ===========================================================================
  // FCM TOKEN
  // ===========================================================================

  /// Saves the current device token inside the user's
  /// Firestore document.
  static Future<void> saveFcmToken({
    required String uid,
    required String token,
  }) async {
    final String normalizedUid =
        uid.trim();

    final String normalizedToken =
        token.trim();

    if (normalizedUid.isEmpty ||
        normalizedToken.isEmpty) {
      return;
    }

    await _firestore
        .collection('users')
        .doc(normalizedUid)
        .set(
      <String, dynamic>{
        'fcmToken': normalizedToken,
        'fcmTokenUpdatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Removes the device token when the user signs out.
  static Future<void> removeFcmToken() async {
    final User? currentUser =
        _auth.currentUser;

    if (currentUser == null) {
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .set(
        <String, dynamic>{
          'fcmToken': FieldValue.delete(),
          'fcmTokenUpdatedAt':
              FieldValue.delete(),
        },
        SetOptions(merge: true),
      );

      _initialized = false;

      debugPrintNotification(
        'FCM token removed for '
        '${currentUser.uid}.',
      );
    } catch (error) {
      debugPrintNotification(
        'Unable to remove FCM token: $error',
      );
    }
  }

  /// Returns the current device FCM token.
  static Future<String?> getCurrentToken() async {
    try {
      final String? token =
          await _messaging.getToken();

      if (token == null ||
          token.trim().isEmpty) {
        return null;
      }

      return token.trim();
    } catch (error) {
      debugPrintNotification(
        'Unable to get FCM token: $error',
      );

      return null;
    }
  }

  /// Deletes the current device FCM token.
  static Future<void> deleteCurrentToken() async {
    try {
      await _messaging.deleteToken();

      _initialized = false;

      debugPrintNotification(
        'Current FCM token deleted.',
      );
    } catch (error) {
      debugPrintNotification(
        'Unable to delete FCM token: $error',
      );
    }
  }

  // ===========================================================================
  // CREATE NOTIFICATION
  // ===========================================================================

  /// Creates an in-app notification document.
  ///
  /// Firestore path:
  ///
  /// users/{uid}/notifications/{notificationId}
  static Future<void> createNotification({
    required String recipientUid,
    required String title,
    required String message,
    required String type,
    required String priority,
    String? senderUid,
    String? senderName,
    String? senderPhotoUrl,
    String? postId,
    String? conversationId,
    String? connectionRequestId,
    String? actionRoute,
    String? newsId,
    String? newsUrl,
    String? newsSource,
  }) async {
    final String normalizedRecipientUid =
        recipientUid.trim();

    if (normalizedRecipientUid.isEmpty) {
      throw ArgumentError(
        'Recipient UID cannot be empty.',
      );
    }

    final CollectionReference<
        Map<String, dynamic>> notifications =
        _firestore
            .collection('users')
            .doc(normalizedRecipientUid)
            .collection('notifications');

    final DocumentReference<
        Map<String, dynamic>> notification =
        notifications.doc();

    await notification.set(
      <String, dynamic>{
        'id': notification.id,
        'title': title.trim(),
        'message': message.trim(),
        'type': type.trim(),
        'priority': priority.trim(),
        'createdAt':
            FieldValue.serverTimestamp(),
        'isRead': false,
        'actionRoute': actionRoute,
        'senderUid': senderUid,
        'senderName': senderName,
        'senderPhotoUrl': senderPhotoUrl,
        'postId': postId,
        'conversationId': conversationId,
        'connectionRequestId':
            connectionRequestId,
        'newsId': newsId,
        'newsUrl': newsUrl,
        'newsSource': newsSource,
      },
    );

    debugPrintNotification(
      'Notification created for '
      '$normalizedRecipientUid',
    );
  }

  // ===========================================================================
  // DAILY AGRICULTURE NEWS
  // ===========================================================================

  /// Creates a Daily Agriculture News notification
  /// inside the user's Firestore notification collection.
  static Future<void>
      createDailyNewsNotification({
    required String recipientUid,
    required String newsId,
    required String newsTitle,
    required String newsUrl,
    String? newsSource,
    String? message,
  }) async {
    final String normalizedTitle =
        newsTitle.trim();

    final String normalizedUrl =
        newsUrl.trim();

    if (normalizedTitle.isEmpty) {
      throw ArgumentError(
        'News title cannot be empty.',
      );
    }

    if (normalizedUrl.isEmpty) {
      throw ArgumentError(
        'News URL cannot be empty.',
      );
    }

    await createNotification(
      recipientUid: recipientUid,
      title: 'Daily Agriculture News',
      message:
          message?.trim().isNotEmpty == true
              ? message!.trim()
              : normalizedTitle,
      type: 'dailyNews',
      priority: 'medium',
      actionRoute: '/news',
      newsId: newsId.trim(),
      newsUrl: normalizedUrl,
      newsSource: newsSource?.trim(),
    );

    debugPrintNotification(
      'Daily Agriculture News notification '
      'created: $normalizedTitle',
    );
  }

  /// Displays a test Daily Agriculture News
  /// notification locally.
  static Future<void>
      showTestDailyNewsNotification({
    required String title,
    required String url,
    String? source,
  }) async {
    await showLocalNotification(
      title: 'Daily Agriculture News',
      body: title,
      payload:
          'dailyNews|/news||$url|||',
    );
  }

  // ===========================================================================
  // CONNECTION REQUEST
  // ===========================================================================

  static Future<void>
      createConnectionRequestNotification({
    required String recipientUid,
    required String senderUid,
    String? senderName,
    String? senderPhotoUrl,
    String? connectionRequestId,
  }) async {
    await createNotification(
      recipientUid: recipientUid,
      title: 'New connection request',
      message:
          senderName == null ||
                  senderName.trim().isEmpty
              ? 'Someone wants to connect with you.'
              : '${senderName.trim()} wants to connect with you.',
      type: 'connectionRequest',
      priority: 'medium',
      senderUid: senderUid,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      connectionRequestId:
          connectionRequestId,
      actionRoute: '/connections',
    );
  }

  // ===========================================================================
  // CONNECTION ACCEPTED
  // ===========================================================================

  static Future<void>
      createConnectionAcceptedNotification({
    required String recipientUid,
    required String senderUid,
    String? senderName,
    String? senderPhotoUrl,
  }) async {
    await createNotification(
      recipientUid: recipientUid,
      title: 'Connection accepted',
      message:
          senderName == null ||
                  senderName.trim().isEmpty
              ? 'Your connection request was accepted.'
              : '${senderName.trim()} accepted your connection request.',
      type: 'connectionAccepted',
      priority: 'low',
      senderUid: senderUid,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      actionRoute: '/connections',
    );
  }

  // ===========================================================================
  // MESSAGE
  // ===========================================================================

  static Future<void>
      createMessageNotification({
    required String recipientUid,
    required String senderUid,
    required String conversationId,
    required String message,
    String? senderName,
    String? senderPhotoUrl,
  }) async {
    await createNotification(
      recipientUid: recipientUid,
      title:
          senderName == null ||
                  senderName.trim().isEmpty
              ? 'New message'
              : senderName.trim(),
      message:
          message.trim().isEmpty
              ? 'You received a new message.'
              : message.trim(),
      type: 'message',
      priority: 'medium',
      senderUid: senderUid,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      conversationId: conversationId,
      actionRoute: '/messages',
    );
  }

  // ===========================================================================
  // LIKE
  // ===========================================================================

  static Future<void> createLikeNotification({
    required String recipientUid,
    required String senderUid,
    required String postId,
    String? senderName,
    String? senderPhotoUrl,
  }) async {
    await createNotification(
      recipientUid: recipientUid,
      title: 'New like',
      message:
          senderName == null ||
                  senderName.trim().isEmpty
              ? 'Someone liked your post.'
              : '${senderName.trim()} liked your post.',
      type: 'like',
      priority: 'low',
      senderUid: senderUid,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      postId: postId,
      actionRoute: '/post/$postId',
    );
  }

  // ===========================================================================
  // COMMENT
  // ===========================================================================

  static Future<void> createCommentNotification({
    required String recipientUid,
    required String senderUid,
    required String postId,
    String? senderName,
    String? senderPhotoUrl,
    String? commentText,
  }) async {
    final String normalizedComment =
        commentText?.trim() ?? '';

    await createNotification(
      recipientUid: recipientUid,
      title: 'New comment',
      message:
          senderName == null ||
                  senderName.trim().isEmpty
              ? 'Someone commented on your post.'
              : normalizedComment.isEmpty
                  ? '${senderName.trim()} commented on your post.'
                  : '${senderName.trim()}: $normalizedComment',
      type: 'comment',
      priority: 'low',
      senderUid: senderUid,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      postId: postId,
      actionRoute: '/post/$postId',
    );
  }

  // ===========================================================================
  // NOTIFICATION STREAM
  // ===========================================================================

  /// Returns a real-time stream of the current user's notifications.
  static Stream<List<AppNotificationModel>>
      notificationsStream() {
    final User? user =
        _auth.currentUser;

    if (user == null) {
      return const Stream<
          List<AppNotificationModel>>.empty();
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots()
        .map(
      (
        QuerySnapshot<
            Map<String, dynamic>> snapshot,
      ) {
        return snapshot.docs.map(
          (
            QueryDocumentSnapshot<
                Map<String, dynamic>> doc,
          ) {
            final Map<String, dynamic> data =
                doc.data();

            return AppNotificationModel.fromJson(
              <String, dynamic>{
                ...data,
                'id': doc.id,
              },
            );
          },
        ).toList();
      },
    );
  }

  // ===========================================================================
  // GET NOTIFICATIONS
  // ===========================================================================

  static Future<List<AppNotificationModel>>
      getNotifications() async {
    final User? user =
        _auth.currentUser;

    if (user == null) {
      return <AppNotificationModel>[];
    }

    try {
      final QuerySnapshot<
          Map<String, dynamic>> snapshot =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('notifications')
              .orderBy(
                'createdAt',
                descending: true,
              )
              .get();

      return snapshot.docs.map(
        (
          QueryDocumentSnapshot<
              Map<String, dynamic>> doc,
        ) {
          final Map<String, dynamic> data =
              doc.data();

          return AppNotificationModel.fromJson(
            <String, dynamic>{
              ...data,
              'id': doc.id,
            },
          );
        },
      ).toList();
    } catch (error) {
      debugPrintNotification(
        'Unable to load notifications: $error',
      );

      return <AppNotificationModel>[];
    }
  }

  // ===========================================================================
  // MARK AS READ
  // ===========================================================================

  static Future<void> markAsRead(
    String notificationId,
  ) async {
    final User? user =
        _auth.currentUser;

    final String normalizedId =
        notificationId.trim();

    if (user == null ||
        normalizedId.isEmpty) {
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(normalizedId)
          .update(
        <String, dynamic>{
          'isRead': true,
        },
      );

      debugPrintNotification(
        'Notification marked as read: '
        '$normalizedId',
      );
    } catch (error) {
      debugPrintNotification(
        'Unable to mark notification as read: '
        '$error',
      );
    }
  }

  // ===========================================================================
  // MARK AS UNREAD
  // ===========================================================================

  static Future<void> markAsUnread(
    String notificationId,
  ) async {
    final User? user =
        _auth.currentUser;

    final String normalizedId =
        notificationId.trim();

    if (user == null ||
        normalizedId.isEmpty) {
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(normalizedId)
          .update(
        <String, dynamic>{
          'isRead': false,
        },
      );

      debugPrintNotification(
        'Notification marked as unread: '
        '$normalizedId',
      );
    } catch (error) {
      debugPrintNotification(
        'Unable to mark notification as unread: '
        '$error',
      );
    }
  }

  // ===========================================================================
  // MARK ALL AS READ
  // ===========================================================================

  static Future<void> markAllAsRead() async {
    final User? user =
        _auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      final QuerySnapshot<
          Map<String, dynamic>> snapshot =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('notifications')
              .where(
                'isRead',
                isEqualTo: false,
              )
              .get();

      if (snapshot.docs.isEmpty) {
        return;
      }

      final WriteBatch batch =
          _firestore.batch();

      for (
        final QueryDocumentSnapshot<
            Map<String, dynamic>> doc
        in snapshot.docs
      ) {
        batch.update(
          doc.reference,
          <String, dynamic>{
            'isRead': true,
          },
        );
      }

      await batch.commit();

      debugPrintNotification(
        'All notifications marked as read.',
      );
    } catch (error) {
      debugPrintNotification(
        'Unable to mark all notifications as read: '
        '$error',
      );
    }
  }

  // ===========================================================================
  // DELETE NOTIFICATION
  // ===========================================================================

  static Future<void> deleteNotification(
    String notificationId,
  ) async {
    final User? user =
        _auth.currentUser;

    final String normalizedId =
        notificationId.trim();

    if (user == null ||
        normalizedId.isEmpty) {
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(normalizedId)
          .delete();

      debugPrintNotification(
        'Notification deleted: '
        '$normalizedId',
      );
    } catch (error) {
      debugPrintNotification(
        'Unable to delete notification: $error',
      );
    }
  }

  // ===========================================================================
  // DELETE ALL NOTIFICATIONS
  // ===========================================================================

  static Future<void>
      deleteAllNotifications() async {
    final User? user =
        _auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      final QuerySnapshot<
          Map<String, dynamic>> snapshot =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('notifications')
              .get();

      if (snapshot.docs.isEmpty) {
        return;
      }

      final WriteBatch batch =
          _firestore.batch();

      for (
        final QueryDocumentSnapshot<
            Map<String, dynamic>> doc
        in snapshot.docs
      ) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      debugPrintNotification(
        'All notifications deleted.',
      );
    } catch (error) {
      debugPrintNotification(
        'Unable to delete all notifications: $error',
      );
    }
  }
}

// ============================================================================
// DEBUG
// ============================================================================

void debugPrintNotification(
  String message,
) {
  // ignore: avoid_print
  print(
    'AgriAI Notification: $message',
  );
}