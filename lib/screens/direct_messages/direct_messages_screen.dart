import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/direct_messages_service.dart';

class DirectMessagesScreen extends StatefulWidget {
  const DirectMessagesScreen({super.key});

  @override
  State<DirectMessagesScreen> createState() => _DirectMessagesScreenState();
}

class _DirectMessagesScreenState extends State<DirectMessagesScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final String value = _searchController.text.trim().toLowerCase();

    if (value == _searchQuery) {
      return;
    }

    setState(() {
      _searchQuery = value;
    });
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please sign in to view messages.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF7FAF8),
        foregroundColor: const Color(0xFF17351F),
        title: const Text(
          'Messages',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 23,
          ),
        ),
      ),
      body: Column(
        children: <Widget>[
          _buildSearchBar(),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<List<DirectConversation>>(
              stream: DirectMessagesService.watchConversations(),
              builder: (
                BuildContext context,
                AsyncSnapshot<List<DirectConversation>> snapshot,
              ) {
                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final List<DirectConversation> conversations =
                    snapshot.data ?? <DirectConversation>[];

                final List<DirectConversation> filtered =
                    conversations.where((DirectConversation conversation) {
                  if (_searchQuery.isEmpty) {
                    return true;
                  }

                  final String otherUid = conversation.participantUids
                      .firstWhere(
                    (String uid) => uid != currentUser.uid,
                    orElse: () => '',
                  );

                  return otherUid.toLowerCase().contains(_searchQuery) ||
                      conversation.lastMessage
                          .toLowerCase()
                          .contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, int index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (
                    BuildContext context,
                    int index,
                  ) {
                    return _ConversationTile(
                      conversation: filtered[index],
                      currentUid: currentUser.uid,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => DirectChatScreen(
                              conversation: filtered[index],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search messages',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  tooltip: 'Clear search',
                  onPressed: _searchController.clear,
                  icon: const Icon(Icons.close_rounded),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 15,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.forum_rounded,
                size: 42,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No conversations yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF17351F),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Connect with farmers and start a conversation.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF6B776F),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.cloud_off_rounded,
              size: 52,
              color: Color(0xFF78909C),
            ),
            const SizedBox(height: 14),
            const Text(
              'Unable to load messages',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF6B776F),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final DirectConversation conversation;
  final String currentUid;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.currentUid,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String otherUid = conversation.participantUids.firstWhere(
      (String uid) => uid != currentUid,
      orElse: () => '',
    );

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: otherUid.isEmpty
          ? null
          : FirebaseFirestore.instance
              .collection('users')
              .doc(otherUid)
              .get(),
      builder: (
        BuildContext context,
        AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot,
      ) {
        final Map<String, dynamic>? data = snapshot.data?.data();

        final String displayName =
            (data?['displayName'] as String?)?.trim().isNotEmpty == true
                ? (data?['displayName'] as String).trim()
                : 'AgriAI Farmer';

        final String userId =
            (data?['userId'] as String?)?.trim() ?? '';

        final String photoUrl =
            (data?['photoUrl'] as String?)?.trim() ?? '';

        final String preview = conversation.lastMessage.trim().isEmpty
            ? 'Start a conversation'
            : conversation.lastMessage.trim();

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: Row(
                children: <Widget>[
                  _Avatar(
                    photoUrl: photoUrl,
                    displayName: displayName,
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF17351F),
                                ),
                              ),
                            ),
                            if (conversation.lastMessageAt != null)
                              Text(
                                _formatTime(
                                  conversation.lastMessageAt!,
                                ),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF89948C),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                        if (userId.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 2),
                          Text(
                            '@$userId',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF5F7464),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        const SizedBox(height: 5),
                        Text(
                          preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF7A857E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFFB0BBB4),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static String _formatTime(DateTime dateTime) {
    final DateTime now = DateTime.now();

    if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day) {
      final int hour = dateTime.hour;
      final int minute = dateTime.minute;
      final String suffix = hour >= 12 ? 'PM' : 'AM';
      final int displayHour = hour % 12 == 0 ? 12 : hour % 12;

      return '$displayHour:${minute.toString().padLeft(2, '0')} $suffix';
    }

    if (dateTime.year == now.year) {
      return '${dateTime.day}/${dateTime.month}';
    }

    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}

class _Avatar extends StatelessWidget {
  final String photoUrl;
  final String displayName;

  const _Avatar({
    required this.photoUrl,
    required this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    final String initial = displayName.trim().isEmpty
        ? 'A'
        : displayName.trim().substring(0, 1).toUpperCase();

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFE8F5E9),
        border: Border.all(
          color: const Color(0xFFD6E8D8),
        ),
      ),
      child: ClipOval(
        child: photoUrl.isNotEmpty
            ? Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, Object error, StackTrace? stackTrace) {
                  return _initial(initial);
                },
              )
            : _initial(initial),
      ),
    );
  }

  Widget _initial(String initial) {
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: Color(0xFF2E7D32),
          fontWeight: FontWeight.w800,
          fontSize: 20,
        ),
      ),
    );
  }
}

