import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../direct_messages/direct_messages_screen.dart';
import '../profile/public_farmer_profile_screen.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  static const Color primary = Color(0xFF2E7D32);
  static const Color bg = Color(0xFFF6FAF7);
  static const Color text = Color(0xFF183125);

  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';
  bool _loading = false;
  String? _error;
  List<_Farmer> _farmers = <_Farmer>[];
  final Map<String, _ConnectionStatus> _status =
      <String, _ConnectionStatus>{};
  final Set<String> _busy = <String>{};

  User? get _me => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_changed);
    unawaited(_search(''));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller
      ..removeListener(_changed)
      ..dispose();
    super.dispose();
  }

  void _changed() {
    final String q = _controller.text.trim().toLowerCase();
    if (q == _query) return;
    setState(() => _query = q);
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => unawaited(_search(q)),
    );
  }

  Future<void> _search(String q) async {
    final User? me = _me;
    if (me == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Please sign in to search for farmers.';
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final CollectionReference<Map<String, dynamic>> users =
          FirebaseFirestore.instance.collection('users');

      final Query<Map<String, dynamic>> query = q.isEmpty
          ? users.orderBy('userIdLower').limit(30)
          : users
              .orderBy('userIdLower')
              .startAt(<String>[q])
              .endAt(<String>['$q\uf8ff'])
              .limit(30);

      final QuerySnapshot<Map<String, dynamic>> snap = await query.get();
      final List<_Farmer> result = <_Farmer>[];

      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in snap.docs) {
        final Map<String, dynamic> d = doc.data();
        final String uid = '${d['uid'] ?? doc.id}'.trim();
        final String id = '${d['userId'] ?? ''}'.trim();
        if (uid.isEmpty || uid == me.uid || id.isEmpty) continue;

        final String lower =
            '${d['userIdLower'] ?? id}'.trim().toLowerCase();
        if (q.isNotEmpty && !lower.startsWith(q)) continue;

        result.add(
          _Farmer(
            uid: uid,
            userId: id,
            name: '${d['displayName'] ?? 'AgriAI Farmer'}'.trim(),
            photoUrl: '${d['photoUrl'] ?? ''}'.trim(),
            location: '${d['location'] ?? ''}'.trim(),
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _farmers = result;
        _loading = false;
      });
      await _loadStatuses(result);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() {
        _farmers = <_Farmer>[];
        _loading = false;
        _error = 'Search failed: ${e.message ?? e.code}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _farmers = <_Farmer>[];
        _loading = false;
        _error = 'Search failed: $e';
      });
    }
  }

  Future<void> _loadStatuses(List<_Farmer> farmers) async {
    final User? me = _me;
    if (me == null) return;

    final Map<String, _ConnectionStatus> values =
        <String, _ConnectionStatus>{};

    for (final _Farmer farmer in farmers) {
      values[farmer.uid] = await _getStatus(me.uid, farmer.uid);
    }

    if (!mounted) return;
    setState(() {
      _status
        ..clear()
        ..addAll(values);
    });
  }

  Future<_ConnectionStatus> _getStatus(String me, String other) async {
    final FirebaseFirestore db = FirebaseFirestore.instance;

    final QuerySnapshot<Map<String, dynamic>> direct = await db
        .collection('connections')
        .where('user1Uid', isEqualTo: me)
        .where('user2Uid', isEqualTo: other)
        .limit(1)
        .get();
    if (direct.docs.isNotEmpty) return _ConnectionStatus.connected;

    final QuerySnapshot<Map<String, dynamic>> reverse = await db
        .collection('connections')
        .where('user1Uid', isEqualTo: other)
        .where('user2Uid', isEqualTo: me)
        .limit(1)
        .get();
    if (reverse.docs.isNotEmpty) return _ConnectionStatus.connected;

    final QuerySnapshot<Map<String, dynamic>> outgoing = await db
        .collection('connectionRequests')
        .where('fromUid', isEqualTo: me)
        .where('toUid', isEqualTo: other)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (outgoing.docs.isNotEmpty) return _ConnectionStatus.sent;

    final QuerySnapshot<Map<String, dynamic>> incoming = await db
        .collection('connectionRequests')
        .where('fromUid', isEqualTo: other)
        .where('toUid', isEqualTo: me)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (incoming.docs.isNotEmpty) return _ConnectionStatus.accept;

    return _ConnectionStatus.connect;
  }

  Future<void> _connect(_Farmer farmer) async {
    final User? me = _me;
    if (me == null || _busy.contains(farmer.uid)) return;

    setState(() => _busy.add(farmer.uid));
    try {
      final _ConnectionStatus state = await _getStatus(me.uid, farmer.uid);

      if (state == _ConnectionStatus.connected) {
        _setStatus(farmer.uid, state);
        _message('Already connected with @${farmer.userId}.');
        return;
      }

      if (state == _ConnectionStatus.accept) {
        await _accept(farmer);
        return;
      }

      final FirebaseFirestore db = FirebaseFirestore.instance;
      final QuerySnapshot<Map<String, dynamic>> existing = await db
          .collection('connectionRequests')
          .where('fromUid', isEqualTo: me.uid)
          .where('toUid', isEqualTo: farmer.uid)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (existing.docs.isEmpty) {
        await db.collection('connectionRequests').add(<String, dynamic>{
          'fromUid': me.uid,
          'toUid': farmer.uid,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      _setStatus(farmer.uid, _ConnectionStatus.sent);
      _message('Connection request sent to @${farmer.userId}.');
    } catch (e) {
      _message('Unable to connect: $e');
    } finally {
      if (mounted) setState(() => _busy.remove(farmer.uid));
    }
  }

  Future<void> _accept(_Farmer farmer) async {
    final User? me = _me;
    if (me == null) return;

    final FirebaseFirestore db = FirebaseFirestore.instance;
    final QuerySnapshot<Map<String, dynamic>> requests = await db
        .collection('connectionRequests')
        .where('fromUid', isEqualTo: farmer.uid)
        .where('toUid', isEqualTo: me.uid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (requests.docs.isEmpty) {
      _setStatus(farmer.uid, _ConnectionStatus.connect);
      _message('Request is no longer available.');
      return;
    }

    final String a =
        me.uid.compareTo(farmer.uid) < 0 ? me.uid : farmer.uid;
    final String b =
        me.uid.compareTo(farmer.uid) < 0 ? farmer.uid : me.uid;

    final WriteBatch batch = db.batch();
    batch.set(
      db.collection('connections').doc('${a}_$b'),
      <String, dynamic>{
        'user1Uid': a,
        'user2Uid': b,
        'connectedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    batch.update(
      requests.docs.first.reference,
      <String, dynamic>{
        'status': 'accepted',
        'respondedAt': FieldValue.serverTimestamp(),
      },
    );
    await batch.commit();

    _setStatus(farmer.uid, _ConnectionStatus.connected);
    _message('@${farmer.userId} is now connected with you.');
  }

  Future<void> _cancel(_Farmer farmer) async {
    final User? me = _me;
    if (me == null || _busy.contains(farmer.uid)) return;

    setState(() => _busy.add(farmer.uid));
    try {
      final QuerySnapshot<Map<String, dynamic>> requests =
          await FirebaseFirestore.instance
              .collection('connectionRequests')
              .where('fromUid', isEqualTo: me.uid)
              .where('toUid', isEqualTo: farmer.uid)
              .where('status', isEqualTo: 'pending')
              .limit(1)
              .get();

      if (requests.docs.isNotEmpty) {
        await requests.docs.first.reference.delete();
      }
      _setStatus(farmer.uid, _ConnectionStatus.connect);
      _message('Connection request cancelled.');
    } catch (e) {
      _message('Unable to cancel request: $e');
    } finally {
      if (mounted) setState(() => _busy.remove(farmer.uid));
    }
  }

  Future<void> _reject(_Farmer farmer) async {
    final User? me = _me;
    if (me == null || _busy.contains(farmer.uid)) return;

    setState(() => _busy.add(farmer.uid));
    try {
      final QuerySnapshot<Map<String, dynamic>> requests =
          await FirebaseFirestore.instance
              .collection('connectionRequests')
              .where('fromUid', isEqualTo: farmer.uid)
              .where('toUid', isEqualTo: me.uid)
              .where('status', isEqualTo: 'pending')
              .limit(1)
              .get();

      if (requests.docs.isNotEmpty) {
        await requests.docs.first.reference.update(<String, dynamic>{
          'status': 'rejected',
          'respondedAt': FieldValue.serverTimestamp(),
        });
      }
      _setStatus(farmer.uid, _ConnectionStatus.connect);
      _message('Connection request declined.');
    } catch (e) {
      _message('Unable to decline request: $e');
    } finally {
      if (mounted) setState(() => _busy.remove(farmer.uid));
    }
  }

  void _setStatus(String uid, _ConnectionStatus value) {
    if (!mounted) return;
    setState(() => _status[uid] = value);
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
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
        title: const Text(
          'Find Farmers',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 21),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : () => unawaited(_search(_query)),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: TextField(
              controller: _controller,
              autocorrect: false,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search by @AgriAI User ID',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: _controller.clear,
                        icon: const Icon(Icons.close_rounded),
                      ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 15,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: Color(0xFFE0EAE3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: Color(0xFFE0EAE3)),
                ),
              ),
            ),
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading && _farmers.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: primary, strokeWidth: 2.4),
      );
    }

    if (_error != null) {
      return _MessageState(
        icon: Icons.cloud_off_rounded,
        title: 'Unable to search farmers',
        subtitle: _error!,
        retry: () => unawaited(_search(_query)),
      );
    }

    if (_farmers.isEmpty) {
      return _MessageState(
        icon: Icons.people_outline_rounded,
        title: _query.isEmpty ? 'No farmers found' : 'No farmer found',
        subtitle: _query.isEmpty
            ? 'Farmers with public AgriAI IDs will appear here.'
            : 'Try another AgriAI User ID.',
      );
    }

    return RefreshIndicator(
      color: primary,
      onRefresh: () => _search(_query),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
        itemCount: _farmers.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (BuildContext context, int index) {
          final _Farmer farmer = _farmers[index];
          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PublicFarmerProfileScreen(
                    uid: farmer.uid,
                  ),
                ),
              );
            },
            child: _FarmerCard(
              farmer: farmer,
              status: _status[farmer.uid] ?? _ConnectionStatus.connect,
            busy: _busy.contains(farmer.uid),
            onConnect: () => unawaited(_connect(farmer)),
            onCancel: () => unawaited(_cancel(farmer)),
            onAccept: () => unawaited(_connect(farmer)),
            onReject: () => unawaited(_reject(farmer)),
              onMessage: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const DirectMessagesScreen(),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

enum _ConnectionStatus { connect, sent, accept, connected }

class _Farmer {
  final String uid;
  final String userId;
  final String name;
  final String photoUrl;
  final String location;

  const _Farmer({
    required this.uid,
    required this.userId,
    required this.name,
    required this.photoUrl,
    required this.location,
  });
}

class _FarmerCard extends StatelessWidget {
  final _Farmer farmer;
  final _ConnectionStatus status;
  final bool busy;
  final VoidCallback onConnect;
  final VoidCallback onCancel;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onMessage;

  const _FarmerCard({
    required this.farmer,
    required this.status,
    required this.busy,
    required this.onConnect,
    required this.onCancel,
    required this.onAccept,
    required this.onReject,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFE0EAE3)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          _Avatar(url: farmer.photoUrl, name: farmer.name),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  farmer.name.isEmpty ? 'AgriAI Farmer' : farmer.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF183125),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '@${farmer.userId}',
                  style: const TextStyle(
                    color: Color(0xFF2E7D32),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (farmer.location.isNotEmpty)
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: Color(0xFF718078),
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          farmer.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF718078),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _Action(
            status: status,
            busy: busy,
            onConnect: onConnect,
            onCancel: onCancel,
            onAccept: onAccept,
            onReject: onReject,
            onMessage: onMessage,
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  final _ConnectionStatus status;
  final bool busy;
  final VoidCallback onConnect;
  final VoidCallback onCancel;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onMessage;

  const _Action({
    required this.status,
    required this.busy,
    required this.onConnect,
    required this.onCancel,
    required this.onAccept,
    required this.onReject,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (busy) {
      return const SizedBox(
        width: 88,
        height: 38,
        child: Center(
          child: SizedBox(
            width: 17,
            height: 17,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF2E7D32),
            ),
          ),
        ),
      );
    }

    switch (status) {
      case _ConnectionStatus.connect:
        return _Button(
          label: 'Connect',
          icon: Icons.person_add_alt_1_rounded,
          filled: true,
          onTap: onConnect,
        );
      case _ConnectionStatus.sent:
        return _Button(
          label: 'Sent',
          icon: Icons.schedule_rounded,
          filled: false,
          onTap: onCancel,
        );
      case _ConnectionStatus.accept:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: 34,
              height: 34,
              child: OutlinedButton(
                onPressed: onReject,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  foregroundColor: const Color(0xFF789083),
                  side: const BorderSide(color: Color(0xFFD8E4DB)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                child: const Icon(Icons.close_rounded, size: 15),
              ),
            ),
            const SizedBox(width: 5),
            _Button(
              label: 'Accept',
              icon: Icons.check_rounded,
              filled: true,
              onTap: onAccept,
            ),
          ],
        );
      case _ConnectionStatus.connected:
        return _Button(
          label: 'Message',
          icon: Icons.chat_bubble_outline_rounded,
          filled: false,
          onTap: onMessage,
        );
    }
  }
}

class _Button extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  const _Button({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: filled
          ? FilledButton.icon(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
            )
          : OutlinedButton.icon(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2E7D32),
                side: const BorderSide(color: Color(0xFFB9D4BE)),
                padding: const EdgeInsets.symmetric(horizontal: 9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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

class _Avatar extends StatelessWidget {
  final String url;
  final String name;

  const _Avatar({required this.url, required this.name});

  @override
  Widget build(BuildContext context) {
    final String initial = name.trim().isEmpty
        ? 'A'
        : name.trim().substring(0, 1).toUpperCase();

    return CircleAvatar(
      radius: 26,
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

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? retry;

  const _MessageState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.retry,
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
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF183125),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                height: 1.45,
                color: Color(0xFF718078),
              ),
            ),
            if (retry != null) ...<Widget>[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: retry,
                icon: const Icon(Icons.refresh_rounded, size: 17),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
