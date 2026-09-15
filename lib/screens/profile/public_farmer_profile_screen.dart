import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../direct_messages/direct_messages_screen.dart';

class PublicFarmerProfileScreen extends StatefulWidget {
  final String uid;

  const PublicFarmerProfileScreen({
    super.key,
    required this.uid,
  });

  @override
  State<PublicFarmerProfileScreen> createState() =>
      _PublicFarmerProfileScreenState();
}

class _PublicFarmerProfileScreenState
    extends State<PublicFarmerProfileScreen>
    with SingleTickerProviderStateMixin {
  static const Color primary = Color(0xFF2E7D32);
  static const Color background = Color(0xFFF6FAF7);
  static const Color dark = Color(0xFF183125);
  static const Color muted = Color(0xFF718078);

  late final TabController _tabs;

  Map<String, dynamic>? _user;
  bool _loading = true;
  bool _busy = false;
  _ProfileConnectionState _connection =
      _ProfileConnectionState.connect;

  User? get _me => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    unawaited(_load());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.uid)
              .get();

      if (!doc.exists) {
        if (!mounted) return;
        setState(() {
          _loading = false;
        });
        return;
      }

      final Map<String, dynamic> data = <String, dynamic>{
        'uid': widget.uid,
        ...?doc.data(),
      };

      final _ProfileConnectionState state =
          await _getConnectionState();

      if (!mounted) return;
      setState(() {
        _user = data;
        _connection = state;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      _message('Unable to load farmer profile.');
    }
  }

  Future<_ProfileConnectionState> _getConnectionState() async {
    final String? me = _me?.uid;
    if (me == null || me == widget.uid) {
      return _ProfileConnectionState.self;
    }

    final FirebaseFirestore db = FirebaseFirestore.instance;

    final QuerySnapshot<Map<String, dynamic>> a = await db
        .collection('connections')
        .where('user1Uid', isEqualTo: me)
        .where('user2Uid', isEqualTo: widget.uid)
        .limit(1)
        .get();
    if (a.docs.isNotEmpty) {
      return _ProfileConnectionState.connected;
    }

    final QuerySnapshot<Map<String, dynamic>> b = await db
        .collection('connections')
        .where('user1Uid', isEqualTo: widget.uid)
        .where('user2Uid', isEqualTo: me)
        .limit(1)
        .get();
    if (b.docs.isNotEmpty) {
      return _ProfileConnectionState.connected;
    }

    final QuerySnapshot<Map<String, dynamic>> sent = await db
        .collection('connectionRequests')
        .where('fromUid', isEqualTo: me)
        .where('toUid', isEqualTo: widget.uid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (sent.docs.isNotEmpty) {
      return _ProfileConnectionState.sent;
    }

    final QuerySnapshot<Map<String, dynamic>> incoming = await db
        .collection('connectionRequests')
        .where('fromUid', isEqualTo: widget.uid)
        .where('toUid', isEqualTo: me)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (incoming.docs.isNotEmpty) {
      return _ProfileConnectionState.accept;
    }

    return _ProfileConnectionState.connect;
  }

  Future<void> _connect() async {
    final User? me = _me;
    if (me == null || _busy) return;

    setState(() => _busy = true);

    try {
      final _ProfileConnectionState state =
          await _getConnectionState();

      if (state == _ProfileConnectionState.accept) {
        await _accept();
      } else if (state == _ProfileConnectionState.connect) {
        await _sendRequest();
      } else {
        setState(() => _connection = state);
      }
    } catch (e) {
      _message('Unable to update connection: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendRequest() async {
    final User me = _me!;

    final QuerySnapshot<Map<String, dynamic>> existing =
        await FirebaseFirestore.instance
            .collection('connectionRequests')
            .where('fromUid', isEqualTo: me.uid)
            .where('toUid', isEqualTo: widget.uid)
            .where('status', isEqualTo: 'pending')
            .limit(1)
            .get();

    if (existing.docs.isEmpty) {
      await FirebaseFirestore.instance
          .collection('connectionRequests')
          .add(<String, dynamic>{
        'fromUid': me.uid,
        'toUid': widget.uid,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    if (!mounted) return;
    setState(() => _connection = _ProfileConnectionState.sent);
    _message('Connection request sent.');
  }

  Future<void> _accept() async {
    final User me = _me!;

    final QuerySnapshot<Map<String, dynamic>> requests =
        await FirebaseFirestore.instance
            .collection('connectionRequests')
            .where('fromUid', isEqualTo: widget.uid)
            .where('toUid', isEqualTo: me.uid)
            .where('status', isEqualTo: 'pending')
            .limit(1)
            .get();

    if (requests.docs.isEmpty) {
      if (!mounted) return;
      setState(() => _connection = _ProfileConnectionState.connect);
      _message('Request is no longer available.');
      return;
    }

    final String first =
        me.uid.compareTo(widget.uid) < 0 ? me.uid : widget.uid;
    final String second =
        me.uid.compareTo(widget.uid) < 0 ? widget.uid : me.uid;

    final WriteBatch batch = FirebaseFirestore.instance.batch();

    batch.set(
      FirebaseFirestore.instance
          .collection('connections')
          .doc('${first}_$second'),
      <String, dynamic>{
        'user1Uid': first,
        'user2Uid': second,
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

    if (!mounted) return;
    setState(() => _connection = _ProfileConnectionState.connected);
    _message('You are now connected.');
  }

  Future<void> _cancelRequest() async {
    final User? me = _me;
    if (me == null || _busy) return;

    setState(() => _busy = true);

    try {
      final QuerySnapshot<Map<String, dynamic>> requests =
          await FirebaseFirestore.instance
              .collection('connectionRequests')
              .where('fromUid', isEqualTo: me.uid)
              .where('toUid', isEqualTo: widget.uid)
              .where('status', isEqualTo: 'pending')
              .limit(1)
              .get();

      if (requests.docs.isNotEmpty) {
        await requests.docs.first.reference.delete();
      }

      if (!mounted) return;
      setState(() => _connection = _ProfileConnectionState.connect);
      _message('Connection request cancelled.');
    } catch (e) {
      _message('Unable to cancel request.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _decline() async {
    final User? me = _me;
    if (me == null || _busy) return;

    setState(() => _busy = true);

    try {
      final QuerySnapshot<Map<String, dynamic>> requests =
          await FirebaseFirestore.instance
              .collection('connectionRequests')
              .where('fromUid', isEqualTo: widget.uid)
              .where('toUid', isEqualTo: me.uid)
              .where('status', isEqualTo: 'pending')
              .limit(1)
              .get();

      if (requests.docs.isNotEmpty) {
        await requests.docs.first.reference.update(
          <String, dynamic>{
            'status': 'rejected',
            'respondedAt': FieldValue.serverTimestamp(),
          },
        );
      }

      if (!mounted) return;
      setState(() => _connection = _ProfileConnectionState.connect);
      _message('Connection request declined.');
    } catch (_) {
      _message('Unable to decline request.');
    } finally {
      if (mounted) setState(() => _busy = false);
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

  Stream<QuerySnapshot<Map<String, dynamic>>> _postsStream() {
    return FirebaseFirestore.instance
        .collection('communityPosts')
        .where('uid', isEqualTo: widget.uid)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _reelsStream() {
    return FirebaseFirestore.instance
        .collection('farmerVideos')
        .where('authorId', isEqualTo: widget.uid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: background,
        body: Center(
          child: CircularProgressIndicator(
            color: primary,
            strokeWidth: 2.4,
          ),
        ),
      );
    }

    if (_user == null) {
      return Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: background,
          elevation: 0,
          foregroundColor: dark,
        ),
        body: const Center(
          child: Text(
            'Farmer profile not found.',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: dark,
        elevation: 0,
        title: const Text(
          'Farmer Profile',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: RefreshIndicator(
        color: primary,
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: <Widget>[
            SliverToBoxAdapter(child: _header()),
            SliverToBoxAdapter(
              child: TabBar(
                controller: _tabs,
                labelColor: primary,
                unselectedLabelColor: muted,
                indicatorColor: primary,
                indicatorWeight: 3,
                tabs: const <Widget>[
                  Tab(text: 'Posts'),
                  Tab(text: 'Reels'),
                ],
              ),
            ),
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabs,
                children: <Widget>[
                  _PostTab(stream: _postsStream()),
                  _ReelTab(stream: _reelsStream()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    final Map<String, dynamic> data = _user!;
    final String name =
        '${data['displayName'] ?? 'AgriAI Farmer'}'.trim();
    final String userId = '${data['userId'] ?? ''}'.trim();
    final String photo = '${data['photoUrl'] ?? ''}'.trim();
    final String bio = '${data['bio'] ?? ''}'.trim();
    final String location = '${data['location'] ?? ''}'.trim();
    final String crops = '${data['crops'] ?? ''}'.trim();
    final String farmSize = '${data['farmSize'] ?? ''}'.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xFFE0EAE3)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _Avatar(url: photo, name: name, radius: 39),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        name.isEmpty ? 'AgriAI Farmer' : name,
                        style: const TextStyle(
                          color: dark,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (userId.isNotEmpty)
                        Text(
                          '@$userId',
                          style: const TextStyle(
                            color: primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      if (location.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 5),
                        Row(
                          children: <Widget>[
                            const Icon(
                              Icons.location_on_outlined,
                              color: muted,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                location,
                                style: const TextStyle(
                                  color: muted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (bio.isNotEmpty) ...<Widget>[
              const SizedBox(height: 15),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  bio,
                  style: const TextStyle(
                    color: Color(0xFF405148),
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
              ),
            ],
            if (crops.isNotEmpty || farmSize.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: <Widget>[
                  if (crops.isNotEmpty)
                    _InfoChip(
                      icon: Icons.eco_rounded,
                      text: crops,
                    ),
                  if (farmSize.isNotEmpty)
                    _InfoChip(
                      icon: Icons.square_foot_rounded,
                      text: farmSize,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            _actionRow(),
          ],
        ),
      ),
    );
  }

  Widget _actionRow() {
    if (_busy) {
      return const SizedBox(
        height: 42,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: primary,
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    switch (_connection) {
      case _ProfileConnectionState.self:
        return const SizedBox.shrink();

      case _ProfileConnectionState.connect:
        return SizedBox(
          width: double.infinity,
          height: 42,
          child: FilledButton.icon(
            onPressed: _connect,
            style: FilledButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 17),
            label: const Text(
              'Connect',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        );

      case _ProfileConnectionState.sent:
        return Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _cancelRequest,
                icon: const Icon(Icons.schedule_rounded, size: 17),
                label: const Text(
                  'Request Sent',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primary,
                  side: const BorderSide(color: Color(0xFFB9D4BE)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ),
          ],
        );

      case _ProfileConnectionState.accept:
        return Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton(
                onPressed: _decline,
                style: OutlinedButton.styleFrom(
                  foregroundColor: muted,
                  side: const BorderSide(color: Color(0xFFD8E4DB)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                child: const Text(
                  'Decline',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: _accept,
                style: FilledButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                icon: const Icon(Icons.check_rounded, size: 17),
                label: const Text(
                  'Accept',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        );

      case _ProfileConnectionState.connected:
        return SizedBox(
          width: double.infinity,
          height: 42,
          child: FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const DirectMessagesScreen(),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            icon: const Icon(Icons.chat_rounded, size: 17),
            label: const Text(
              'Message',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        );
    }
  }
}

enum _ProfileConnectionState {
  self,
  connect,
  sent,
  accept,
  connected,
}

class _PostTab extends StatelessWidget {
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;

  const _PostTab({required this.stream});

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
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF2E7D32),
              strokeWidth: 2,
            ),
          );
        }

        if (snapshot.hasError) {
          return const _TabEmpty(
            icon: Icons.cloud_off_rounded,
            title: 'Unable to load posts',
          );
        }

        final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs =
            snapshot.data?.docs ??
                <QueryDocumentSnapshot<Map<String, dynamic>>>[];

        if (docs.isEmpty) {
          return const _TabEmpty(
            icon: Icons.article_outlined,
            title: 'No posts yet',
          );
        }

        docs.sort((a, b) {
          final dynamic av = a.data()['createdAt'];
          final dynamic bv = b.data()['createdAt'];
          final int am =
              av is Timestamp ? av.millisecondsSinceEpoch : 0;
          final int bm =
              bv is Timestamp ? bv.millisecondsSinceEpoch : 0;
          return bm.compareTo(am);
        });

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
          itemCount: docs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (BuildContext context, int index) {
            return _PublicPostCard(
              postId: docs[index].id,
              data: docs[index].data(),
            );
          },
        );
      },
    );
  }
}

class _PublicPostCard extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> data;

  const _PublicPostCard({
    required this.postId,
    required this.data,
  });

  @override
  State<_PublicPostCard> createState() => _PublicPostCardState();
}

class _PublicPostCardState extends State<_PublicPostCard> {
  static const Color primary = Color(0xFF2E7D32);

  bool _liked = false;
  bool _saved = false;
  bool _busyLike = false;
  bool _busySave = false;
  int _likes = 0;
  int _comments = 0;

  User? get _me => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _likes = _number(widget.data['likesCount']);
    _comments = _number(widget.data['commentsCount']);
    unawaited(_loadInteractionState());
  }

  int _number(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  Future<void> _loadInteractionState() async {
    final String? uid = _me?.uid;
    if (uid == null) return;

    final FirebaseFirestore db = FirebaseFirestore.instance;

    try {
      final List<DocumentSnapshot<Map<String, dynamic>>> results =
          await Future.wait(
        <Future<DocumentSnapshot<Map<String, dynamic>>>>[
          db
              .collection('communityPosts')
              .doc(widget.postId)
              .collection('likes')
              .doc(uid)
              .get(),
          db
              .collection('users')
              .doc(uid)
              .collection('savedPosts')
              .doc(widget.postId)
              .get(),
        ],
      );

      if (!mounted) return;
      setState(() {
        _liked = results[0].exists;
        _saved = results[1].exists;
      });
    } catch (_) {
      // The post remains usable even if interaction-state reads fail.
    }
  }

  Future<void> _toggleLike() async {
    final String? uid = _me?.uid;
    if (uid == null || _busyLike) return;

    final FirebaseFirestore db = FirebaseFirestore.instance;
    final DocumentReference<Map<String, dynamic>> postRef =
        db.collection('communityPosts').doc(widget.postId);
    final DocumentReference<Map<String, dynamic>> likeRef =
        postRef.collection('likes').doc(uid);

    final bool next = !_liked;
    final int nextCount =
        (_likes + (next ? 1 : -1)).clamp(0, 1000000000);

    setState(() {
      _busyLike = true;
      _liked = next;
      _likes = nextCount;
    });

    try {
      if (next) {
        await likeRef.set(<String, dynamic>{
          'uid': uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await postRef.set(
          <String, dynamic>{
            'likesCount': FieldValue.increment(1),
          },
          SetOptions(merge: true),
        );
      } else {
        await likeRef.delete();
        await postRef.set(
          <String, dynamic>{
            'likesCount': FieldValue.increment(-1),
          },
          SetOptions(merge: true),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _liked = !next;
        _likes = _number(widget.data['likesCount']);
      });
      _message('Unable to update like.');
    } finally {
      if (mounted) setState(() => _busyLike = false);
    }
  }

  Future<void> _toggleSave() async {
    final String? uid = _me?.uid;
    if (uid == null || _busySave) return;

    final DocumentReference<Map<String, dynamic>> saveRef =
        FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('savedPosts')
            .doc(widget.postId);

    final bool next = !_saved;

    setState(() {
      _busySave = true;
      _saved = next;
    });

    try {
      if (next) {
        await saveRef.set(<String, dynamic>{
          'postId': widget.postId,
          'postOwnerUid':
              '${widget.data['uid'] ?? widget.data['authorUid'] ?? ''}',
          'userId': '${widget.data['userId'] ?? ''}',
          'displayName':
              '${widget.data['displayName'] ?? 'AgriAI Farmer'}',
          'text':
              '${widget.data['text'] ?? widget.data['content'] ?? ''}',
          'postType': '${widget.data['postType'] ?? 'text'}',
          'mediaUrl':
              '${widget.data['mediaUrl'] ?? widget.data['imageUrl'] ?? ''}',
          'savedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await saveRef.delete();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saved = !next);
      _message('Unable to update saved post.');
    } finally {
      if (mounted) setState(() => _busySave = false);
    }
  }

  Future<void> _openComments() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PostCommentsSheet(
        postId: widget.postId,
        onCountChanged: (int count) {
          if (mounted) setState(() => _comments = count);
        },
      ),
    );
  }

  void _share() {
    final String text =
        '${widget.data['text'] ?? widget.data['content'] ?? ''}'.trim();

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  'Share Post',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE7F3E9),
                    child: Icon(
                      Icons.forum_rounded,
                      color: primary,
                    ),
                  ),
                  title: const Text(
                    'Share with a farmer',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: const Text('Send it through AgriAI Messages'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(this.context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const DirectMessagesScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE7F3E9),
                    child: Icon(
                      Icons.copy_rounded,
                      color: primary,
                    ),
                  ),
                  title: const Text(
                    'Copy post text',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    if (text.isEmpty) {
                      _message('This post has no text to copy.');
                    } else {
                      _message('Post text is ready to share.');
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
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
    final String text =
        '${widget.data['text'] ?? widget.data['content'] ?? ''}'.trim();
    final String image =
        '${widget.data['mediaUrl'] ?? widget.data['imageUrl'] ?? ''}'.trim();
    final String author =
        '${widget.data['displayName'] ?? 'AgriAI Farmer'}'.trim();
    final String userId = '${widget.data['userId'] ?? ''}'.trim();
    final String photo = '${widget.data['photoUrl'] ?? ''}'.trim();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFE0EAE3)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 12, 13, 8),
            child: Row(
              children: <Widget>[
                _Avatar(url: photo, name: author, radius: 20),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        author.isEmpty ? 'AgriAI Farmer' : author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF183125),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (userId.isNotEmpty)
                        Text(
                          '@$userId',
                          style: const TextStyle(
                            color: primary,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 2, 13, 11),
              child: Text(
                text,
                style: const TextStyle(
                  color: Color(0xFF405148),
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ),
          if (image.isNotEmpty)
            AspectRatio(
              aspectRatio: 1.55,
              child: Image.network(
                image,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(7, 5, 7, 7),
            child: Row(
              children: <Widget>[
                _PostAction(
                  icon: _liked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  label: '$_likes',
                  active: _liked,
                  onTap: _toggleLike,
                ),
                _PostAction(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: '$_comments',
                  onTap: _openComments,
                ),
                _PostAction(
                  icon: Icons.send_rounded,
                  label: 'Share',
                  onTap: _share,
                ),
                const Spacer(),
                IconButton(
                  tooltip: _saved ? 'Unsave' : 'Save',
                  onPressed: _busySave ? null : _toggleSave,
                  icon: Icon(
                    _saved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: _saved ? primary : const Color(0xFF718078),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PostAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _PostAction({
    required this.icon,
    required this.label,
    this.active = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 7,
          vertical: 7,
        ),
        child: Row(
          children: <Widget>[
            Icon(
              icon,
              size: 18,
              color: active
                  ? const Color(0xFFE53935)
                  : const Color(0xFF718078),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF718078),
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostCommentsSheet extends StatefulWidget {
  final String postId;
  final ValueChanged<int> onCountChanged;

  const _PostCommentsSheet({
    required this.postId,
    required this.onCountChanged,
  });

  @override
  State<_PostCommentsSheet> createState() => _PostCommentsSheetState();
}

class _PostCommentsSheetState extends State<_PostCommentsSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _sending = false;

  Stream<QuerySnapshot<Map<String, dynamic>>> get _commentsStream {
    return FirebaseFirestore.instance
        .collection('communityPosts')
        .doc(widget.postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final User? user = FirebaseAuth.instance.currentUser;
    final String text = _controller.text.trim();

    if (user == null || text.isEmpty || _sending) return;

    setState(() => _sending = true);

    try {
      final DocumentSnapshot<Map<String, dynamic>> profile =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      final Map<String, dynamic> profileData =
          profile.data() ?? <String, dynamic>{};

      await FirebaseFirestore.instance
          .collection('communityPosts')
          .doc(widget.postId)
          .collection('comments')
          .add(<String, dynamic>{
        'uid': user.uid,
        'userId': '${profileData['userId'] ?? ''}',
        'displayName':
            '${profileData['displayName'] ?? user.displayName ?? 'Farmer'}',
        'photoUrl': '${profileData['photoUrl'] ?? ''}',
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('communityPosts')
          .doc(widget.postId)
          .set(
        <String, dynamic>{
          'commentsCount': FieldValue.increment(1),
        },
        SetOptions(merge: true),
      );

      _controller.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to add comment.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double bottom =
        MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.72,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      child: Column(
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 15, 18, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Comments',
                style: TextStyle(
                  color: Color(0xFF183125),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _commentsStream,
              builder: (
                BuildContext context,
                AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
              ) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Unable to load comments.'),
                  );
                }

                final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs =
                    snapshot.data?.docs ??
                        <QueryDocumentSnapshot<Map<String, dynamic>>>[];

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  widget.onCountChanged(docs.length);
                });

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No comments yet. Start the conversation.',
                      style: TextStyle(
                        color: Color(0xFF718078),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  itemCount: docs.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: 10),
                  itemBuilder: (BuildContext context, int index) {
                    final Map<String, dynamic> data = docs[index].data();
                    final String name =
                        '${data['displayName'] ?? 'Farmer'}';
                    final String id = '${data['userId'] ?? ''}';
                    final String photo =
                        '${data['photoUrl'] ?? ''}';
                    final String comment =
                        '${data['text'] ?? ''}';

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _Avatar(
                          url: photo,
                          name: name,
                          radius: 18,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(
                              11,
                              8,
                              11,
                              9,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F8F6),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  name,
                                  style: const TextStyle(
                                    color: Color(0xFF183125),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                if (id.isNotEmpty)
                                  Text(
                                    '@$id',
                                    style: const TextStyle(
                                      color: Color(0xFF2E7D32),
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  comment,
                                  style: const TextStyle(
                                    color: Color(0xFF405148),
                                    fontSize: 11,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              12,
              7,
              12,
              10 + bottom,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: 'Write a comment...',
                      filled: true,
                      fillColor: const Color(0xFFF3F7F4),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                IconButton.filled(
                  onPressed: _sending ? null : _send,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                  ),
                  icon: _sending
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReelTab extends StatelessWidget {
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;

  const _ReelTab({required this.stream});

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
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF2E7D32),
              strokeWidth: 2,
            ),
          );
        }

        if (snapshot.hasError) {
          return const _TabEmpty(
            icon: Icons.cloud_off_rounded,
            title: 'Unable to load Reels',
          );
        }

        final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs =
            snapshot.data?.docs ??
                <QueryDocumentSnapshot<Map<String, dynamic>>>[];

        if (docs.isEmpty) {
          return const _TabEmpty(
            icon: Icons.play_circle_outline_rounded,
            title: 'No Reels yet',
          );
        }

        final List<QueryDocumentSnapshot<Map<String, dynamic>>> sorted =
            List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(docs)
              ..sort((a, b) {
                final dynamic aTime = a.data()['createdAt'];
                final dynamic bTime = b.data()['createdAt'];
                final DateTime aDate = aTime is Timestamp
                    ? aTime.toDate()
                    : DateTime.fromMillisecondsSinceEpoch(0);
                final DateTime bDate = bTime is Timestamp
                    ? bTime.toDate()
                    : DateTime.fromMillisecondsSinceEpoch(0);
                return bDate.compareTo(aDate);
              });

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.72,
          ),
          itemCount: sorted.length,
          itemBuilder: (BuildContext context, int index) {
            final QueryDocumentSnapshot<Map<String, dynamic>> doc =
                sorted[index];
            final Map<String, dynamic> data = doc.data();
            final String title =
                '${data['title'] ?? data['caption'] ?? 'Farming Reel'}'.trim();
            final String thumbnail =
                '${data['thumbnailUrl'] ?? data['thumbnail'] ?? ''}'.trim();
            final int likes = _intValue(data['likesCount']);
            final int views = _intValue(data['viewsCount']);

            return InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => _PublicReelsViewerScreen(
                      initialIndex: index,
                      docs: sorted,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(18),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF183125),
                  borderRadius: BorderRadius.circular(18),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    if (thumbnail.isNotEmpty)
                      Image.network(
                        thumbnail,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            Colors.transparent,
                            Color(0xE6000000),
                          ],
                        ),
                      ),
                    ),
                    const Center(
                      child: CircleAvatar(
                        radius: 23,
                        backgroundColor: Color(0xCCFFFFFF),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: Color(0xFF2E7D32),
                          size: 30,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      right: 10,
                      bottom: 10,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            title.isEmpty ? 'Farming Reel' : title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${_compactNumber(likes)} likes  •  ${_compactNumber(views)} views',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PublicReelsViewerScreen extends StatefulWidget {
  final int initialIndex;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

  const _PublicReelsViewerScreen({
    required this.initialIndex,
    required this.docs,
  });

  @override
  State<_PublicReelsViewerScreen> createState() =>
      _PublicReelsViewerScreenState();
}

class _PublicReelsViewerScreenState extends State<_PublicReelsViewerScreen> {
  static const Color primary = Color(0xFF2E7D32);
  static const Color dark = Color(0xFF07130D);

  late final PageController _pageController;
  int _activeIndex = 0;
  bool _muted = true;
  bool _showHeart = false;
  final Map<String, VideoPlayerController> _controllers =
      <String, VideoPlayerController>{};
  final Set<String> _initialised = <String>{};

  User? get _me => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _activeIndex = widget.initialIndex.clamp(0, widget.docs.length - 1);
    _pageController = PageController(initialPage: _activeIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_activate(_activeIndex));
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final VideoPlayerController controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _activate(int index) async {
    if (index < 0 || index >= widget.docs.length) return;

    for (final MapEntry<String, VideoPlayerController> entry
        in _controllers.entries) {
      if (entry.key != widget.docs[index].id && entry.value.value.isPlaying) {
        await entry.value.pause();
      }
    }

    final QueryDocumentSnapshot<Map<String, dynamic>> doc = widget.docs[index];
    final String id = doc.id;
    final String url = _reelUrl(doc.data());
    if (url.isEmpty) return;

    VideoPlayerController? controller = _controllers[id];
    if (controller == null) {
      controller = VideoPlayerController.networkUrl(Uri.parse(url));
      _controllers[id] = controller;
      try {
        await controller.initialize();
        controller.setLooping(true);
        controller.setVolume(_muted ? 0 : 1);
      } catch (_) {
        if (mounted) setState(() {});
        return;
      }
    }

    if (!mounted) return;
    setState(() {});
    if (controller.value.isInitialized) {
      await controller.play();
    }

    if (!_initialised.contains(id)) {
      _initialised.add(id);
      await FirebaseFirestore.instance
          .collection('farmerVideos')
          .doc(id)
          .set(<String, dynamic>{
        'viewsCount': FieldValue.increment(1),
      }, SetOptions(merge: true));
    }
  }

  Future<void> _toggleMute() async {
    setState(() => _muted = !_muted);
    for (final VideoPlayerController controller in _controllers.values) {
      controller.setVolume(_muted ? 0 : 1);
    }
  }

  void _togglePlay(VideoPlayerController controller) {
    if (!controller.value.isInitialized) return;
    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
      } else {
        controller.play();
      }
    });
  }

  Future<void> _like(QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    final User? user = _me;
    if (user == null) return;

    final DocumentReference<Map<String, dynamic>> reelRef =
        FirebaseFirestore.instance.collection('farmerVideos').doc(doc.id);
    final DocumentReference<Map<String, dynamic>> likeRef =
        reelRef.collection('likes').doc(user.uid);

    try {
      final DocumentSnapshot<Map<String, dynamic>> existing =
          await likeRef.get();
      if (existing.exists) {
        await likeRef.delete();
        await reelRef.set(<String, dynamic>{
          'likesCount': FieldValue.increment(-1),
        }, SetOptions(merge: true));
      } else {
        await likeRef.set(<String, dynamic>{
          'uid': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await reelRef.set(<String, dynamic>{
          'likesCount': FieldValue.increment(1),
        }, SetOptions(merge: true));
      }
    } catch (_) {
      _snack('Unable to update like.');
    }
  }

  Future<void> _doubleTapLike(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    setState(() => _showHeart = true);
    Future<void>.delayed(const Duration(milliseconds: 650), () {
      if (mounted) setState(() => _showHeart = false);
    });
    await _like(doc);
  }

  Future<bool> _isLiked(String reelId) async {
    final User? user = _me;
    if (user == null) return false;
    final DocumentSnapshot<Map<String, dynamic>> doc =
        await FirebaseFirestore.instance
            .collection('farmerVideos')
            .doc(reelId)
            .collection('likes')
            .doc(user.uid)
            .get();
    return doc.exists;
  }

  Future<bool> _isSaved(String reelId) async {
    final User? user = _me;
    if (user == null) return false;
    final DocumentSnapshot<Map<String, dynamic>> doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('savedReels')
            .doc(reelId)
            .get();
    return doc.exists;
  }

  Future<void> _toggleSave(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final User? user = _me;
    if (user == null) return;

    final DocumentReference<Map<String, dynamic>> ref =
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('savedReels')
            .doc(doc.id);

    try {
      final DocumentSnapshot<Map<String, dynamic>> existing = await ref.get();
      if (existing.exists) {
        await ref.delete();
        _snack('Removed from Saved Reels.');
      } else {
        final Map<String, dynamic> data = doc.data();
        await ref.set(<String, dynamic>{
          'reelId': doc.id,
          'reelOwnerUid': '${data['authorId'] ?? ''}',
          'authorId': '${data['authorId'] ?? ''}',
          'title': '${data['title'] ?? data['caption'] ?? 'Farming Reel'}',
          'caption': '${data['caption'] ?? data['title'] ?? ''}',
          'mediaUrl': _reelUrl(data),
          'thumbnailUrl': '${data['thumbnailUrl'] ?? ''}',
          'savedAt': FieldValue.serverTimestamp(),
        });
        _snack('Saved to your Reels.');
      }
      if (mounted) setState(() {});
    } catch (_) {
      _snack('Unable to update saved Reel.');
    }
  }

  Future<void> _showComments(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext sheetContext) => _ReelCommentsSheet(
        reelId: doc.id,
        reelOwnerUid: '${doc.data()['authorId'] ?? ''}',
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _share(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final Map<String, dynamic> data = doc.data();
    final String ownerUid = '${data['authorId'] ?? ''}'.trim();
    final String reelId = doc.id;
    final String caption =
        '${data['caption'] ?? data['title'] ?? 'Farming Reel'}'.trim();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 18),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Share Reel',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8F5E9),
                    child: Icon(Icons.forum_rounded, color: primary),
                  ),
                  title: const Text(
                    'Share with a farmer',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: const Text('Send it through AgriAI Messages'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const DirectMessagesScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8F5E9),
                    child: Icon(Icons.link_rounded, color: primary),
                  ),
                  title: const Text(
                    'Copy Reel link',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  onTap: () async {
                    await Clipboard.setData(
                      ClipboardData(text: 'agriAI://reel/$reelId'),
                    );
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                    _snack('Reel link copied.');
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFF3E0),
                    child: Icon(Icons.text_snippet_rounded, color: Colors.orange),
                  ),
                  title: const Text(
                    'Copy caption',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: caption));
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                    _snack('Caption copied.');
                  },
                ),
                if (ownerUid.isNotEmpty && ownerUid == _me?.uid)
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFE8F5E9),
                      child: Icon(Icons.edit_rounded, color: primary),
                    ),
                    title: const Text(
                      'Edit caption',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _editCaption(doc);
                    },
                  ),
                if (ownerUid.isNotEmpty && ownerUid == _me?.uid)
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFFFEBEE),
                      child: Icon(Icons.delete_outline_rounded, color: Colors.red),
                    ),
                    title: const Text(
                      'Delete Reel',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _deleteReel(doc);
                    },
                  ),
                if (ownerUid.isEmpty || ownerUid != _me?.uid)
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFFFEBEE),
                      child: Icon(Icons.flag_outlined, color: Colors.red),
                    ),
                    title: const Text(
                      'Report Reel',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _reportReel(doc);
                    },
                  ),
                if (ownerUid.isEmpty || ownerUid != _me?.uid)
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFF2F4F3),
                      child: Icon(Icons.visibility_off_rounded),
                    ),
                    title: const Text(
                      'Not interested',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _snack('We will show fewer Reels like this.');
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _editCaption(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final Map<String, dynamic> data = doc.data();
    final TextEditingController controller = TextEditingController(
      text: '${data['caption'] ?? data['title'] ?? ''}',
    );

    final String? value = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Edit Reel caption'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 5,
            maxLength: 500,
            decoration: const InputDecoration(
              hintText: 'Write a caption for your Reel',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (value == null) return;
    final String caption = value.trim();
    try {
      await FirebaseFirestore.instance
          .collection('farmerVideos')
          .doc(doc.id)
          .update(<String, dynamic>{
        'caption': caption,
        'title': caption,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _snack('Reel caption updated.');
    } catch (_) {
      _snack('Unable to update caption.');
    }
  }

  Future<void> _deleteReel(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Reel?'),
          content: const Text(
            'This Reel will be removed from AgriAI. This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    try {
      await FirebaseFirestore.instance
          .collection('farmerVideos')
          .doc(doc.id)
          .delete();
      _controllers.remove(doc.id)?.dispose();
      if (!mounted) return;
      if (widget.docs.length <= 1) {
        Navigator.pop(context);
      } else {
        setState(() {});
      }
      _snack('Reel deleted.');
    } catch (_) {
      _snack('Unable to delete Reel.');
    }
  }

  Future<void> _reportReel(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final User? user = _me;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('reelReports').add(<String, dynamic>{
        'reelId': doc.id,
        'reportedByUid': user.uid,
        'reelOwnerUid': '${doc.data()['authorId'] ?? ''}',
        'reason': 'Reported from public farmer profile',
        'createdAt': FieldValue.serverTimestamp(),
      });
      _snack('Reel reported. Thank you.');
    } catch (_) {
      _snack('Unable to report Reel right now.');
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: dark,
      body: Stack(
        children: <Widget>[
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: widget.docs.length,
            onPageChanged: (int index) {
              setState(() => _activeIndex = index);
              unawaited(_activate(index));
            },
            itemBuilder: (BuildContext context, int index) {
              return _PublicReelPage(
                doc: widget.docs[index],
                controller: _controllers[widget.docs[index].id],
                muted: _muted,
                showHeart: _showHeart && _activeIndex == index,
                onTap: () {
                  final VideoPlayerController? controller =
                      _controllers[widget.docs[index].id];
                  if (controller != null) _togglePlay(controller);
                },
                onDoubleTap: () => _doubleTapLike(widget.docs[index]),
                onLike: () => _like(widget.docs[index]),
                isLiked: () => _isLiked(widget.docs[index].id),
                onComment: () => _showComments(widget.docs[index]),
                onSave: () => _toggleSave(widget.docs[index]),
                isSaved: () => _isSaved(widget.docs[index].id),
                onShare: () => _share(widget.docs[index]),
                onMute: _toggleMute,
              );
            },
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Material(
                  color: Colors.black38,
                  shape: const CircleBorder(),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    tooltip: 'Back',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PublicReelPage extends StatelessWidget {
  static const Color primary = Color(0xFF2E7D32);

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final VideoPlayerController? controller;
  final bool muted;
  final bool showHeart;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final VoidCallback onLike;
  final Future<bool> Function() isLiked;
  final VoidCallback onComment;
  final VoidCallback onSave;
  final Future<bool> Function() isSaved;
  final VoidCallback onShare;
  final VoidCallback onMute;

  const _PublicReelPage({
    required this.doc,
    required this.controller,
    required this.muted,
    required this.showHeart,
    required this.onTap,
    required this.onDoubleTap,
    required this.onLike,
    required this.isLiked,
    required this.onComment,
    required this.onSave,
    required this.isSaved,
    required this.onShare,
    required this.onMute,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> data = doc.data();
    final String caption =
        '${data['caption'] ?? data['title'] ?? 'Farming Reel'}'.trim();
    final String author =
        '${data['authorName'] ?? data['displayName'] ?? 'AgriAI Farmer'}'.trim();
    final String userId = '${data['authorUserId'] ?? data['userId'] ?? ''}'.trim();
    final String avatar = '${data['authorPhotoUrl'] ?? data['photoUrl'] ?? ''}'.trim();
    final int likes = _intValue(data['likesCount']);
    final int comments = _intValue(data['commentsCount']);
    final int shares = _intValue(data['sharesCount']);
    final int views = _intValue(data['viewsCount']);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const ColoredBox(color: Colors.black),
          if (controller != null && controller!.value.isInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: controller!.value.aspectRatio == 0
                    ? 9 / 16
                    : controller!.value.aspectRatio,
                child: VideoPlayer(controller!),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: <double>[0, .38, 1],
                colors: <Color>[
                  Color(0x66000000),
                  Colors.transparent,
                  Color(0xE6000000),
                ],
              ),
            ),
          ),
          if (showHeart)
            const Center(
              child: Icon(
                Icons.favorite_rounded,
                color: Colors.white,
                size: 110,
              ),
            ),
          Positioned(
            right: 12,
            bottom: 100,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _AsyncReelAction(
                    icon: Icons.favorite_rounded,
                    activeIcon: Icons.favorite_rounded,
                    color: Colors.redAccent,
                    label: _compactNumber(likes),
                    isActive: isLiked,
                    onTap: onLike,
                  ),
                  const SizedBox(height: 17),
                  _ReelAction(
                    icon: Icons.comment_rounded,
                    label: _compactNumber(comments),
                    onTap: onComment,
                  ),
                  const SizedBox(height: 17),
                  _ReelAction(
                    icon: Icons.send_rounded,
                    label: _compactNumber(shares),
                    onTap: onShare,
                  ),
                  const SizedBox(height: 17),
                  _AsyncReelAction(
                    icon: Icons.bookmark_border_rounded,
                    activeIcon: Icons.bookmark_rounded,
                    label: 'Save',
                    isActive: isSaved,
                    onTap: onSave,
                  ),
                  const SizedBox(height: 17),
                  _ReelAction(
                    icon: muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                    label: muted ? 'Muted' : 'Sound',
                    onTap: onMute,
                  ),
                  const SizedBox(height: 17),
                  _ReelAction(
                    icon: Icons.more_horiz_rounded,
                    label: 'More',
                    onTap: onShare,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 78,
            bottom: 30,
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white24,
                        backgroundImage:
                            avatar.isNotEmpty ? NetworkImage(avatar) : null,
                        child: avatar.isEmpty
                            ? const Icon(Icons.person_rounded, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          userId.isEmpty ? author : '$author  @$userId',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    caption.isEmpty ? 'Farming Reel' : caption,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      height: 1.35,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      const Icon(Icons.music_note_rounded, color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      const Expanded(
                        child: Text(
                          'Original farming audio',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_compactNumber(views)} views',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 10,
            child: controller != null && controller!.value.isInitialized
                ? SafeArea(
                    top: false,
                    child: VideoProgressIndicator(
                      controller!,
                      allowScrubbing: true,
                      padding: EdgeInsets.zero,
                      colors: const VideoProgressColors(
                        playedColor: primary,
                        bufferedColor: Colors.white54,
                        backgroundColor: Colors.white24,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _ReelAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ReelAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: 54,
        child: Column(
          children: <Widget>[
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AsyncReelAction extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final Color? color;
  final String label;
  final Future<bool> Function() isActive;
  final VoidCallback onTap;

  const _AsyncReelAction({
    required this.icon,
    required this.activeIcon,
    this.color,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_AsyncReelAction> createState() => _AsyncReelActionState();
}

class _AsyncReelActionState extends State<_AsyncReelAction> {
  bool _active = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final bool value = await widget.isActive();
      if (mounted) setState(() => _active = value);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        setState(() => _active = !_active);
        widget.onTap();
      },
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: 54,
        child: Column(
          children: <Widget>[
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24),
              ),
              child: Icon(
                _active ? widget.activeIcon : widget.icon,
                color: _active ? (widget.color ?? Colors.white) : Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReelCommentsSheet extends StatefulWidget {
  final String reelId;
  final String reelOwnerUid;

  const _ReelCommentsSheet({
    required this.reelId,
    required this.reelOwnerUid,
  });

  @override
  State<_ReelCommentsSheet> createState() => _ReelCommentsSheetState();
}

class _ReelCommentsSheetState extends State<_ReelCommentsSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _sending = false;

  User? get _me => FirebaseAuth.instance.currentUser;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final User? user = _me;
    final String text = _controller.text.trim();
    if (user == null || text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      final DocumentReference<Map<String, dynamic>> reelRef =
          FirebaseFirestore.instance.collection('farmerVideos').doc(widget.reelId);
      await reelRef.collection('comments').add(<String, dynamic>{
        'uid': user.uid,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await reelRef.set(<String, dynamic>{
        'commentsCount': FieldValue.increment(1),
      }, SetOptions(merge: true));
      _controller.clear();
    } catch (_) {
      _snack('Unable to add comment.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _snack(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Stream<QuerySnapshot<Map<String, dynamic>>> stream =
        FirebaseFirestore.instance
            .collection('farmerVideos')
            .doc(widget.reelId)
            .collection('comments')
            .orderBy('createdAt', descending: false)
            .limit(100)
            .snapshots();

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .72,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Row(
                children: <Widget>[
                  const Expanded(
                    child: Text(
                      'Reel Comments',
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: stream,
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }
                  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs =
                      snapshot.data?.docs ??
                          <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No comments yet. Be the first to comment.',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                    itemCount: docs.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Map<String, dynamic> data = docs[index].data();
                      final String uid = '${data['uid'] ?? ''}';
                      return FutureBuilder<
                          DocumentSnapshot<Map<String, dynamic>>>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .get(),
                        builder: (BuildContext context,
                            AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> userSnap) {
                          final Map<String, dynamic>? userData = userSnap.data?.data();
                          final String name =
                              '${userData?['displayName'] ?? 'Farmer'}';
                          final String photo = '${userData?['photoUrl'] ?? ''}';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                CircleAvatar(
                                  radius: 19,
                                  backgroundImage:
                                      photo.isNotEmpty ? NetworkImage(photo) : null,
                                  child: photo.isEmpty
                                      ? const Icon(Icons.person_rounded)
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        name,
                                        style: const TextStyle(fontWeight: FontWeight.w900),
                                      ),
                                      const SizedBox(height: 3),
                                      Text('${data['text'] ?? ''}'),
                                    ],
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
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                14,
                10,
                14,
                10 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 12,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        filled: true,
                        fillColor: const Color(0xFFF3F6F4),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

int _intValue(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}

String _compactNumber(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(value % 1000000 == 0 ? 0 : 1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}K';
  }
  return '$value';
}

String _reelUrl(Map<String, dynamic> data) {
  final String value =
      '${data['cloudinaryUrl'] ?? data['mediaUrl'] ?? data['videoUrl'] ?? ''}'.trim();
  return value;
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3ED),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.eco_rounded,
            size: 13,
            color: Color(0xFF2E7D32),
          ),
          const SizedBox(width: 5),
          Icon(icon, size: 13, color: const Color(0xFF2E7D32)),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF2E7D32),
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String url;
  final String name;
  final double radius;

  const _Avatar({
    required this.url,
    required this.name,
    this.radius = 25,
  });

  @override
  Widget build(BuildContext context) {
    final String initial = name.trim().isEmpty
        ? 'A'
        : name.trim().substring(0, 1).toUpperCase();

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFE7F3E9),
      backgroundImage: url.isEmpty ? null : NetworkImage(url),
      child: url.isEmpty
          ? Text(
              initial,
              style: TextStyle(
                color: const Color(0xFF2E7D32),
                fontWeight: FontWeight.w900,
                fontSize: radius * 0.62,
              ),
            )
          : null,
    );
  }
}

class _TabEmpty extends StatelessWidget {
  final IconData icon;
  final String title;

  const _TabEmpty({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            icon,
            size: 48,
            color: const Color(0xFF9BB0A1),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF718078),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
