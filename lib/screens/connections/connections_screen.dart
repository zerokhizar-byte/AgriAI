import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../profile/public_farmer_profile_screen.dart';

class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen>
    with SingleTickerProviderStateMixin {
  static const Color primary = Color(0xFF2E7D32);
  static const Color background = Color(0xFFF6FAF7);
  static const Color dark = Color(0xFF183125);
  static const Color muted = Color(0xFF718078);

  late final TabController _tabs;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get _me => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _incomingStream() {
    final String? uid = _me?.uid;
    if (uid == null) {
      return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }
    return _db
        .collection('connectionRequests')
        .where('toUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _outgoingStream() {
    final String? uid = _me?.uid;
    if (uid == null) {
      return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }
    return _db
        .collection('connectionRequests')
        .where('fromUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Stream<List<String>> _connectionUidsStream() {
    final String? uid = _me?.uid;
    if (uid == null) {
      return Stream<List<String>>.value(const <String>[]);
    }

    final Stream<QuerySnapshot<Map<String, dynamic>>> first = _db
        .collection('connections')
        .where('user1Uid', isEqualTo: uid)
        .snapshots();

    final Stream<QuerySnapshot<Map<String, dynamic>>> second = _db
        .collection('connections')
        .where('user2Uid', isEqualTo: uid)
        .snapshots();

    return _combineConnectionStreams(first, second);
  }

  Stream<List<String>> _combineConnectionStreams(
    Stream<QuerySnapshot<Map<String, dynamic>>> first,
    Stream<QuerySnapshot<Map<String, dynamic>>> second,
  ) async* {
    List<QueryDocumentSnapshot<Map<String, dynamic>>>? firstDocs;
    List<QueryDocumentSnapshot<Map<String, dynamic>>>? secondDocs;

    final StreamController<List<String>> controller =
        StreamController<List<String>>();

    void emit() {
      final Set<String> ids = <String>{};

      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in firstDocs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[]) {
        final String id = '${doc.data()['user2Uid'] ?? ''}'.trim();
        if (id.isNotEmpty) ids.add(id);
      }

      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in secondDocs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[]) {
        final String id = '${doc.data()['user1Uid'] ?? ''}'.trim();
        if (id.isNotEmpty) ids.add(id);
      }

      controller.add(ids.toList());
    }

    final StreamSubscription<QuerySnapshot<Map<String, dynamic>>> a =
        first.listen((value) {
      firstDocs = value.docs;
      emit();
    });

    final StreamSubscription<QuerySnapshot<Map<String, dynamic>>> b =
        second.listen((value) {
      secondDocs = value.docs;
      emit();
    });

    try {
      yield* controller.stream;
    } finally {
      await a.cancel();
      await b.cancel();
      await controller.close();
    }
  }

  Future<Map<String, dynamic>?> _user(String uid) async {
    final DocumentSnapshot<Map<String, dynamic>> doc =
        await _db.collection('users').doc(uid).get();

    if (!doc.exists) return null;

    return <String, dynamic>{
      'uid': uid,
      ...?doc.data(),
    };
  }

  Future<void> _accept(
    String requestId,
    String otherUid,
  ) async {
    final String? uid = _me?.uid;
    if (uid == null) return;

    try {
      final String first =
          uid.compareTo(otherUid) < 0 ? uid : otherUid;
      final String second =
          uid.compareTo(otherUid) < 0 ? otherUid : uid;

      final WriteBatch batch = _db.batch();

      batch.set(
        _db.collection('connections').doc('${first}_$second'),
        <String, dynamic>{
          'user1Uid': first,
          'user2Uid': second,
          'connectedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      batch.update(
        _db.collection('connectionRequests').doc(requestId),
        <String, dynamic>{
          'status': 'accepted',
          'respondedAt': FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();
      _message('Connection accepted.');
    } catch (e) {
      _message('Unable to accept request: $e');
    }
  }

  Future<void> _reject(String requestId) async {
    try {
      await _db
          .collection('connectionRequests')
          .doc(requestId)
          .update(<String, dynamic>{
        'status': 'rejected',
        'respondedAt': FieldValue.serverTimestamp(),
      });
      _message('Connection request declined.');
    } catch (e) {
      _message('Unable to decline request: $e');
    }
  }

  Future<void> _cancel(String requestId) async {
    try {
      await _db.collection('connectionRequests').doc(requestId).delete();
      _message('Connection request cancelled.');
    } catch (e) {
      _message('Unable to cancel request: $e');
    }
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(value),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: dark,
        elevation: 0,
        title: const Text(
          'Connections',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 21,
          ),
        ),
        bottom: TabBar(
          controller: _tabs,
          labelColor: primary,
          unselectedLabelColor: muted,
          indicatorColor: primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
          tabs: const <Widget>[
            Tab(text: 'Connections'),
            Tab(text: 'Requests'),
            Tab(text: 'Sent'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: <Widget>[
          _ConnectionsList(
            stream: _connectionUidsStream(),
            loadUser: _user,
          ),
          _RequestsList(
            stream: _incomingStream(),
            loadUser: _user,
            onAccept: _accept,
            onReject: _reject,
          ),
          _SentList(
            stream: _outgoingStream(),
            loadUser: _user,
            onCancel: _cancel,
          ),
        ],
      ),
    );
  }
}

class _ConnectionsList extends StatelessWidget {
  final Stream<List<String>> stream;
  final Future<Map<String, dynamic>?> Function(String) loadUser;

  const _ConnectionsList({
    required this.stream,
    required this.loadUser,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<String>>(
      stream: stream,
      builder: (
        BuildContext context,
        AsyncSnapshot<List<String>> snapshot,
      ) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const _Loading();
        }

        if (snapshot.hasError) {
          return const _EmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'Unable to load connections',
            subtitle: 'Check your connection and try again.',
          );
        }

        final List<String> ids = snapshot.data ?? <String>[];

        if (ids.isEmpty) {
          return const _EmptyState(
            icon: Icons.people_outline_rounded,
            title: 'No connections yet',
            subtitle: 'Search for farmers and connect with them.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
          itemCount: ids.length,
          separatorBuilder: (_, _) => const SizedBox(height: 9),
          itemBuilder: (BuildContext context, int index) {
            return FutureBuilder<Map<String, dynamic>?>(
              future: loadUser(ids[index]),
              builder: (
                BuildContext context,
                AsyncSnapshot<Map<String, dynamic>?> userSnapshot,
              ) {
                if (!userSnapshot.hasData) {
                  return const _UserLoadingTile();
                }

                final Map<String, dynamic>? data = userSnapshot.data;
                if (data == null) {
                  return const SizedBox.shrink();
                }

                return InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PublicFarmerProfileScreen(
                          uid: ids[index],
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: _FarmerTile(
                    data: data,
                    action: _TileButton(
                    label: 'Connected',
                    icon: Icons.check_circle_rounded,
                    onTap: null,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _RequestsList extends StatelessWidget {
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final Future<Map<String, dynamic>?> Function(String) loadUser;
  final Future<void> Function(String, String) onAccept;
  final Future<void> Function(String) onReject;

  const _RequestsList({
    required this.stream,
    required this.loadUser,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (
        BuildContext context,
        AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
      ) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const _Loading();
        }

        if (snapshot.hasError) {
          return const _EmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'Unable to load requests',
            subtitle: 'Check your connection and try again.',
          );
        }

        final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs =
            snapshot.data?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[];

        if (docs.isEmpty) {
          return const _EmptyState(
            icon: Icons.person_add_alt_1_rounded,
            title: 'No connection requests',
            subtitle: 'New farmer connection requests will appear here.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
          itemCount: docs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 9),
          itemBuilder: (BuildContext context, int index) {
            final QueryDocumentSnapshot<Map<String, dynamic>> request = docs[index];
            final String uid = '${request.data()['fromUid'] ?? ''}'.trim();

            return FutureBuilder<Map<String, dynamic>?>(
              future: loadUser(uid),
              builder: (
                BuildContext context,
                AsyncSnapshot<Map<String, dynamic>?> userSnapshot,
              ) {
                if (!userSnapshot.hasData) {
                  return const _UserLoadingTile();
                }

                final Map<String, dynamic>? data = userSnapshot.data;
                if (data == null) return const SizedBox.shrink();

                return _FarmerTile(
                  data: data,
                  action: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _IconAction(
                        icon: Icons.close_rounded,
                        tooltip: 'Decline',
                        onTap: () => unawaited(
                          onReject(request.id),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _TileButton(
                        label: 'Accept',
                        icon: Icons.check_rounded,
                        onTap: () => unawaited(
                          onAccept(request.id, uid),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _SentList extends StatelessWidget {
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final Future<Map<String, dynamic>?> Function(String) loadUser;
  final Future<void> Function(String) onCancel;

  const _SentList({
    required this.stream,
    required this.loadUser,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (
        BuildContext context,
        AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
      ) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const _Loading();
        }

        if (snapshot.hasError) {
          return const _EmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'Unable to load sent requests',
            subtitle: 'Check your connection and try again.',
          );
        }

        final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs =
            snapshot.data?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[];

        if (docs.isEmpty) {
          return const _EmptyState(
            icon: Icons.schedule_rounded,
            title: 'No sent requests',
            subtitle: 'Connection requests you send will appear here.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
          itemCount: docs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 9),
          itemBuilder: (BuildContext context, int index) {
            final QueryDocumentSnapshot<Map<String, dynamic>> request = docs[index];
            final String uid = '${request.data()['toUid'] ?? ''}'.trim();

            return FutureBuilder<Map<String, dynamic>?>(
              future: loadUser(uid),
              builder: (
                BuildContext context,
                AsyncSnapshot<Map<String, dynamic>?> userSnapshot,
              ) {
                if (!userSnapshot.hasData) {
                  return const _UserLoadingTile();
                }

                final Map<String, dynamic>? data = userSnapshot.data;
                if (data == null) return const SizedBox.shrink();

                return _FarmerTile(
                  data: data,
                  action: _TileButton(
                    label: 'Cancel',
                    icon: Icons.close_rounded,
                    onTap: () => unawaited(onCancel(request.id)),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _FarmerTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final Widget action;

  const _FarmerTile({
    required this.data,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    final String name =
        '${data['displayName'] ?? 'AgriAI Farmer'}'.trim();
    final String userId = '${data['userId'] ?? ''}'.trim();
    final String photo = '${data['photoUrl'] ?? ''}'.trim();
    final String location = '${data['location'] ?? ''}'.trim();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0EAE3)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          _Avatar(url: photo, name: name),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  name.isEmpty ? 'AgriAI Farmer' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF183125),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (userId.isNotEmpty)
                  Text(
                    '@$userId',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF2E7D32),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                if (location.isNotEmpty)
                  Text(
                    location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF718078),
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          action,
        ],
      ),
    );
  }
}

class _TileButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _TileButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF2E7D32),
          side: const BorderSide(color: Color(0xFFB9D4BE)),
          padding: const EdgeInsets.symmetric(horizontal: 9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
        icon: Icon(icon, size: 14),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 35,
        height: 35,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            foregroundColor: const Color(0xFF718078),
            side: const BorderSide(color: Color(0xFFD8E4DB)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
            ),
          ),
          child: Icon(icon, size: 15),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String url;
  final String name;

  const _Avatar({
    required this.url,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    final String initial = name.trim().isEmpty
        ? 'A'
        : name.trim().substring(0, 1).toUpperCase();

    return CircleAvatar(
      radius: 25,
      backgroundColor: const Color(0xFFE7F3E9),
      backgroundImage: url.isEmpty ? null : NetworkImage(url),
      child: url.isEmpty
          ? Text(
              initial,
              style: const TextStyle(
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            )
          : null,
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFF2E7D32),
        strokeWidth: 2.4,
      ),
    );
  }
}

class _UserLoadingTile extends StatelessWidget {
  const _UserLoadingTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            color: Color(0xFF2E7D32),
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: const Color(0xFFE7F3E9),
                borderRadius: BorderRadius.circular(27),
              ),
              child: Icon(
                icon,
                size: 38,
                color: const Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF183125),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF718078),
                fontSize: 11,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
