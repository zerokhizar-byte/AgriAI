import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<_Reel> _reels = <_Reel>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_loadReels());
  }

  Future<void> _loadReels() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _firestore.collection('farmerVideos').get();

      final List<_Reel> reels = snapshot.docs
          .map((doc) => _Reel.fromDocument(doc))
          .where((reel) => reel.url.isNotEmpty)
          .toList();

      reels.sort(
        (a, b) => b.createdAt.compareTo(a.createdAt),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _reels = reels;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _reels.isEmpty
              ? _EmptyReels(
                  onRefresh: _loadReels,
                )
              : PageView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: _reels.length,
                  itemBuilder: (context, index) {
                    return _ReelPage(
                      reel: _reels[index],
                    );
                  },
                ),
    );
  }
}

class _ReelPage extends StatefulWidget {
  final _Reel reel;

  const _ReelPage({
    required this.reel,
  });

  @override
  State<_ReelPage> createState() => _ReelPageState();
}

class _ReelPageState extends State<_ReelPage> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_init());
  }

  Future<void> _init() async {
    try {
      final VideoPlayerController controller =
          VideoPlayerController.networkUrl(
        Uri.parse(widget.reel.url),
      );

      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _failed = true;
      });
    }
  }

  void _togglePlayback() {
    final VideoPlayerController? controller = _controller;

    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
      } else {
        controller.play();
      }
    });
  }

  @override
  void dispose() {
    final VideoPlayerController? controller = _controller;

    if (controller != null) {
      unawaited(controller.dispose());
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final VideoPlayerController? controller = _controller;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        if (controller != null && controller.value.isInitialized)
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          )
        else
          Container(
            color: Colors.black,
            child: Center(
              child: _failed
                  ? const Text(
                      'Unable to load reel',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    )
                  : const CircularProgressIndicator(
                      color: Colors.white,
                    ),
            ),
          ),

        // Full-screen playback control.
        if (controller != null && controller.value.isInitialized)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: false,
              child: GestureDetector(
                onTap: _togglePlayback,
                behavior: HitTestBehavior.translucent,
              ),
            ),
          ),

        // Top header.
        Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          left: 18,
          right: 12,
          child: Row(
            children: <Widget>[
              const Text(
                'AgriAI Reels',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),

        // Reel information.
        Positioned(
          left: 18,
          right: 78,
          bottom: 32,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '@${widget.reel.authorId}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                widget.reel.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),

        // Reel actions.
        Positioned(
          right: 16,
          bottom: 35,
          child: Column(
            children: <Widget>[
              _Action(
                icon: Icons.favorite_border_rounded,
                label: 'Like',
              ),
              const SizedBox(height: 18),
              _Action(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Comment',
              ),
              const SizedBox(height: 18),
              _Action(
                icon: Icons.share_outlined,
                label: 'Share',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Action({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Icon(
          icon,
          color: Colors.white,
          size: 28,
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}

class _EmptyReels extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _EmptyReels({
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.video_library_outlined,
            color: Colors.white,
            size: 54,
          ),
          const SizedBox(height: 12),
          const Text(
            'No farming reels yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Upload a video from Home to start the community.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => unawaited(onRefresh()),
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}

class _Reel {
  final String url;
  final String title;
  final String authorId;
  final DateTime createdAt;

  const _Reel({
    required this.url,
    required this.title,
    required this.authorId,
    required this.createdAt,
  });

  factory _Reel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> data =
        doc.data() ?? <String, dynamic>{};

    final dynamic timestamp = data['createdAt'];

    final DateTime createdAt = timestamp is Timestamp
        ? timestamp.toDate()
        : DateTime.tryParse(
              '${timestamp ?? ''}',
            ) ??
            DateTime.fromMillisecondsSinceEpoch(0);

    return _Reel(
      url: '${data['cloudinaryUrl'] ?? ''}',
      title: '${data['title'] ?? 'Farming reel'}',
      authorId:
          '${data['userId'] ?? data['authorId'] ?? data['author'] ?? 'farmer'}',
      createdAt: createdAt,
    );
  }
}