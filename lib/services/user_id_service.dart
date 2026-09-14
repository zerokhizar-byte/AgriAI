import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserIdService {
  UserIdService._();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static final FirebaseAuth _auth =
      FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>>
      get _usernamesCollection =>
          _firestore.collection('usernames');

  static String normalizeUserId(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceFirst(RegExp(r'^@'), '');
  }

  static String? validateUserId(String value) {
    final String userId = normalizeUserId(value);

    if (userId.length < 4) {
      return 'User ID must be at least 4 characters.';
    }

    if (userId.length > 20) {
      return 'User ID must be 20 characters or less.';
    }

    final RegExp pattern =
        RegExp(r'^[a-z][a-z0-9_]*$');

    if (!pattern.hasMatch(userId)) {
      return 'Use lowercase letters, numbers and underscores. '
          'It must start with a letter.';
    }

    return null;
  }

  static Future<bool> isUserIdAvailable(
    String userId,
  ) async {
    final String normalized =
        normalizeUserId(userId);

    final String? validationError =
        validateUserId(normalized);

    if (validationError != null) {
      return false;
    }

    final DocumentSnapshot<Map<String, dynamic>>
        snapshot =
        await _usernamesCollection
            .doc(normalized)
            .get();

    if (!snapshot.exists) {
      return true;
    }

    final User? currentUser =
        _auth.currentUser;

    if (currentUser == null) {
      return false;
    }

    final Map<String, dynamic> data =
        snapshot.data() ??
            <String, dynamic>{};

    return '${data['uid'] ?? ''}' ==
        currentUser.uid;
  }

  static Future<void> changeUserId(
    String requestedUserId,
  ) async {
    final User? currentUser =
        _auth.currentUser;

    if (currentUser == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'not-authenticated',
        message:
            'You must be signed in to change your User ID.',
      );
    }

    final String newUserId =
        normalizeUserId(requestedUserId);

    final String? validationError =
        validateUserId(newUserId);

    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    final DocumentReference<Map<String, dynamic>>
        userReference =
        _firestore
            .collection('users')
            .doc(currentUser.uid);

    await _firestore.runTransaction(
      (Transaction transaction) async {
        final DocumentSnapshot<
            Map<String, dynamic>> userSnapshot =
            await transaction.get(
          userReference,
        );

        final Map<String, dynamic> userData =
            userSnapshot.data() ??
                <String, dynamic>{};

        final String oldUserId =
            normalizeUserId(
          '${userData['userId'] ?? ''}',
        );

        final DocumentReference<
            Map<String, dynamic>>
            newUsernameReference =
            _usernamesCollection
                .doc(newUserId);

        final DocumentSnapshot<
            Map<String, dynamic>>
            usernameSnapshot =
            await transaction.get(
          newUsernameReference,
        );

        if (usernameSnapshot.exists) {
          final Map<String, dynamic>
              existingData =
              usernameSnapshot.data() ??
                  <String, dynamic>{};

          final String existingUid =
              '${existingData['uid'] ?? ''}';

          if (existingUid !=
              currentUser.uid) {
            throw FirebaseException(
              plugin: 'cloud_firestore',
              code: 'user-id-taken',
              message:
                  'This AgriAI User ID is already taken.',
            );
          }
        }

        transaction.set(
          newUsernameReference,
          <String, dynamic>{
            'uid': currentUser.uid,
            'userId': newUserId,
            'createdAt':
                FieldValue.serverTimestamp(),
          },
        );

        transaction.set(
          userReference,
          <String, dynamic>{
            'uid': currentUser.uid,
            'userId': newUserId,
            'userIdLower': newUserId,
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        if (oldUserId.isNotEmpty &&
            oldUserId != newUserId) {
          transaction.delete(
            _usernamesCollection.doc(oldUserId),
          );
        }
      },
    );
  }

  static Future<void> ensureCurrentUserReservation(
    String userId,
  ) async {
    final User? currentUser =
        _auth.currentUser;

    if (currentUser == null) {
      return;
    }

    final String normalized =
        normalizeUserId(userId);

    final String? validationError =
        validateUserId(normalized);

    if (validationError != null) {
      return;
    }

    final DocumentReference<
        Map<String, dynamic>>
        usernameReference =
        _usernamesCollection
            .doc(normalized);

    final DocumentSnapshot<
        Map<String, dynamic>>
        snapshot =
        await usernameReference.get();

    if (snapshot.exists) {
      return;
    }

    await usernameReference.set(
      <String, dynamic>{
        'uid': currentUser.uid,
        'userId': normalized,
        'createdAt':
            FieldValue.serverTimestamp(),
      },
    );
  }
}