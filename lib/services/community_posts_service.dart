import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommunityPostsService {
  CommunityPostsService._();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;
  static final FirebaseAuth _auth =
      FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> get _posts =>
      _firestore.collection('communityPosts');

  static Future<String> createPost({
    required String text,
    required String postType,
    String? mediaUrl,
    String? mediaType,
  }) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'not-authenticated',
        message: 'You must be signed in to create a post.',
      );
    }

    final String cleanText = text.trim();
    if (cleanText.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'empty-post',
        message: 'A post cannot be empty.',
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

    final DocumentReference<Map<String, dynamic>> ref =
        _posts.doc();

    await ref.set(<String, dynamic>{
      'uid': user.uid,
      'userId': userId,
      'displayName':
          displayName.isEmpty ? 'AgriAI Farmer' : displayName,
      'photoUrl': photoUrl,
      'text': cleanText,
      'postType': postType.trim().isEmpty ? 'farming_update' : postType,
      'mediaUrl': mediaUrl?.trim() ?? '',
      'mediaType': mediaType?.trim() ?? '',
      'likesCount': 0,
      'commentsCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return ref.id;
  }

  static Future<List<CommunityPostData>> getPosts({
    int limit = 50,
  }) async {
    final int safeLimit = limit.clamp(1, 100);

    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _posts
            .orderBy('createdAt', descending: true)
            .limit(safeLimit)
            .get();

    return snapshot.docs
        .map(CommunityPostData.fromFirestore)
        .where((CommunityPostData post) => post.text.isNotEmpty)
        .toList();
  }

  static Future<void> updatePost({
    required String postId,
    required String text,
  }) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'not-authenticated',
        message: 'You must be signed in.',
      );
    }

    final String cleanText = text.trim();
    if (cleanText.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'empty-post',
        message: 'Post text cannot be empty.',
      );
    }

    final DocumentReference<Map<String, dynamic>> ref =
        _posts.doc(postId.trim());

    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await ref.get();

    if (!snapshot.exists) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'post-not-found',
        message: 'Post not found.',
      );
    }

    final Map<String, dynamic> data =
        snapshot.data() ?? <String, dynamic>{};

    if ('${data['uid'] ?? ''}' != user.uid) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'You can only edit your own posts.',
      );
    }

    await ref.update(<String, dynamic>{
      'text': cleanText,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deletePost({
    required String postId,
  }) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'not-authenticated',
        message: 'You must be signed in.',
      );
    }

    final DocumentReference<Map<String, dynamic>> ref =
        _posts.doc(postId.trim());

    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await ref.get();

    if (!snapshot.exists) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'post-not-found',
        message: 'Post not found.',
      );
    }

    final Map<String, dynamic> data =
        snapshot.data() ?? <String, dynamic>{};

    if ('${data['uid'] ?? ''}' != user.uid) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'You can only delete your own posts.',
      );
    }

    await ref.delete();
  }

  static Future<bool> hasLiked({
    required String postId,
  }) async {
    final User? user = _auth.currentUser;
    if (user == null || postId.trim().isEmpty) {
      return false;
    }

    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _posts
            .doc(postId.trim())
            .collection('likes')
            .doc(user.uid)
            .get();

    return snapshot.exists;
  }

  static Future<CommunityLikeResult> toggleLike({
    required String postId,
  }) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'not-authenticated',
        message: 'You must be signed in to like a post.',
      );
    }

    final DocumentReference<Map<String, dynamic>> postRef =
        _posts.doc(postId.trim());

    final DocumentReference<Map<String, dynamic>> likeRef =
        postRef.collection('likes').doc(user.uid);

    return _firestore.runTransaction<CommunityLikeResult>(
      (Transaction transaction) async {
        final DocumentSnapshot<Map<String, dynamic>> postSnapshot =
            await transaction.get(postRef);
        final DocumentSnapshot<Map<String, dynamic>> likeSnapshot =
            await transaction.get(likeRef);

        if (!postSnapshot.exists) {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'post-not-found',
            message: 'Post not found.',
          );
        }

        final Map<String, dynamic> data =
            postSnapshot.data() ?? <String, dynamic>{};

        final int current =
            _toInt(data['likesCount']);

        if (likeSnapshot.exists) {
          final int next = current > 0 ? current - 1 : 0;
          transaction.delete(likeRef);
          transaction.update(postRef, <String, dynamic>{
            'likesCount': next,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          return CommunityLikeResult(
            liked: false,
            likesCount: next,
          );
        }

        transaction.set(likeRef, <String, dynamic>{
          'uid': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        transaction.update(postRef, <String, dynamic>{
          'likesCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return CommunityLikeResult(
          liked: true,
          likesCount: current + 1,
        );
      },
    );
  }

  static int _toInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse('$value') ?? 0;
  }
}

class CommunityLikeResult {
  final bool liked;
  final int likesCount;

  const CommunityLikeResult({
    required this.liked,
    required this.likesCount,
  });
}

class CommunityPostData {
  final String id;
  final String uid;
  final String userId;
  final String displayName;
  final String photoUrl;
  final String text;
  final String postType;
  final String mediaUrl;
  final String mediaType;
  final int likesCount;
  final int commentsCount;
  final DateTime? createdAt;

  const CommunityPostData({
    required this.id,
    required this.uid,
    required this.userId,
    required this.displayName,
    required this.photoUrl,
    required this.text,
    required this.postType,
    required this.mediaUrl,
    required this.mediaType,
    required this.likesCount,
    required this.commentsCount,
    required this.createdAt,
  });

  factory CommunityPostData.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final Map<String, dynamic> data = document.data();
    final dynamic timestamp = data['createdAt'];

    return CommunityPostData(
      id: document.id,
      uid: '${data['uid'] ?? ''}'.trim(),
      userId: '${data['userId'] ?? ''}'.trim(),
      displayName:
          '${data['displayName'] ?? 'AgriAI Farmer'}'.trim().isEmpty
              ? 'AgriAI Farmer'
              : '${data['displayName'] ?? 'AgriAI Farmer'}'.trim(),
      photoUrl: '${data['photoUrl'] ?? ''}'.trim(),
      text: '${data['text'] ?? ''}'.trim(),
      postType: '${data['postType'] ?? 'farming_update'}'.trim(),
      mediaUrl: '${data['mediaUrl'] ?? ''}'.trim(),
      mediaType: '${data['mediaType'] ?? ''}'.trim(),
      likesCount: _toInt(data['likesCount']),
      commentsCount: _toInt(data['commentsCount']),
      createdAt:
          timestamp is Timestamp ? timestamp.toDate() : null,
    );
  }

  static int _toInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse('$value') ?? 0;
  }
}
