import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreTest {
  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static Future<void> runTest() async {
    const String testId = 'agriai_connection_test';

    // --------------------------------------------------
    // 1. WRITE TEST
    // --------------------------------------------------
    await _firestore
        .collection('system')
        .doc(testId)
        .set({
      'message': 'AgriAI Firestore connection successful',
      'timestamp': FieldValue.serverTimestamp(),
    });

    // --------------------------------------------------
    // 2. READ TEST
    // --------------------------------------------------
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _firestore
            .collection('system')
            .doc(testId)
            .get();

    if (!snapshot.exists) {
      throw Exception(
        'Firestore document was not found after writing.',
      );
    }

    final Map<String, dynamic>? data = snapshot.data();

    if (data == null) {
      throw Exception(
        'Firestore returned empty document data.',
      );
    }

    if (data['message'] !=
        'AgriAI Firestore connection successful') {
      throw Exception(
        'Firestore returned incorrect data.',
      );
    }

    // --------------------------------------------------
    // 3. DELETE TEST
    // --------------------------------------------------
    await _firestore
        .collection('system')
        .doc(testId)
        .delete();

    // --------------------------------------------------
    // 4. VERIFY DELETE
    // --------------------------------------------------
    final DocumentSnapshot<Map<String, dynamic>>
        deletedSnapshot = await _firestore
            .collection('system')
            .doc(testId)
            .get();

    if (deletedSnapshot.exists) {
      throw Exception(
        'Firestore document still exists after deletion.',
      );
    }
  }
}