import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'notification_service.dart';

enum ConnectionStatus {
  none,
  pending,
  incoming,
  connected,
}

class ConnectionService {
  ConnectionService._();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static final FirebaseAuth _auth =
      FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>>
      get _requests =>
          _firestore.collection('connectionRequests');

  static CollectionReference<Map<String, dynamic>>
      get _connections =>
          _firestore.collection('connections');

  static CollectionReference<Map<String, dynamic>>
      get _users =>
          _firestore.collection('users');

  static String _requestId(
    String fromUid,
    String toUid,
  ) {
    return '${fromUid.trim()}_${toUid.trim()}';
  }

  static String _connectionId(
    String firstUid,
    String secondUid,
  ) {
    final List<String> uids = <String>[
      firstUid.trim(),
      secondUid.trim(),
    ]..sort();

    return '${uids[0]}_${uids[1]}';
  }

  static Future<ConnectionStatus> getStatus({
    required String otherUid,
  }) async {
    final User? currentUser = _auth.currentUser;
    final String other = otherUid.trim();

    if (currentUser == null ||
        other.isEmpty ||
        other == currentUser.uid) {
      return ConnectionStatus.none;
    }

    final String currentUid = currentUser.uid;

    final DocumentSnapshot<Map<String, dynamic>>
        connection =
        await _connections
            .doc(
              _connectionId(
                currentUid,
                other,
              ),
            )
            .get();

    if (connection.exists) {
      return ConnectionStatus.connected;
    }

    final DocumentSnapshot<Map<String, dynamic>>
        outgoing =
        await _requests
            .doc(
              _requestId(
                currentUid,
                other,
              ),
            )
            .get();

    if (outgoing.exists &&
        outgoing.data()?['status'] == 'pending') {
      return ConnectionStatus.pending;
    }

    final DocumentSnapshot<Map<String, dynamic>>
        incoming =
        await _requests
            .doc(
              _requestId(
                other,
                currentUid,
              ),
            )
            .get();

    if (incoming.exists &&
        incoming.data()?['status'] == 'pending') {
      return ConnectionStatus.incoming;
    }

    return ConnectionStatus.none;
  }

  static Future<void> sendRequest({
    required String toUid,
  }) async {
    final User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'not-authenticated',
        message: 'Please sign in first.',
      );
    }

    final String fromUid = currentUser.uid;
    final String recipientUid = toUid.trim();

    if (recipientUid.isEmpty) {
      throw ArgumentError(
        'User ID cannot be empty.',
      );
    }

    if (recipientUid == fromUid) {
      throw ArgumentError(
        'You cannot connect with yourself.',
      );
    }

    final ConnectionStatus status =
        await getStatus(
      otherUid: recipientUid,
    );

    if (status == ConnectionStatus.connected) {
      return;
    }

    if (status == ConnectionStatus.pending) {
      return;
    }

    if (status == ConnectionStatus.incoming) {
      await acceptRequest(
        fromUid: recipientUid,
      );
      return;
    }

    final String requestId =
        _requestId(
      fromUid,
      recipientUid,
    );

    final DocumentReference<Map<String, dynamic>>
        request =
        _requests.doc(requestId);

    final DocumentSnapshot<Map<String, dynamic>>
        senderSnapshot =
        await _users.doc(fromUid).get();

    final Map<String, dynamic>? senderData =
        senderSnapshot.data();

    final String senderName =
        (senderData?['displayName']?.toString() ??
                currentUser.displayName ??
                '')
            .trim();

    final String senderPhotoUrl =
        (senderData?['photoUrl']?.toString() ??
                currentUser.photoURL ??
                '')
            .trim();

    final WriteBatch batch =
        _firestore.batch();

    batch.set(
      request,
      <String, dynamic>{
        'fromUid': fromUid,
        'toUid': recipientUid,
        'status': 'pending',
        'createdAt':
            FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();

    try {
      await NotificationService
          .createConnectionRequestNotification(
        recipientUid: recipientUid,
        senderUid: fromUid,
        senderName: senderName,
        senderPhotoUrl:
            senderPhotoUrl,
        connectionRequestId:
            requestId,
      );
    } catch (error) {
      // The connection request has already been created.
      // Notification failure should not cancel the request.
      // ignore: avoid_print
      print(
        'AgriAI Connection Notification Error: '
        '$error',
      );
    }
  }

  static Future<void> acceptRequest({
    required String fromUid,
  }) async {
    final User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'not-authenticated',
        message: 'Please sign in first.',
      );
    }

    final String requesterUid =
        fromUid.trim();

    final String currentUid =
        currentUser.uid;

    if (requesterUid.isEmpty ||
        requesterUid == currentUid) {
      throw ArgumentError(
        'Invalid connection request.',
      );
    }

    final DocumentReference<Map<String, dynamic>>
        request =
        _requests.doc(
      _requestId(
        requesterUid,
        currentUid,
      ),
    );

    final DocumentSnapshot<Map<String, dynamic>>
        requestSnapshot =
        await request.get();

    if (!requestSnapshot.exists ||
        requestSnapshot.data()?['status'] !=
            'pending') {
      return;
    }

    final String connectionId =
        _connectionId(
      requesterUid,
      currentUid,
    );

    final WriteBatch batch =
        _firestore.batch();

    batch.set(
      _connections.doc(connectionId),
      <String, dynamic>{
        'user1Uid': requesterUid,
        'user2Uid': currentUid,
        'connectedAt':
            FieldValue.serverTimestamp(),
      },
    );

    batch.update(
      request,
      <String, dynamic>{
        'status': 'accepted',
        'acceptedAt':
            FieldValue.serverTimestamp(),
      },
    );

    batch.delete(
      _requests.doc(
        _requestId(
          currentUid,
          requesterUid,
        ),
      ),
    );

    await batch.commit();
  }

  static Future<void> cancelRequest({
    required String toUid,
  }) async {
    final User? currentUser =
        _auth.currentUser;

    if (currentUser == null) {
      return;
    }

    await _requests
        .doc(
          _requestId(
            currentUser.uid,
            toUid,
          ),
        )
        .delete();
  }

  static Future<void> declineRequest({
    required String fromUid,
  }) async {
    final User? currentUser =
        _auth.currentUser;

    if (currentUser == null) {
      return;
    }

    await _requests
        .doc(
          _requestId(
            fromUid,
            currentUser.uid,
          ),
        )
        .delete();
  }

  static Future<void> removeConnection({
    required String otherUid,
  }) async {
    final User? currentUser =
        _auth.currentUser;

    if (currentUser == null) {
      return;
    }

    await _connections
        .doc(
          _connectionId(
            currentUser.uid,
            otherUid,
          ),
        )
        .delete();
  }
}