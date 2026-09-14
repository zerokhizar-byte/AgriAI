import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommunitySavedPostsService {
  CommunitySavedPostsService._();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static final FirebaseAuth _auth =
      FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> _savedPosts(
    String uid,
  ) =>
      _firestore
          .collection('users')
          .doc(uid)
          .collection('savedPosts');

  static Future<bool> hasSaved({
    required String postId,
  }) async {
    final User? user = _auth.currentUser;
    final String cleanPostId = postId.trim();

    if (user == null || cleanPostId.isEmpty) {
      return false;
    }

    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _savedPosts(user.uid).doc(cleanPostId).get();

    return snapshot.exists;
  }

  static Future<bool> toggleSaved({
    required String postId,
    required String postOwnerUid,
    required String userId,
    required String displayName,
    required String text,
    required String postType,
    required String mediaUrl,
  }) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'not-authenticated',
        message: 'You must be signed in to save a post.',
      );
    }

    final String cleanPostId = postId.trim();

    if (cleanPostId.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-post-id',
        message: 'Invalid community post ID.',
      );
    }

    final DocumentReference<Map<String, dynamic>> savedRef =
        _savedPosts(user.uid).doc(cleanPostId);

    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await savedRef.get();

    if (snapshot.exists) {
      await savedRef.delete();
      return false;
    }

    await savedRef.set(<String, dynamic>{
      'postId': cleanPostId,
      'postOwnerUid': postOwnerUid,
      'userId': userId,
      'displayName': displayName,
      'text': text,
      'postType': postType,
      'mediaUrl': mediaUrl,
      'savedAt': FieldValue.serverTimestamp(),
    });

    return true;
  }
}
