import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../services/direct_messages_service.dart';

class DirectMessagesScreen extends StatefulWidget {
  const DirectMessagesScreen({super.key});

  @override
  State<DirectMessagesScreen> createState() => _DirectMessagesScreenState();
}

class _DirectMessagesScreenState extends State<DirectMessagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _search = '';

  User get _currentUser => FirebaseAuth.instance.currentUser!;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _getUser(
    String uid,
  ) {
    return FirebaseFirestore.instance.collection('users').doc(uid).get();
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Color(0xFF173D27),
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'New message',
            onPressed: () => _openNewMessage(context),
            icon: const Icon(
              Icons.edit_rounded,
              color: Color(0xFF1B7F45),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() => _search = value.trim().toLowerCase());
              },
              decoration: InputDecoration(
                hintText: 'Search conversations',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _search.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _search = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<DirectConversation>>(
              stream: DirectMessagesService.watchConversations(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _EmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'Could not load messages',
                    subtitle: snapshot.error.toString(),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF1B7F45),
                    ),
                  );
                }

                final conversations = snapshot.data ?? <DirectConversation>[];

                if (conversations.isEmpty) {
                  return const _EmptyState(
                    icon: Icons.forum_outlined,
                    title: 'No conversations yet',
                    subtitle:
                        'Start a conversation with a farmer from AgriAI.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                  itemCount: conversations.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    return _ConversationTile(
                      conversation: conversations[index],
                      currentUid: user.uid,
                      search: _search,
                      loadUser: _getUser,
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

  Future<void> _openNewMessage(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _NewMessageSheet(),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final DirectConversation conversation;
  final String currentUid;
  final String search;
  final Future<DocumentSnapshot<Map<String, dynamic>>> Function(String uid)
      loadUser;

  const _ConversationTile({
    required this.conversation,
    required this.currentUid,
    required this.search,
    required this.loadUser,
  });

  @override
  Widget build(BuildContext context) {
    final otherUid = conversation.otherParticipantUid(currentUid);
    final unread = conversation.unreadCountFor(currentUid);

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: loadUser(otherUid),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? <String, dynamic>{};
        final name = (data['displayName'] ?? 'Farmer').toString();
        final userId = (data['userId'] ?? '').toString();

        if (search.isNotEmpty &&
            !name.toLowerCase().contains(search) &&
            !userId.toLowerCase().contains(search)) {
          return const SizedBox.shrink();
        }

        final photoUrl = (data['photoUrl'] ?? '').toString();

        return Material(
          color: unread > 0 ? const Color(0xFFEAF7EE) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => DirectChatScreen(
                    otherUid: otherUid,
                    otherName: name,
                    otherPhotoUrl: photoUrl,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _Avatar(
                        photoUrl: photoUrl,
                        name: name,
                        size: 54,
                      ),
                      if (unread > 0)
                        Positioned(
                          right: -3,
                          top: -3,
                          child: Container(
                            constraints: const BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B7F45),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              unread > 99 ? '99+' : '$unread',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: unread > 0
                                      ? FontWeight.w800
                                      : FontWeight.w700,
                                  color: const Color(0xFF173D27),
                                  fontSize: 15.5,
                                ),
                              ),
                            ),
                            if (conversation.lastMessageAt != null)
                              Text(
                                _formatTime(conversation.lastMessageAt!),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: unread > 0
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                  color: unread > 0
                                      ? const Color(0xFF1B7F45)
                                      : Colors.grey.shade500,
                                ),
                              ),
                          ],
                        ),
                        if (userId.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            '@$userId',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _conversationPreview(conversation),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: unread > 0
                                      ? const Color(0xFF173D27)
                                      : Colors.grey.shade600,
                                  fontSize: 13,
                                  fontWeight: unread > 0
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 21,
                              color: unread > 0
                                  ? const Color(0xFF1B7F45)
                                  : Colors.grey.shade400,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _conversationPreview(DirectConversation conversation) {
    switch (conversation.lastMessageType) {
      case 'post':
        return '📷 Shared a post';
      case 'reel':
        return '🎬 Shared a Reel';
      default:
        return conversation.lastMessage.isEmpty
            ? 'Start a conversation'
            : conversation.lastMessage;
    }
  }
}

class DirectChatScreen extends StatefulWidget {
  final String otherUid;
  final String otherName;
  final String otherPhotoUrl;

  const DirectChatScreen({
    super.key,
    required this.otherUid,
    required this.otherName,
    this.otherPhotoUrl = '',
  });

  @override
  State<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final String _conversationId;

  User get _currentUser => FirebaseAuth.instance.currentUser!;

  @override
  void initState() {
    super.initState();

    _conversationId = DirectMessagesService.conversationIdForUsers(
      _currentUser.uid,
      widget.otherUid,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markConversationAsSeen();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _markConversationAsSeen() async {
    try {
      await DirectMessagesService.markMessagesSeen(
        conversationId: _conversationId,
      );
    } catch (_) {}
  }

  Future<void> _sendText() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();

    try {
      await DirectMessagesService.sendTextMessage(
        conversationId: _conversationId,
        receiverUid: widget.otherUid,
        text: text,
      );
      await _markConversationAsSeen();
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send message: $e')),
      );
    }
  }

  Future<void> _openSharePicker() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _ChatShareSheet(
        receiverUid: widget.otherUid,
        conversationId: _conversationId,
      ),
    );
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF173D27),
            size: 20,
          ),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            _Avatar(
              photoUrl: widget.otherPhotoUrl,
              name: widget.otherName,
              size: 40,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF173D27),
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'AgriAI farmer chat',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<DirectMessage>>(
              stream: DirectMessagesService.watchMessages(
                conversationId: _conversationId,
                limit: 100,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Could not load messages.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF1B7F45),
                    ),
                  );
                }

                final messages = snapshot.data ?? <DirectMessage>[];

                if (messages.isEmpty) {
                  return _ChatEmptyState(name: widget.otherName);
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _markConversationAsSeen();
                });

                return ListView.builder(
                  controller: _scrollController,
                  reverse: false,
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 18),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMine = message.senderUid == _currentUser.uid;

                    return _MessageBubble(
                      message: message,
                      isMine: isMine,
                      otherName: widget.otherName,
                    );
                  },
                );
              },
            ),
          ),
          _MessageComposer(
            controller: _controller,
            onSend: _sendText,
            onShare: _openSharePicker,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final DirectMessage message;
  final bool isMine;
  final String otherName;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.otherName,
  });

  @override
  Widget build(BuildContext context) {
    final isPost = message.type == DirectMessageType.post.name;
    final isReel = message.type == DirectMessageType.reel.name;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * .84,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (isPost)
              _SharedPostCard(
                postId: message.postId,
                fallbackMediaUrl: message.mediaUrl,
                fallbackText: message.text,
                isMine: isMine,
              )
            else if (isReel)
              _SharedReelCard(
                reelId: message.reelId,
                fallbackMediaUrl: message.mediaUrl,
                fallbackText: message.text,
                isMine: isMine,
              )
            else
              _TextMessage(
                text: message.text,
                isMine: isMine,
              ),
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Text(
                _formatMessageTime(message.createdAt),
                style: TextStyle(
                  fontSize: 9.5,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextMessage extends StatelessWidget {
  final String text;
  final bool isMine;

  const _TextMessage({
    required this.text,
    required this.isMine,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: isMine ? const Color(0xFF1B7F45) : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(19),
          topRight: const Radius.circular(19),
          bottomLeft: Radius.circular(isMine ? 19 : 5),
          bottomRight: Radius.circular(isMine ? 5 : 19),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .035),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isMine ? Colors.white : const Color(0xFF173D27),
          fontSize: 14.5,
          height: 1.35,
        ),
      ),
    );
  }
}

