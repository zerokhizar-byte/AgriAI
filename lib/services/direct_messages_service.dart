import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';

enum DirectMessageType {
  text,
  post,
  reel,
}

class DirectConversation {
  final String id;
  final List<String> participantUids;
  final String lastMessage;
  final String lastMessageType;
  final DateTime? lastMessageAt;
  final DateTime? updatedAt;
  final Map<String, int> unreadCounts;

  const DirectConversation({
    required this.id,
    required this.participantUids,
    required this.lastMessage,
    required this.lastMessageType,
    required this.lastMessageAt,
    required this.updatedAt,
    required this.unreadCounts,
  });

  String otherParticipantUid(String currentUid) {
    for (final String uid in participantUids) {
      if (uid != currentUid) {
        return uid;
      }
    }

    return '';
  }

  int unreadCountFor(String uid) {
    return unreadCounts[uid] ?? 0;
  }

  factory DirectConversation.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final Map<String, dynamic> data =
        document.data() ?? <String, dynamic>{};

    final Map<String, int> parsedUnreadCounts =
        <String, int>{};

    final dynamic rawUnreadCounts = data['unreadCounts'];

    if (rawUnreadCounts is Map) {
      rawUnreadCounts.forEach(
        (
          dynamic key,
          dynamic value,
        ) {
          final int? parsedValue = value is num
              ? value.toInt()
              : int.tryParse('$value');

          if (parsedValue != null && parsedValue > 0) {
            parsedUnreadCounts['$key'] = parsedValue;
          }
        },
      );
    }

    final dynamic rawParticipants =
        data['participantUids'];

    final List<String> participants =
        rawParticipants is List
            ? rawParticipants
                .map(
                  (dynamic value) => '$value',
                )
                .where(
                  (String value) => value.isNotEmpty,
                )
                .toList()
            : <String>[];

    return DirectConversation(
      id: document.id,
      participantUids: participants,
      lastMessage: '${data['lastMessage'] ?? ''}',
      lastMessageType:
          '${data['lastMessageType'] ?? 'text'}',
      lastMessageAt: _timestampToDateTime(
        data['lastMessageAt'],
      ),
      updatedAt: _timestampToDateTime(
        data['updatedAt'],
      ),
      unreadCounts: parsedUnreadCounts,
    );
  }
}

class DirectMessage {
  final String id;
  final String senderUid;
  final String receiverUid;
  final String type;
  final String text;
  final String postId;
  final String reelId;
  final String mediaUrl;
  final DateTime? createdAt;
  final bool seen;

  const DirectMessage({
    required this.id,
    required this.senderUid,
    required this.receiverUid,
    required this.type,
    required this.text,
    required this.postId,
    required this.reelId,
    required this.mediaUrl,
    required this.createdAt,
    required this.seen,
  });

  factory DirectMessage.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final Map<String, dynamic> data =
        document.data() ?? <String, dynamic>{};

    return DirectMessage(
      id: document.id,
      senderUid: '${data['senderUid'] ?? ''}',
      receiverUid: '${data['receiverUid'] ?? ''}',
      type: '${data['type'] ?? 'text'}',
      text: '${data['text'] ?? ''}',
      postId: '${data['postId'] ?? ''}',
      reelId: '${data['reelId'] ?? ''}',
      mediaUrl: '${data['mediaUrl'] ?? ''}',
      createdAt: _timestampToDateTime(
        data['createdAt'],
      ),
      seen: data['seen'] == true,
    );
  }
}

class DirectMessagesService {
  DirectMessagesService._();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static final FirebaseAuth _auth =
      FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>>
      get _conversations =>
          _firestore.collection('conversations');

  // ===========================================================================
  // CONVERSATION ID
  // ===========================================================================

  static String conversationIdForUsers(
    String firstUid,
    String secondUid,
  ) {
    final List<String> uids = <String>[
      firstUid.trim(),
      secondUid.trim(),
    ]..sort();

    if (uids.length != 2 ||
        uids[0].isEmpty ||
        uids[1].isEmpty ||
        uids[0] == uids[1]) {
      throw ArgumentError(
        'Two different valid user IDs are required.',
      );
    }

    return '${uids[0]}_${uids[1]}';
  }

  // ===========================================================================
  // GET OR CREATE CONVERSATION
  // ===========================================================================