class DirectChatScreen extends StatefulWidget {
  final DirectConversation conversation;

  const DirectChatScreen({
    super.key,
    required this.conversation,
  });

  @override
  State<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  final TextEditingController _messageController =
      TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please sign in.'),
        ),
      );
    }

    final String otherUid = widget.conversation.participantUids.firstWhere(
      (String uid) => uid != currentUser.uid,
      orElse: () => '',
    );

    final String conversationId =
        DirectMessagesService.conversationIdForUsers(
      currentUser.uid,
      otherUid,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF17351F),
        elevation: 0.5,
        titleSpacing: 0,
        title: _ChatUserTitle(uid: otherUid),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: StreamBuilder<List<DirectMessage>>(
              stream: DirectMessagesService.watchMessages(
                conversationId: conversationId,
              ),
              builder: (
                BuildContext context,
                AsyncSnapshot<List<DirectMessage>> snapshot,
              ) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Unable to load chat.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final List<DirectMessage> messages =
                    snapshot.data ?? <DirectMessage>[];

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'Start the conversation 👋',
                      style: TextStyle(
                        color: Color(0xFF6B776F),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                  itemCount: messages.length,
                  itemBuilder: (
                    BuildContext context,
                    int index,
                  ) {
                    final DirectMessage message = messages[index];
                    final bool isMine =
                        message.senderUid == currentUser.uid;

                    return _MessageBubble(
                      message: message,
                      isMine: isMine,
                    );
                  },
                );
              },
            ),
          ),
          _buildComposer(
            currentUid: currentUser.uid,
            receiverUid: otherUid,
            conversationId: conversationId,
          ),
        ],
      ),
    );
  }

  Widget _buildComposer({
    required String currentUid,
    required String receiverUid,
    required String conversationId,
  }) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Color(0xFFE4EAE5),
            ),
          ),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _messageController,
                textCapitalization: TextCapitalization.sentences,
                minLines: 1,
                maxLines: 5,
                onSubmitted: (_) => _sendText(
                  conversationId: conversationId,
                  receiverUid: receiverUid,
                ),
                decoration: InputDecoration(
                  hintText: 'Message...',
                  filled: true,
                  fillColor: const Color(0xFFF3F7F4),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: const Color(0xFF2E7D32),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _sendText(
                  conversationId: conversationId,
                  receiverUid: receiverUid,
                ),
                child: const Padding(
                  padding: EdgeInsets.all(13),
                  child: Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 21,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendText({
    required String conversationId,
    required String receiverUid,
  }) async {
    final String text = _messageController.text.trim();

    if (text.isEmpty) {
      return;
    }

    _messageController.clear();

    try {
      await DirectMessagesService.sendTextMessage(
        conversationId: conversationId,
        receiverUid: receiverUid,
        text: text,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $error'),
        ),
      );
    }
  }
}

class _ChatUserTitle extends StatelessWidget {
  final String uid;

  const _ChatUserTitle({
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    if (uid.isEmpty) {
      return const Text(
        'Farmer',
        style: TextStyle(
          fontWeight: FontWeight.w700,
        ),
      );
    }

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get(),
      builder: (
        BuildContext context,
        AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot,
      ) {
        final Map<String, dynamic>? data = snapshot.data?.data();

        final String name =
            (data?['displayName'] as String?)?.trim().isNotEmpty == true
                ? (data?['displayName'] as String).trim()
                : 'Farmer';

        final String userId =
            (data?['userId'] as String?)?.trim() ?? '';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            if (userId.isNotEmpty)
              Text(
                '@$userId',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF66806C),
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final DirectMessage message;
  final bool isMine;

  const _MessageBubble({
    required this.message,
    required this.isMine,
  });

  @override
  Widget build(BuildContext context) {
    final String messageType = message.type.toString().toLowerCase();

    final bool isPost = messageType == 'post';
    final bool isReel = messageType == 'reel';

    String label;

    if (isPost) {
      label = 'Shared Post';
    } else if (isReel) {
      label = 'Shared Reel';
    } else {
      label = message.text.trim().isEmpty
          ? 'Message'
          : message.text.trim();
    }

    final bool isSharedContent = isPost || isReel;

    return Align(
      alignment:
          isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isMine
              ? const Color(0xFF2E7D32)
              : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMine ? 18 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 18),
          ),
          boxShadow: isMine
              ? null
              : <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (isSharedContent) ...<Widget>[
              Icon(
                isPost
                    ? Icons.article_rounded
                    : Icons.play_circle_rounded,
                size: 19,
                color: isMine
                    ? Colors.white
                    : const Color(0xFF2E7D32),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isMine
                      ? Colors.white
                      : const Color(0xFF26352C),
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: isSharedContent
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