class _SharedPostCard extends StatefulWidget {
  final String postId;
  final String fallbackMediaUrl;
  final String fallbackText;
  final bool isMine;

  const _SharedPostCard({
    required this.postId,
    required this.fallbackMediaUrl,
    required this.fallbackText,
    required this.isMine,
  });

  @override
  State<_SharedPostCard> createState() => _SharedPostCardState();
}

class _SharedPostCardState extends State<_SharedPostCard> {
  late Future<DocumentSnapshot<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = FirebaseFirestore.instance
        .collection('communityPosts')
        .doc(widget.postId)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SharedLoadingCard(
            icon: Icons.article_rounded,
            label: 'Loading shared post…',
          );
        }

        final data = snapshot.data?.data();

        if (data == null) {
          return _DeletedShareCard(
            icon: Icons.article_outlined,
            title: 'Post unavailable',
            subtitle: widget.fallbackText.isEmpty
                ? 'This post may have been removed.'
                : widget.fallbackText,
          );
        }

        final text = (data['text'] ?? widget.fallbackText).toString().trim();
        final mediaUrl =
            (data['mediaUrl'] ?? widget.fallbackMediaUrl).toString().trim();
        final displayName = (data['displayName'] ?? data['author'] ?? 'Farmer')
            .toString();
        final userId = (data['userId'] ?? data['authorId'] ?? '').toString();
        final photoUrl = (data['photoUrl'] ?? '').toString();
        final postType = (data['postType'] ?? 'Post').toString();

        return _RichShareCard(
          isMine: widget.isMine,
          accentIcon: Icons.article_rounded,
          accentLabel: 'SHARED POST',
          title: displayName,
          handle: userId,
          avatarUrl: photoUrl,
          mediaUrl: mediaUrl,
          text: text,
          footer: postType,
        );
      },
    );
  }
}

