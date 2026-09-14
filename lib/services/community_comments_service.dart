import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommunityCommentsService {
  CommunityCommentsService._();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;
  static final FirebaseAuth _auth =
      FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> _comments(
    String postId,
  ) =>
      _firestore
          .collection('communityPosts')
          .doc(postId)
          .collection('comments');

  static Future<String> createComment({
    required String postId,
    required String text,
  }) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'not-authenticated',
        message: 'You must be signed in to comment.',
      );
    }

    final String cleanPostId = postId.trim();
    final String cleanText = text.trim();

    if (cleanPostId.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-post-id',
        message: 'Invalid community post ID.',
      );
    }
    if (cleanText.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'empty-comment',
        message: 'A comment cannot be empty.',
      );
    }
    if (cleanText.length > 500) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'comment-too-long',
        message: 'A comment can contain at most 500 characters.',
      );
    }

    final DocumentReference<Map<String, dynamic>> postRef =
        _firestore.collection('communityPosts').doc(cleanPostId);

    final DocumentSnapshot<Map<String, dynamic>> postSnapshot =
        await postRef.get();

    if (!postSnapshot.exists) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'post-not-found',
        message: 'This community post no longer exists.',
      );
    }

    final DocumentSnapshot<Map<String, dynamic>> userSnapshot =
        await _firestore.collection('users').doc(user.uid).get();

    final Map<String, dynamic> userData =
        userSnapshot.data() ?? <String, dynamic>{};

    final String displayName =
        '${userData['displayName'] ?? user.displayName ?? 'AgriAI Farmer'}'
            .trim();

    final String userId =
        '${userData['userId'] ?? ''}'.trim();

    final String photoUrl =
        '${userData['photoUrl'] ?? user.photoURL ?? ''}'.trim();

    final DocumentReference<Map<String, dynamic>> commentRef =
        _comments(cleanPostId).doc();

    await _firestore.runTransaction<void>(
      (Transaction transaction) async {
        final DocumentSnapshot<Map<String, dynamic>> latestPost =
            await transaction.get(postRef);

        if (!latestPost.exists) {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'post-not-found',
            message: 'This community post no longer exists.',
          );
        }

        transaction.set(
          commentRef,
          <String, dynamic>{
            'uid': user.uid,
            'userId': userId,
            'displayName': displayName.isEmpty
                ? 'AgriAI Farmer'
                : displayName,
            'photoUrl': photoUrl,
            'text': cleanText,
            'createdAt': FieldValue.serverTimestamp(),
          },
        );

        transaction.update(
          postRef,
          <String, dynamic>{
            'commentsCount': FieldValue.increment(1),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      },
    );

    return commentRef.id;
  }

  static Future<List<CommunityCommentData>> getComments({
    required String postId,
    int limit = 100,
  }) async {
    final String cleanPostId = postId.trim();
    if (cleanPostId.isEmpty) {
      return <CommunityCommentData>[];
    }

    final int safeLimit = limit.clamp(1, 200);

    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _comments(cleanPostId)
            .orderBy('createdAt', descending: false)
            .limit(safeLimit)
            .get();

    return snapshot.docs
        .map(CommunityCommentData.fromFirestore)
        .toList();
  }
}

class CommunityCommentData {
  final String id;
  final String uid;
  final String userId;
  final String displayName;
  final String photoUrl;
  final String text;
  final DateTime? createdAt;

  const CommunityCommentData({
    required this.id,
    required this.uid,
    required this.userId,
    required this.displayName,
    required this.photoUrl,
    required this.text,
    required this.createdAt,
  });

  factory CommunityCommentData.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final Map<String, dynamic> data = document.data();
    final dynamic timestamp = data['createdAt'];

    return CommunityCommentData(
      id: document.id,
      uid: '${data['uid'] ?? ''}'.trim(),
      userId: '${data['userId'] ?? ''}'.trim(),
      displayName:
          '${data['displayName'] ?? 'AgriAI Farmer'}'.trim().isEmpty
              ? 'AgriAI Farmer'
              : '${data['displayName'] ?? 'AgriAI Farmer'}'.trim(),
      photoUrl: '${data['photoUrl'] ?? ''}'.trim(),
      text: '${data['text'] ?? ''}'.trim(),
      createdAt:
          timestamp is Timestamp ? timestamp.toDate() : null,
    );
  }
}
