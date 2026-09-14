import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  const DirectConversation({
    required this.id,
    required this.participantUids,
    required this.lastMessage,
    required this.lastMessageType,
    required this.lastMessageAt,
    required this.updatedAt,
  });

  String otherParticipantUid(String currentUid) {
    for (final String uid in participantUids) {
      if (uid != currentUid) {
        return uid;
      }
    }

    return '';
  }

  factory DirectConversation.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final Map<String, dynamic> data =
        document.data() ?? <String, dynamic>{};

    return DirectConversation(
      id: document.id,
      participantUids:
          (data['participantUids'] as List<dynamic>?)
                  ?.map((dynamic value) => '$value')
                  .where((String value) => value.isNotEmpty)
                  .toList() ??
              <String>[],
      lastMessage: '${data['lastMessage'] ?? ''}',
      lastMessageType: '${data['lastMessageType'] ?? 'text'}',
      lastMessageAt: _timestampToDateTime(
        data['lastMessageAt'],
      ),
      updatedAt: _timestampToDateTime(
        data['updatedAt'],
      ),
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

  static Future<String> getOrCreateConversation({
    required String otherUid,
  }) async {
    final User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'not-authenticated',
        message: 'You must be signed in to use Direct Messages.',
      );
    }

    final String currentUid = currentUser.uid;
    final String normalizedOtherUid = otherUid.trim();

    if (normalizedOtherUid.isEmpty) {
      throw ArgumentError('Other user ID cannot be empty.');
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

    final DocumentReference<Map<String, dynamic>> reference =
        _conversations.doc(conversationId);

    final DocumentSnapshot<Map<String, dynamic>> snapshot =
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
        },
      );
    }

    return conversationId;
  }

  static Stream<List<DirectConversation>> watchConversations() {
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
            final List<DirectConversation> conversations =
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
                        DateTime.fromMillisecondsSinceEpoch(0);

                final DateTime secondDate =
                    second.updatedAt ??
                        second.lastMessageAt ??
                        DateTime.fromMillisecondsSinceEpoch(0);

                return secondDate.compareTo(firstDate);
              },
            );

            return conversations;
          },
        );
  }

  static Stream<List<DirectMessage>> watchMessages({
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
        .orderBy('createdAt', descending: true)
        .limit(safeLimit)
        .snapshots()
        .map(
          (
            QuerySnapshot<Map<String, dynamic>> snapshot,
          ) {
            final List<DirectMessage> messages =
                snapshot.docs
                    .map(
                      DirectMessage.fromDocument,
                    )
                    .toList();

            messages.sort(
              (
                DirectMessage first,
                DirectMessage second,
              ) {
                final DateTime firstDate =
                    first.createdAt ??
                        DateTime.fromMillisecondsSinceEpoch(0);

                final DateTime secondDate =
                    second.createdAt ??
                        DateTime.fromMillisecondsSinceEpoch(0);

                return firstDate.compareTo(secondDate);
              },
            );

            return messages;
          },
        );
  }

  static Future<String> sendTextMessage({
    required String conversationId,
    required String receiverUid,
    required String text,
  }) async {
    final String value = text.trim();

    if (value.isEmpty) {
      throw ArgumentError('Message cannot be empty.');
    }

    return _sendMessage(
      conversationId: conversationId,
      receiverUid: receiverUid,
      type: DirectMessageType.text,
      text: value,
    );
  }

  static Future<String> sendPostMessage({
    required String conversationId,
    required String receiverUid,
    required String postId,
    String text = '',
    String mediaUrl = '',
  }) async {
    final String normalizedPostId = postId.trim();

    if (normalizedPostId.isEmpty) {
      throw ArgumentError('Post ID cannot be empty.');
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

  static Future<String> sendReelMessage({
    required String conversationId,
    required String receiverUid,
    required String reelId,
    String text = '',
    String mediaUrl = '',
  }) async {
    final String normalizedReelId = reelId.trim();

    if (normalizedReelId.isEmpty) {
      throw ArgumentError('Reel ID cannot be empty.');
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
        message: 'You must be signed in to send messages.',
      );
    }

    final String normalizedConversationId =
        conversationId.trim();
    final String normalizedReceiverUid =
        receiverUid.trim();

    if (normalizedConversationId.isEmpty) {
      throw ArgumentError('Conversation ID cannot be empty.');
    }

    if (normalizedReceiverUid.isEmpty) {
      throw ArgumentError('Receiver ID cannot be empty.');
    }

    if (normalizedReceiverUid == currentUser.uid) {
      throw ArgumentError(
        'You cannot send a message to yourself.',
      );
    }

    final DocumentReference<Map<String, dynamic>> conversation =
        _conversations.doc(normalizedConversationId);

    final DocumentReference<Map<String, dynamic>> message =
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

    final WriteBatch batch = _firestore.batch();

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
        'lastMessageAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();

    return message.id;
  }

  static Future<void> markMessagesSeen({
    required String conversationId,
  }) async {
    final User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      return;
    }

    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _conversations
            .doc(conversationId.trim())
            .collection('messages')
            .where('receiverUid', isEqualTo: currentUser.uid)
            .where('seen', isEqualTo: false)
            .limit(100)
            .get();

    if (snapshot.docs.isEmpty) {
      return;
    }

    final WriteBatch batch = _firestore.batch();

    for (final QueryDocumentSnapshot<Map<String, dynamic>> document
        in snapshot.docs) {
      batch.update(
        document.reference,
        <String, dynamic>{
          'seen': true,
        },
      );
    }

    await batch.commit();
  }

  static Future<int> getUnreadCount() async {
    final User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      return 0;
    }

    final QuerySnapshot<Map<String, dynamic>> conversations =
        await _conversations
            .where(
              'participantUids',
              arrayContains: currentUser.uid,
            )
            .get();

    int unread = 0;

    for (final QueryDocumentSnapshot<Map<String, dynamic>> conversation
        in conversations.docs) {
      final QuerySnapshot<Map<String, dynamic>> messages =
          await conversation.reference
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

      unread += messages.docs.length;
    }

    return unread;
  }
}

DateTime? _timestampToDateTime(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }

  if (value is DateTime) {
    return value;
  }

  return null;
}