class _SharedReelCard extends StatefulWidget {
  final String reelId;
  final String fallbackMediaUrl;
  final String fallbackText;
  final bool isMine;

  const _SharedReelCard({
    required this.reelId,
    required this.fallbackMediaUrl,
    required this.fallbackText,
    required this.isMine,
  });

  @override
  State<_SharedReelCard> createState() => _SharedReelCardState();
}

class _SharedReelCardState extends State<_SharedReelCard> {
  late Future<DocumentSnapshot<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = FirebaseFirestore.instance
        .collection('farmerVideos')
        .doc(widget.reelId)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SharedLoadingCard(
            icon: Icons.play_circle_rounded,
            label: 'Loading shared Reel…',
          );
        }

        final data = snapshot.data?.data();

        if (data == null) {
          return _DeletedShareCard(
            icon: Icons.play_circle_outline_rounded,
            title: 'Reel unavailable',
            subtitle: widget.fallbackText.isEmpty
                ? 'This Reel may have been removed.'
                : widget.fallbackText,
          );
        }

        final title = (data['title'] ?? widget.fallbackText).toString().trim();
        final mediaUrl = (data['cloudinaryUrl'] ?? data['mediaUrl'] ??
                widget.fallbackMediaUrl)
            .toString()
            .trim();
        final displayName =
            (data['author'] ?? data['displayName'] ?? 'Farmer').toString();
        final userId =
            (data['userId'] ?? data['authorId'] ?? '').toString();

        return _RichShareCard(
          isMine: widget.isMine,
          accentIcon: Icons.play_circle_rounded,
          accentLabel: 'SHARED REEL',
          title: displayName,
          handle: userId,
          avatarUrl: '',
          mediaUrl: mediaUrl,
          text: title,
          footer: 'Farming video',
          isVideo: true,
        );
      },
    );
  }
}

class _RichShareCard extends StatelessWidget {
  final bool isMine;
  final IconData accentIcon;
  final String accentLabel;
  final String title;
  final String handle;
  final String avatarUrl;
  final String mediaUrl;
  final String text;
  final String footer;
  final bool isVideo;

  const _RichShareCard({
    required this.isMine,
    required this.accentIcon,
    required this.accentLabel,
    required this.title,
    required this.handle,
    required this.avatarUrl,
    required this.mediaUrl,
    required this.text,
    required this.footer,
    this.isVideo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 310,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isMine
              ? const Color(0xFF9DD5AF)
              : const Color(0xFFDCEBE0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .055),
            blurRadius: 13,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(13, 11, 13, 9),
            decoration: const BoxDecoration(
              color: Color(0xFFF0F8F2),
            ),
            child: Row(
              children: [
                Icon(
                  accentIcon,
                  color: const Color(0xFF1B7F45),
                  size: 18,
                ),
                const SizedBox(width: 7),
                Text(
                  accentLabel,
                  style: const TextStyle(
                    color: Color(0xFF1B7F45),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .7,
                  ),
                ),
              ],
            ),
          ),
          if (mediaUrl.isNotEmpty)
            isVideo
                ? _VideoPreview(url: mediaUrl)
                : _ImagePreview(url: mediaUrl),
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 12, 13, 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Avatar(
                      photoUrl: avatarUrl,
                      name: title,
                      size: 32,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title.isEmpty ? 'Farmer' : title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF173D27),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (handle.isNotEmpty)
                            Text(
                              '@$handle',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 10.5,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (text.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    text,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF26392D),
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.eco_rounded,
                      size: 15,
                      color: Color(0xFF1B7F45),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        footer,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.open_in_new_rounded,
                      size: 15,
                      color: Color(0xFF1B7F45),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final String url;

  const _ImagePreview({required this.url});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.35,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          color: const Color(0xFFEAF4EC),
          alignment: Alignment.center,
          child: const Icon(
            Icons.broken_image_outlined,
            color: Color(0xFF6D8B76),
            size: 34,
          ),
        ),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: const Color(0xFFEAF4EC),
            alignment: Alignment.center,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF1B7F45),
            ),
          );
        },
      ),
    );
  }
}

