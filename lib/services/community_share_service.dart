import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommunityShareService {
  CommunityShareService._();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static final FirebaseAuth _auth =
      FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>>
      get _sharesCollection =>
          _firestore.collection('postShares');

  /// Shares a community post with another AgriAI user.
  ///
  /// Returns the created share document ID.
  static Future<String> sharePostToUser({
    required String postId,
    required String toUid,
  }) async {
    final User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'not-authenticated',
        message: 'You must be signed in to share a post.',
      );
    }

    final String fromUid = currentUser.uid;
    final String normalizedToUid = toUid.trim();

    if (postId.trim().isEmpty) {
      throw ArgumentError('Post ID cannot be empty.');
    }

    if (normalizedToUid.isEmpty) {
      throw ArgumentError('Recipient user cannot be empty.');
    }

    if (normalizedToUid == fromUid) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'cannot-share-to-self',
        message: 'You cannot share a post with yourself.',
      );
    }

    final DocumentReference<Map<String, dynamic>>
        shareReference =
        _sharesCollection.doc();

    await shareReference.set(
      <String, dynamic>{
        'fromUid': fromUid,
        'toUid': normalizedToUid,
        'postId': postId.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      },
    );

    return shareReference.id;
  }

  /// Returns posts shared with the currently signed-in user.
  ///
  /// Results are ordered newest first.
  static Stream<QuerySnapshot<Map<String, dynamic>>>
      getReceivedShares({
    int limit = 50,
  }) {
    final User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      return const Stream<
          QuerySnapshot<Map<String, dynamic>>>.empty();
    }

    final int safeLimit = limit < 1 ? 1 : limit;

    return _sharesCollection
        .where('toUid', isEqualTo: currentUser.uid)
        .orderBy('createdAt', descending: true)
        .limit(safeLimit)
        .snapshots();
  }

  /// Returns the posts shared by the currently signed-in user.
  static Stream<QuerySnapshot<Map<String, dynamic>>>
      getSentShares({
    int limit = 50,
  }) {
    final User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      return const Stream<
          QuerySnapshot<Map<String, dynamic>>>.empty();
    }

    final int safeLimit = limit < 1 ? 1 : limit;

    return _sharesCollection
        .where('fromUid', isEqualTo: currentUser.uid)
        .orderBy('createdAt', descending: true)
        .limit(safeLimit)
        .snapshots();
  }

  /// Deletes a share record.
  static Future<void> deleteShare(
    String shareId,
  ) async {
    final User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'not-authenticated',
        message: 'You must be signed in.',
      );
    }

    final String normalizedShareId = shareId.trim();

    if (normalizedShareId.isEmpty) {
      throw ArgumentError('Share ID cannot be empty.');
    }

    final DocumentReference<Map<String, dynamic>>
        shareReference =
        _sharesCollection.doc(normalizedShareId);

    final DocumentSnapshot<Map<String, dynamic>>
        snapshot =
        await shareReference.get();

    if (!snapshot.exists) {
      return;
    }

    final Map<String, dynamic> data =
        snapshot.data() ?? <String, dynamic>{};

    final String fromUid =
        '${data['fromUid'] ?? ''}';

    final String toUid =
        '${data['toUid'] ?? ''}';

    if (fromUid != currentUser.uid &&
        toUid != currentUser.uid) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message:
            'You are not allowed to delete this share.',
      );
    }

    await shareReference.delete();
  }

  /// Checks whether the current user has already shared
  /// a specific post with a specific recipient.
  static Future<bool> hasSharedWithUser({
    required String postId,
    required String toUid,
  }) async {
    final User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      return false;
    }

    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _sharesCollection
            .where(
              'fromUid',
              isEqualTo: currentUser.uid,
            )
            .where(
              'toUid',
              isEqualTo: toUid.trim(),
            )
            .where(
              'postId',
              isEqualTo: postId.trim(),
            )
            .limit(1)
            .get();

    return snapshot.docs.isNotEmpty;
  }
}