  static Future<String> getOrCreateConversation({
    required String otherUid,
  }) async {
    final User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'not-authenticated',
        message:
            'You must be signed in to use Direct Messages.',
      );
    }

    final String currentUid = currentUser.uid;
    final String normalizedOtherUid = otherUid.trim();

    if (normalizedOtherUid.isEmpty) {
      throw ArgumentError(
        'Other user ID cannot be empty.',
      );
    }

    if (normalizedOtherUid == currentUid) {
      throw ArgumentError(
        'You cannot create a conversation with yourself.',
      );
    }

    final String conversationId =
        conversationIdForUsers(
      currentUid,
      normalizedOtherUid,
    );

    final DocumentReference<Map<String, dynamic>>
        reference =
        _conversations.doc(conversationId);

    final DocumentSnapshot<Map<String, dynamic>>
        snapshot =
        await reference.get();

    if (!snapshot.exists) {
      await reference.set(
        <String, dynamic>{
          'participantUids': <String>[
            currentUid,
            normalizedOtherUid,
          ],
          'lastMessage': '',
          'lastMessageType': 'text',
          'lastMessageAt': null,
          'updatedAt': FieldValue.serverTimestamp(),
          'unreadCounts': <String, int>{
            currentUid: 0,
            normalizedOtherUid: 0,
          },
        },
      );
    } else if (snapshot.data()?['unreadCounts'] == null) {
      await reference.set(
        <String, dynamic>{
          'unreadCounts': <String, int>{
            currentUid: 0,
            normalizedOtherUid: 0,
          },
        },
        SetOptions(merge: true),
      );
    }

    return conversationId;
  }

  // ===========================================================================
  // WATCH CONVERSATIONS
  // ===========================================================================

  static Stream<List<DirectConversation>>
      watchConversations() {
    final User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      return Stream<List<DirectConversation>>.value(
        <DirectConversation>[],
      );
    }

    return _conversations
        .where(
          'participantUids',
          arrayContains: currentUser.uid,
        )
        .snapshots()
        .map(
      (
        QuerySnapshot<Map<String, dynamic>> snapshot,
      ) {
        final List<DirectConversation>
            conversations =
            snapshot.docs
                .map(
                  DirectConversation.fromDocument,
                )
                .toList();

        conversations.sort(
          (
            DirectConversation first,
            DirectConversation second,
          ) {
            final DateTime firstDate =
                first.updatedAt ??
                    first.lastMessageAt ??
                    DateTime.fromMillisecondsSinceEpoch(
                      0,
                    );

            final DateTime secondDate =
                second.updatedAt ??
                    second.lastMessageAt ??
                    DateTime.fromMillisecondsSinceEpoch(
                      0,
                    );

            return secondDate.compareTo(firstDate);
          },
        );

        return conversations;
      },
    );
  }

  // ===========================================================================
  // WATCH MESSAGES
  // ===========================================================================

  static Stream<List<DirectMessage>>
      watchMessages({
    required String conversationId,
    int limit = 100,
  }) {
    final String normalizedConversationId =
        conversationId.trim();

    if (normalizedConversationId.isEmpty) {
      return Stream<List<DirectMessage>>.value(
        <DirectMessage>[],
      );
    }

    final int safeLimit = limit < 1 ? 1 : limit;

    return _conversations
        .doc(normalizedConversationId)
        .collection('messages')

        // IMPORTANT:
        // Messages are returned oldest -> newest.
        // The chat screen should therefore use reverse: false.
        .orderBy(
          'createdAt',
          descending: false,
        )
        .limit(safeLimit)
        .snapshots()
        .map(
      (
        QuerySnapshot<Map<String, dynamic>> snapshot,
      ) {
        return snapshot.docs
            .map(
              DirectMessage.fromDocument,
            )
            .toList();
      },
    );
  }

  // ===========================================================================
  // SEND TEXT MESSAGE
  // ===========================================================================

  static Future<String> sendTextMessage({
    required String conversationId,
    required String receiverUid,
    required String text,
  }) async {
    final String value = text.trim();

    if (value.isEmpty) {
      throw ArgumentError(
        'Message cannot be empty.',
      );
    }

    return _sendMessage(
      conversationId: conversationId,
      receiverUid: receiverUid,
      type: DirectMessageType.text,
      text: value,
    );
  }

  // ===========================================================================
  // SEND POST
  // ===========================================================================

  static Future<String> sendPostMessage({
    required String conversationId,
    required String receiverUid,
    required String postId,
    String text = '',
    String mediaUrl = '',
  }) async {
    final String normalizedPostId =
        postId.trim();

    if (normalizedPostId.isEmpty) {
      throw ArgumentError(
        'Post ID cannot be empty.',
      );
    }

    return _sendMessage(
      conversationId: conversationId,
      receiverUid: receiverUid,
      type: DirectMessageType.post,
      text: text.trim(),
      postId: normalizedPostId,
      mediaUrl: mediaUrl.trim(),
    );
  }

  // ===========================================================================
  // SEND REEL
  // ===========================================================================

  static Future<String> sendReelMessage({
    required String conversationId,
    required String receiverUid,
    required String reelId,
    String text = '',
    String mediaUrl = '',
  }) async {
    final String normalizedReelId =
        reelId.trim();

    if (normalizedReelId.isEmpty) {
      throw ArgumentError(
        'Reel ID cannot be empty.',
      );
    }

    return _sendMessage(
      conversationId: conversationId,
      receiverUid: receiverUid,
      type: DirectMessageType.reel,
      text: text.trim(),
      reelId: normalizedReelId,
      mediaUrl: mediaUrl.trim(),
    );
  }

  // ===========================================================================
  // SEND MESSAGE
  // ===========================================================================

  static Future<String> _sendMessage({
    required String conversationId,
    required String receiverUid,
    required DirectMessageType type,
    String text = '',
    String postId = '',
    String reelId = '',
    String mediaUrl = '',
  }) async {
    final User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'not-authenticated',
        message:
            'You must be signed in to send messages.',
      );
    }

    final String normalizedConversationId =
        conversationId.trim();

    final String normalizedReceiverUid =
        receiverUid.trim();

    if (normalizedConversationId.isEmpty) {
      throw ArgumentError(
        'Conversation ID cannot be empty.',
      );
    }

    if (normalizedReceiverUid.isEmpty) {
      throw ArgumentError(
        'Receiver ID cannot be empty.',
      );
    }

    if (normalizedReceiverUid == currentUser.uid) {
      throw ArgumentError(
        'You cannot send a message to yourself.',
      );
    }

    final DocumentReference<Map<String, dynamic>>
        conversation =
        _conversations.doc(
      normalizedConversationId,
    );

    final DocumentReference<Map<String, dynamic>>
        message =
        conversation.collection('messages').doc();

    final String lastMessage;

    switch (type) {
      case DirectMessageType.text:
        lastMessage = text.trim();
        break;

      case DirectMessageType.post:
        lastMessage = 'Shared a post';
        break;

      case DirectMessageType.reel:
        lastMessage = 'Shared a Reel';
        break;
    }

    final String typeValue = type.name;

    final WriteBatch batch =
        _firestore.batch();

    batch.set(
      message,
      <String, dynamic>{
        'senderUid': currentUser.uid,
        'receiverUid': normalizedReceiverUid,
        'type': typeValue,
        'text': text.trim(),
        'postId': postId.trim(),
        'reelId': reelId.trim(),
        'mediaUrl': mediaUrl.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'seen': false,
      },
    );

    batch.set(
      conversation,
      <String, dynamic>{
        'participantUids': <String>[
          currentUser.uid,
          normalizedReceiverUid,
        ],
        'lastMessage': lastMessage,
        'lastMessageType': typeValue,
        'lastMessageAt':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
        'unreadCounts': <String, dynamic>{
          currentUser.uid:
              FieldValue.increment(0),
          normalizedReceiverUid:
              FieldValue.increment(1),
        },
      },
      SetOptions(merge: true),
    );

    await batch.commit();

    // Create the in-app notification record after the message
    // has been successfully written. Notification failure must
    // never prevent the message itself from being sent.
    try {
      await NotificationService.createMessageNotification(
        recipientUid: normalizedReceiverUid,
        senderUid: currentUser.uid,
        conversationId: normalizedConversationId,
        message: lastMessage,
        senderName: currentUser.displayName,
        senderPhotoUrl: currentUser.photoURL,
      );
    } catch (error) {
      debugPrintNotification(
        'Unable to create message notification: $error',
      );
    }

    return message.id;
  }

  // ===========================================================================
  // MARK MESSAGES SEEN
  // ===========================================================================

  static Future<void> markMessagesSeen({
    required String conversationId,
  }) async {
    final User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      return;
    }

    final String normalizedConversationId =
        conversationId.trim();

    if (normalizedConversationId.isEmpty) {
      return;
    }

    final DocumentReference<Map<String, dynamic>>
        conversation =
        _conversations.doc(
      normalizedConversationId,
    );

    final QuerySnapshot<Map<String, dynamic>>
        snapshot =
        await conversation
            .collection('messages')
            .where(
              'receiverUid',
              isEqualTo: currentUser.uid,
            )
            .where(
              'seen',
              isEqualTo: false,
            )
            .limit(100)
            .get();

    final WriteBatch batch =
        _firestore.batch();

    for (
      final QueryDocumentSnapshot<
          Map<String, dynamic>> document
      in snapshot.docs
    ) {
      batch.update(
        document.reference,
        <String, dynamic>{
          'seen': true,
        },
      );
    }

    batch.set(
      conversation,
      <String, dynamic>{
        'unreadCounts': <String, dynamic>{
          currentUser.uid: 0,
        },
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  // ===========================================================================
  // GET TOTAL UNREAD COUNT
  // ===========================================================================

  static Future<int> getUnreadCount() async {
    final User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      return 0;
    }

    final QuerySnapshot<Map<String, dynamic>>
        conversations =
        await _conversations
            .where(
              'participantUids',
              arrayContains: currentUser.uid,
            )
            .get();

    int unread = 0;

    for (
      final QueryDocumentSnapshot<
          Map<String, dynamic>> conversation
      in conversations.docs
    ) {
      final dynamic rawUnreadCounts =
          conversation.data()['unreadCounts'];

      if (rawUnreadCounts is Map) {
        final dynamic value =
            rawUnreadCounts[currentUser.uid];

        if (value is num) {
          unread += value.toInt();
        }
      }
    }

    return unread;
  }
}

// ============================================================================
// FIRESTORE TIMESTAMP HELPER
// ============================================================================

DateTime? _timestampToDateTime(
  dynamic value,
) {
  if (value is Timestamp) {
    return value.toDate();
  }

  if (value is DateTime) {
    return value;
  }

  return null;
}