class _VideoPreview extends StatefulWidget {
  final String url;

  const _VideoPreview({required this.url});

  @override
  State<_VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<_VideoPreview> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.url),
      );

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      controller.setLooping(true);
      _controller = controller;
      setState(() {});
    } catch (_) {
      if (mounted) {
        setState(() => _failed = true);
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Container(
        height: 220,
        color: const Color(0xFFEAF4EC),
        alignment: Alignment.center,
        child: const Icon(
          Icons.videocam_off_outlined,
          color: Color(0xFF6D8B76),
          size: 34,
        ),
      );
    }

    final controller = _controller;

    if (controller == null || !controller.value.isInitialized) {
      return Container(
        height: 220,
        color: const Color(0xFF173D27),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white,
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        if (controller.value.isPlaying) {
          controller.pause();
        } else {
          controller.play();
        }
        setState(() {});
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
          if (!controller.value.isPlaying)
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .48),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          Positioned(
            right: 9,
            bottom: 9,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 7,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .55),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.play_circle_outline_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'REEL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SharedLoadingCard extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SharedLoadingCard({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 310,
      height: 92,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCEBE0)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF1B7F45),
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF173D27),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeletedShareCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _DeletedShareCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 310,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCEBE0)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.grey.shade500,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF173D27),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11.5,
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

class _MessageComposer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onShare;

  const _MessageComposer({
    required this.controller,
    required this.onSend,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .06),
              blurRadius: 14,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Material(
              color: const Color(0xFFE8F4EB),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onShare,
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.add_rounded,
                    color: Color(0xFF1B7F45),
                    size: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: TextField(
                controller: controller,
                textCapitalization: TextCapitalization.sentences,
                minLines: 1,
                maxLines: 5,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'Message farmer…',
                  filled: true,
                  fillColor: const Color(0xFFF2F6F3),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 11,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 7),
            Material(
              color: const Color(0xFF1B7F45),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onSend,
                child: const SizedBox(
                  width: 46,
                  height: 46,
                  child: Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatEmptyState extends StatelessWidget {
  final String name;

  const _ChatEmptyState({required this.name});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: Color(0xFFE6F4EA),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.eco_rounded,
                color: Color(0xFF1B7F45),
                size: 38,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Start with $name',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF173D27),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Share farming ideas, posts and Reels or simply say hello.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewMessageSheet extends StatefulWidget {
  const _NewMessageSheet();

  @override
  State<_NewMessageSheet> createState() => _NewMessageSheetState();
}

class _NewMessageSheetState extends State<_NewMessageSheet> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .82,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Column(
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 18),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'New message',
                  style: TextStyle(
                    color: Color(0xFF173D27),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                onChanged: (value) {
                  setState(() => _query = value.trim().toLowerCase());
                },
                decoration: InputDecoration(
                  hintText: 'Search farmer by name or @user ID',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: const Color(0xFFF3F7F4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .limit(100)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF1B7F45),
                        ),
                      );
                    }

                    final docs = snapshot.data!.docs.where((doc) {
                      if (doc.id == currentUid) return false;
                      if (_query.isEmpty) return true;

                      final data = doc.data();
                      final name =
                          (data['displayName'] ?? '').toString().toLowerCase();
                      final userId =
                          (data['userId'] ?? '').toString().toLowerCase();

                      return name.contains(_query) ||
                          userId.contains(_query);
                    }).toList();

                    if (docs.isEmpty) {
                      return const _EmptyState(
                        icon: Icons.person_search_rounded,
                        title: 'No farmers found',
                        subtitle: 'Try another name or AgriAI User ID.',
                      );
                    }

                    return ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final data = docs[index].data();
                        final uid = docs[index].id;
                        final name =
                            (data['displayName'] ?? 'Farmer').toString();
                        final userId = (data['userId'] ?? '').toString();
                        final photoUrl = (data['photoUrl'] ?? '').toString();

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 4,
                          ),
                          leading: _Avatar(
                            photoUrl: photoUrl,
                            name: name,
                            size: 46,
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF173D27),
                            ),
                          ),
                          subtitle:
                              userId.isEmpty ? null : Text('@$userId'),
                          trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: Color(0xFF1B7F45),
                          ),
                          onTap: () async {
                            final conversationId =
                                await DirectMessagesService
                                    .getOrCreateConversation(
                              otherUid: uid,
                            );

                            if (!context.mounted) return;

                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => DirectChatScreen(
                                  otherUid: uid,
                                  otherName: name,
                                  otherPhotoUrl: photoUrl,
                                ),
                              ),
                            );

                            debugPrint(
                              'AgriAI: opened conversation $conversationId',
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
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String photoUrl;
  final String name;
  final double size;

  const _Avatar({
    required this.photoUrl,
    required this.name,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? 'F' : name.trim()[0].toUpperCase();

    if (photoUrl.trim().isEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: const Color(0xFFDFF0E3),
        child: Text(
          initial,
          style: TextStyle(
            color: const Color(0xFF1B7F45),
            fontSize: size * .34,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: const Color(0xFFDFF0E3),
      backgroundImage: NetworkImage(photoUrl),
      onBackgroundImageError: (_, _) {},
      child: const SizedBox.shrink(),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: const Color(0xFF78A687),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF173D27),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _ChatShareSheet extends StatefulWidget {
  final String receiverUid;
  final String conversationId;

  const _ChatShareSheet({
    required this.receiverUid,
    required this.conversationId,
  });

  @override
  State<_ChatShareSheet> createState() => _ChatShareSheetState();
}

class _ChatShareSheetState extends State<_ChatShareSheet> {
  int _tab = 0;
  bool _sending = false;

  Future<void> _sendPost(
    String postId,
    String mediaUrl,
    String text,
  ) async {
    await _send(
      type: 'post',
      id: postId,
      mediaUrl: mediaUrl,
      text: text,
    );
  }

  Future<void> _sendReel(
    String reelId,
    String mediaUrl,
    String text,
  ) async {
    await _send(
      type: 'reel',
      id: reelId,
      mediaUrl: mediaUrl,
      text: text,
    );
  }

  Future<void> _send({
    required String type,
    required String id,
    required String mediaUrl,
    required String text,
  }) async {
    if (_sending) return;

    setState(() => _sending = true);

    try {
      if (type == 'post') {
        await DirectMessagesService.sendPostMessage(
          conversationId: widget.conversationId,
          receiverUid: widget.receiverUid,
          postId: id,
          text: text,
          mediaUrl: mediaUrl,
        );
      } else {
        await DirectMessagesService.sendReelMessage(
          conversationId: widget.conversationId,
          receiverUid: widget.receiverUid,
          reelId: id,
          text: text,
          mediaUrl: mediaUrl,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            type == 'post'
                ? 'Post shared in chat'
                : 'Reel shared in chat',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1B7F45),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not share: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .78,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 14),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Share to chat',
                  style: TextStyle(
                    color: Color(0xFF173D27),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F5F1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _ShareTab(
                      label: 'Posts',
                      icon: Icons.article_rounded,
                      selected: _tab == 0,
                      onTap: () => setState(() => _tab = 0),
                    ),
                    _ShareTab(
                      label: 'Reels',
                      icon: Icons.play_circle_rounded,
                      selected: _tab == 1,
                      onTap: () => setState(() => _tab = 1),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _tab == 0
                  ? _PostShareList(
                      onSelect: _sendPost,
                      sending: _sending,
                    )
                  : _ReelShareList(
                      onSelect: _sendReel,
                      sending: _sending,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ShareTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected
                      ? const Color(0xFF1B7F45)
                      : Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? const Color(0xFF173D27)
                        : Colors.grey.shade600,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PostShareList extends StatelessWidget {
  final Future<void> Function(
    String postId,
    String mediaUrl,
    String text,
  ) onSelect;
  final bool sending;

  const _PostShareList({
    required this.onSelect,
    required this.sending,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('communityPosts')
          .orderBy('createdAt', descending: true)
          .limit(30)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ShareError(message: snapshot.error.toString());
        }

        if (!snapshot.hasData) {
          return const _ShareLoading();
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const _ShareEmpty(
            icon: Icons.article_outlined,
            title: 'No posts yet',
            subtitle: 'Create a community post first.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 22),
          itemCount: docs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 9),
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final text = (data['text'] ?? '').toString().trim();
            final mediaUrl = (data['mediaUrl'] ?? '').toString().trim();
            final author =
                (data['displayName'] ?? data['author'] ?? 'Farmer').toString();
            final photoUrl = (data['photoUrl'] ?? '').toString();

            return _ShareContentTile(
              icon: Icons.article_rounded,
              label: 'POST',
              title: author,
              subtitle: text.isEmpty ? 'Photo post' : text,
              mediaUrl: mediaUrl,
              photoUrl: photoUrl,
              sending: sending,
              onTap: () => onSelect(
                docs[index].id,
                mediaUrl,
                text,
              ),
            );
          },
        );
      },
    );
  }
}

class _ReelShareList extends StatelessWidget {
  final Future<void> Function(
    String reelId,
    String mediaUrl,
    String text,
  ) onSelect;
  final bool sending;

  const _ReelShareList({
    required this.onSelect,
    required this.sending,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('farmerVideos')
          .orderBy('createdAt', descending: true)
          .limit(30)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ShareError(message: snapshot.error.toString());
        }

        if (!snapshot.hasData) {
          return const _ShareLoading();
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const _ShareEmpty(
            icon: Icons.play_circle_outline_rounded,
            title: 'No Reels yet',
            subtitle: 'Create a farming Reel first.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 22),
          itemCount: docs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 9),
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final text = (data['title'] ?? '').toString().trim();
            final mediaUrl =
                (data['cloudinaryUrl'] ?? data['mediaUrl'] ?? '')
                    .toString()
                    .trim();
            final author =
                (data['author'] ?? data['displayName'] ?? 'Farmer').toString();

            return _ShareContentTile(
              icon: Icons.play_circle_rounded,
              label: 'REEL',
              title: author,
              subtitle: text.isEmpty ? 'Farming video' : text,
              mediaUrl: mediaUrl,
              photoUrl: '',
              isVideo: true,
              sending: sending,
              onTap: () => onSelect(
                docs[index].id,
                mediaUrl,
                text,
              ),
            );
          },
        );
      },
    );
  }
}

class _ShareContentTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String title;
  final String subtitle;
  final String mediaUrl;
  final String photoUrl;
  final bool isVideo;
  final bool sending;
  final VoidCallback onTap;

  const _ShareContentTile({
    required this.icon,
    required this.label,
    required this.title,
    required this.subtitle,
    required this.mediaUrl,
    required this.photoUrl,
    required this.sending,
    required this.onTap,
    this.isVideo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: sending ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFDCEBE0)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: SizedBox(
                  width: 74,
                  height: 74,
                  child: mediaUrl.isEmpty
                      ? Container(
                          color: const Color(0xFFE8F4EB),
                          alignment: Alignment.center,
                          child: Icon(
                            icon,
                            color: const Color(0xFF1B7F45),
                            size: 30,
                          ),
                        )
                      : isVideo
                          ? Container(
                              color: const Color(0xFF173D27),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 34,
                              ),
                            )
                          : Image.network(
                              mediaUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                color: const Color(0xFFE8F4EB),
                                alignment: Alignment.center,
                                child: Icon(
                                  icon,
                                  color: const Color(0xFF1B7F45),
                                ),
                              ),
                            ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          icon,
                          size: 14,
                          color: const Color(0xFF1B7F45),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          label,
                          style: const TextStyle(
                            color: Color(0xFF1B7F45),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .7,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF173D27),
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFF1B7F45),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 17,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShareLoading extends StatelessWidget {
  const _ShareLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFF1B7F45),
      ),
    );
  }
}

class _ShareEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ShareEmpty({
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 46,
              color: const Color(0xFF78A687),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF173D27),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareError extends StatelessWidget {
  final String message;

  const _ShareError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Unable to load content.\n$message',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ),
    );
  }
}

String _formatTime(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inMinutes < 1) return 'now';
  if (difference.inHours < 1) return '${difference.inMinutes}m';
  if (difference.inDays < 1) return '${difference.inHours}h';
  if (difference.inDays < 7) return '${difference.inDays}d';

  return '${dateTime.day}/${dateTime.month}';
}

String _formatMessageTime(DateTime? dateTime) {
  if (dateTime == null) return '';

  final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final period = dateTime.hour >= 12 ? 'PM' : 'AM';

  return '$hour:$minute $period';
}
