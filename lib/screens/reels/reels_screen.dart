import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme/app_colors.dart';
import '../../services/cloudinary_media_service.dart';
import '../../services/direct_messages_service.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen>
    with WidgetsBindingObserver {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final PageController _pageController =
      PageController();

  List<_Reel> _reels = <_Reel>[];

  bool _loading = true;
  bool _uploading = false;
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_loadReels());
  }

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state != AppLifecycleState.resumed) {
      // Each active reel observes this through the lifecycle
      // and pauses itself.
    }
  }

  Future<void> _loadReels() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final QuerySnapshot<Map<String, dynamic>>
          snapshot = await _firestore
              .collection('farmerVideos')
              .limit(100)
              .get();

      final List<_Reel> loaded =
          snapshot.docs
              .map(
                (QueryDocumentSnapshot<
                        Map<String, dynamic>> document) =>
                    _Reel.fromDocument(document),
              )
              .where(
                (_Reel reel) =>
                    reel.url.isNotEmpty,
              )
              .toList();

      loaded.sort(
        (_Reel a, _Reel b) {
          final int scoreCompare =
              b.recommendationScore.compareTo(
            a.recommendationScore,
          );

          if (scoreCompare != 0) {
            return scoreCompare;
          }

          return b.createdAt.compareTo(a.createdAt);
        },
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _reels = loaded;
        _activeIndex = 0;
        _loading = false;
      });
    } on FirebaseException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });

      _showMessage(
        'Unable to load Reels: ${error.message ?? error.code}',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });

      _showMessage(
        'Unable to load Reels: $error',
      );
    }
  }

  Future<void> _createReel() async {
    if (_uploading) {
      return;
    }

    final XFile? file =
        await ImagePicker().pickVideo(
      source: ImageSource.gallery,
      maxDuration:
          const Duration(minutes: 2),
    );

    if (file == null || !mounted) {
      return;
    }

    final String? title =
        await showDialog<String>(
      context: context,
      builder: (
        BuildContext dialogContext,
      ) {
        final TextEditingController controller =
            TextEditingController();

        return AlertDialog(
          title: const Text(
            'Create a Farming Reel',
            style: TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 120,
            maxLines: 2,
            decoration:
                const InputDecoration(
              hintText:
                  'Add a title or caption…',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () =>
                  Navigator.of(
                dialogContext,
              ).pop(),
              child:
                  const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(
                dialogContext,
              ).pop(
                controller.text.trim(),
              ),
              child:
                  const Text('Continue'),
            ),
          ],
        );
      },
    );

    if (!mounted ||
        title == null) {
      return;
    }

    setState(() {
      _uploading = true;
    });

    try {
      _showMessage(
        'Uploading your Reel…',
      );

      final CloudinaryUploadResult result =
          await CloudinaryMediaService
              .uploadVideo(file);

      final User? user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw FirebaseException(
          plugin: 'firebase_auth',
          code: 'not-authenticated',
          message:
              'Please sign in before uploading a Reel.',
        );
      }

      final DocumentReference<
          Map<String, dynamic>> reference =
          _firestore
              .collection('farmerVideos')
              .doc();

      final DocumentSnapshot<
          Map<String, dynamic>> userSnapshot =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .get();

      final Map<String, dynamic> userData =
          userSnapshot.data() ??
              <String, dynamic>{};

      final String displayName =
          '${userData['displayName'] ?? user.displayName ?? 'AgriAI Farmer'}'
              .trim();

      final String userId =
          '${userData['userId'] ?? ''}'
              .trim();

      final String finalTitle =
          title.trim().isEmpty
              ? 'Farming moments from my field 🌱'
              : title.trim();

      await reference.set(
        <String, dynamic>{
          'author':
              displayName.isEmpty
                  ? 'AgriAI Farmer'
                  : displayName,
          'authorId':
              user.uid,
          'userId':
              userId,
          'title':
              finalTitle,
          'cloudinaryUrl':
              result.secureUrl,
          'publicId':
              result.publicId,
          'resourceType':
              result.resourceType,
          'format':
              result.format,
          'originalFilename':
              result.originalFilename,
          'bytes':
              result.bytes,
          'width':
              result.width,
          'height':
              result.height,
          'duration':
              result.duration,
          'likesCount':
              0,
          'commentsCount':
              0,
          'sharesCount':
              0,
          'viewsCount':
              0,
          'createdAt':
              Timestamp.now(),
        },
      );

      await reference.get();

      await _loadReels();

      if (!mounted) {
        return;
      }

      _showMessage(
        'Reel published successfully.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Reel upload failed: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior:
              SnackBarBehavior.floating,
          duration:
              const Duration(seconds: 3),
        ),
      );
  }

  void _onPageChanged(int index) {
    if (!mounted) {
      return;
    }

    setState(() {
      _activeIndex = index;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance
        .removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          Colors.black,
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(
                color:
                    Colors.white,
              ),
            )
          : _reels.isEmpty
              ? _EmptyReels(
                  onRefresh:
                      _loadReels,
                  onCreate:
                      _createReel,
                )
              : Stack(
                  children: <Widget>[
                    PageView.builder(
                      controller:
                          _pageController,
                      scrollDirection:
                          Axis.vertical,
                      itemCount:
                          _reels.length,
                      onPageChanged:
                          _onPageChanged,
                      itemBuilder: (
                        BuildContext context,
                        int index,
                      ) {
                        return _ReelPage(
                          key: ValueKey<String>(
                            _reels[index].id,
                          ),
                          reel:
                              _reels[index],
                          isActive:
                              index ==
                                  _activeIndex,
                          onChanged:
                              _loadReels,
                        );
                      },
                    ),
                    Positioned(
                      top:
                          MediaQuery.of(context)
                                  .padding
                                  .top +
                              10,
                      left: 16,
                      right: 14,
                      child: Row(
                        children: <Widget>[
                          Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 13,
                              vertical: 8,
                            ),
                            decoration:
                                BoxDecoration(
                              color:
                                  Colors.black.withValues(
                                alpha: 0.32,
                              ),
                              borderRadius:
                                  BorderRadius.circular(
                                14,
                              ),
                              border:
                                  Border.all(
                                color: Colors.white
                                    .withValues(
                                  alpha: 0.12,
                                ),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize:
                                  MainAxisSize.min,
                              children: <Widget>[
                                Icon(
                                  Icons
                                      .agriculture_rounded,
                                  color:
                                      Colors.white,
                                  size: 17,
                                ),
                                SizedBox(
                                  width: 7,
                                ),
                                Text(
                                  'AgriAI Reels',
                                  style:
                                      TextStyle(
                                    color:
                                        Colors.white,
                                    fontSize:
                                        14,
                                    fontWeight:
                                        FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Material(
                            color:
                                Colors.black.withValues(
                              alpha: 0.30,
                            ),
                            shape:
                                const CircleBorder(),
                            child: IconButton(
                              tooltip:
                                  'Create Reel',
                              onPressed:
                                  _uploading
                                      ? null
                                      : _createReel,
                              color:
                                  Colors.white,
                              icon:
                                  _uploading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth:
                                                2,
                                            color:
                                                Colors.white,
                                          ),
                                        )
                                      : const Icon(
                                          Icons
                                              .add_rounded,
                                        ),
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

// ============================================================================
// REEL PAGE
// ============================================================================

class _ReelPage extends StatefulWidget {
  final _Reel reel;
  final bool isActive;
  final Future<void> Function() onChanged;

  const _ReelPage({
    super.key,
    required this.reel,
    required this.isActive,
    required this.onChanged,
  });

  @override
  State<_ReelPage> createState() =>
      _ReelPageState();
}

class _ReelPageState
    extends State<_ReelPage>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;

  bool _failed = false;
  bool _liked = false;
  bool _saved = false;
  bool _muted = true;
  bool _likeBusy = false;
  bool _saveBusy = false;
  bool _shareBusy = false;
  bool _followBusy = false;
  bool _followed = false;
  bool _showPlayIcon = false;
  bool _showHeartAnimation = false;
  bool _captionExpanded = false;
  bool _viewRegistered = false;

  int _likes = 0;
  int _comments = 0;
  int _shares = 0;
  int _views = 0;

  Timer? _hidePlayIconTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _likes = widget.reel.likesCount;
    _comments = widget.reel.commentsCount;
    _shares = widget.reel.sharesCount;
    _views = widget.reel.viewsCount;

    unawaited(_initialize());
    unawaited(_loadInteractionState());
  }

  @override
  void didUpdateWidget(
    covariant _ReelPage oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isActive !=
        widget.isActive) {
      if (widget.isActive) {
        unawaited(_activate());
      } else {
        unawaited(_deactivate());
      }
    }
  }

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state == AppLifecycleState.resumed &&
        widget.isActive) {
      unawaited(_activate());
    } else if (state !=
        AppLifecycleState.resumed) {
      unawaited(_deactivate());
    }
  }

  Future<void> _initialize() async {
    try {
      final VideoPlayerController controller =
          VideoPlayerController.networkUrl(
        Uri.parse(widget.reel.url),
      );

      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);

      if (!mounted) {
        await controller.dispose();
        return;
      }

      _controller = controller;


      if (widget.isActive) {
        await _activate();

        if (!_viewRegistered) {
          _viewRegistered = true;
          unawaited(_registerView());
        }
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _failed = true;
      });    }
  }

  Future<void> _activate() async {
    final VideoPlayerController? controller =
        _controller;

    if (controller == null ||
        !controller.value.isInitialized ||
        !widget.isActive) {
      return;
    }

    await controller.play();
  }

  Future<void> _deactivate() async {
    final VideoPlayerController? controller =
        _controller;

    if (controller == null ||
        !controller.value.isInitialized) {
      return;
    }

    await controller.pause();
  }

  Future<void> _registerView() async {
    if (widget.reel.id.isEmpty) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('farmerVideos')
          .doc(widget.reel.id)
          .update(
        <String, dynamic>{
          'viewsCount':
              FieldValue.increment(1),
        },
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _views++;
      });
    } catch (_) {
      // A view counter must never stop playback.
    }
  }

  Future<void> _loadInteractionState() async {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null ||
        widget.reel.id.isEmpty) {
      return;
    }

    try {
      final DocumentReference<
          Map<String, dynamic>> reelRef =
          FirebaseFirestore.instance
              .collection('farmerVideos')
              .doc(widget.reel.id);

      final List<DocumentSnapshot<
          Map<String, dynamic>>> snapshots =
          await Future.wait(
        <Future<DocumentSnapshot<
            Map<String, dynamic>>>>[
          reelRef
              .collection('likes')
              .doc(user.uid)
              .get(),
          FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('savedReels')
              .doc(widget.reel.id)
              .get(),
          FirebaseFirestore.instance
              .collection('connections')
              .where(
                'user1Uid',
                isEqualTo: user.uid,
              )
              .where(
                'user2Uid',
                isEqualTo: widget.reel.authorUid,
              )
              .limit(1)
              .get()
              .then(
                (QuerySnapshot<
                    Map<String, dynamic>> snapshot) {
                  if (snapshot.docs.isEmpty) {
                    return FirebaseFirestore
                        .instance
                        .collection('connections')
                        .doc('__none__')
                        .get();
                  }
                  return snapshot.docs.first;
                },
              ),
        ],
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _liked = snapshots[0].exists;
        _saved = snapshots[1].exists;
        _followed = snapshots[2].exists;
      });
    } catch (_) {
      // Interaction state is optional and can fail without breaking Reels.
    }
  }

  Future<void> _toggleLike() async {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null ||
        _likeBusy ||
        widget.reel.id.isEmpty) {
      return;
    }

    setState(() {
      _likeBusy = true;
    });

    try {
      final DocumentReference<
          Map<String, dynamic>> reelRef =
          FirebaseFirestore.instance
              .collection('farmerVideos')
              .doc(widget.reel.id);

      final DocumentReference<
          Map<String, dynamic>> likeRef =
          reelRef
              .collection('likes')
              .doc(user.uid);

      final DocumentSnapshot<
          Map<String, dynamic>> snapshot =
          await likeRef.get();

      if (snapshot.exists) {
        await likeRef.delete();

        await reelRef.set(
          <String, dynamic>{
            'likesCount':
                FieldValue.increment(-1),
          },
          SetOptions(merge: true),
        );

        if (mounted) {
          setState(() {
            _liked = false;
            if (_likes > 0) {
              _likes--;
            }
          });
        }
      } else {
        await likeRef.set(
          <String, dynamic>{
            'uid': user.uid,
            'createdAt':
                FieldValue.serverTimestamp(),
          },
        );

        await reelRef.set(
          <String, dynamic>{
            'likesCount':
                FieldValue.increment(1),
          },
          SetOptions(merge: true),
        );

        if (mounted) {
          setState(() {
            _liked = true;
            _likes++;
          });
        }
      }
    } catch (error) {
      if (mounted) {
        _showMessage(
          'Unable to update Like: $error',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _likeBusy = false;
        });
      }
    }
  }

  Future<void> _toggleSaved() async {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null ||
        _saveBusy ||
        widget.reel.id.isEmpty) {
      return;
    }

    setState(() {
      _saveBusy = true;
    });

    try {
      final DocumentReference<
          Map<String, dynamic>> savedRef =
          FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('savedReels')
              .doc(widget.reel.id);

      final DocumentSnapshot<
          Map<String, dynamic>> snapshot =
          await savedRef.get();

      if (snapshot.exists) {
        await savedRef.delete();

        if (mounted) {
          setState(() {
            _saved = false;
          });
          _showMessage('Removed from Saved.');
        }
      } else {
        await savedRef.set(
          <String, dynamic>{
            'reelId':
                widget.reel.id,
            'authorUid':
                widget.reel.authorUid,
            'author':
                widget.reel.author,
            'userId':
                widget.reel.userId,
            'title':
                widget.reel.title,
            'mediaUrl':
                widget.reel.url,
            'savedAt':
                FieldValue.serverTimestamp(),
          },
        );

        if (mounted) {
          setState(() {
            _saved = true;
          });
          _showMessage('Reel saved.');
        }
      }
    } catch (error) {
      if (mounted) {
        _showMessage(
          'Unable to save Reel: $error',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saveBusy = false;
        });
      }
    }
  }

  Future<void> _toggleFollow() async {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null ||
        _followBusy ||
        widget.reel.authorUid.isEmpty ||
        widget.reel.authorUid == user.uid) {
      return;
    }

    setState(() {
      _followBusy = true;
    });

    try {
      final String first =
          user.uid;
      final String second =
          widget.reel.authorUid;

      final QuerySnapshot<
          Map<String, dynamic>> existingConnection =
          await FirebaseFirestore.instance
              .collection('connections')
              .where(
                'user1Uid',
                isEqualTo: first,
              )
              .where(
                'user2Uid',
                isEqualTo: second,
              )
              .limit(1)
              .get();

      final QuerySnapshot<
          Map<String, dynamic>> reverseConnection =
          await FirebaseFirestore.instance
              .collection('connections')
              .where(
                'user1Uid',
                isEqualTo: second,
              )
              .where(
                'user2Uid',
                isEqualTo: first,
              )
              .limit(1)
              .get();

      if (existingConnection.docs.isNotEmpty ||
          reverseConnection.docs.isNotEmpty) {
        if (mounted) {
          setState(() {
            _followed = true;
          });
          _showMessage(
            'You are already connected with @${widget.reel.userId.isEmpty ? widget.reel.author : widget.reel.userId}.',
          );
        }
        return;
      }

      final QuerySnapshot<
          Map<String, dynamic>> outgoing =
          await FirebaseFirestore.instance
              .collection('connectionRequests')
              .where(
                'fromUid',
                isEqualTo: user.uid,
              )
              .where(
                'toUid',
                isEqualTo: widget.reel.authorUid,
              )
              .where(
                'status',
                isEqualTo: 'pending',
              )
              .limit(1)
              .get();

      if (outgoing.docs.isEmpty) {
        await FirebaseFirestore.instance
            .collection('connectionRequests')
            .add(
          <String, dynamic>{
            'fromUid':
                user.uid,
            'toUid':
                widget.reel.authorUid,
            'status':
                'pending',
            'createdAt':
                FieldValue.serverTimestamp(),
          },
        );
      }

      if (mounted) {
        setState(() {
          _followed = true;
        });

        _showMessage(
          'Connection request sent.',
        );
      }
    } catch (error) {
      if (mounted) {
        _showMessage(
          'Unable to connect: $error',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _followBusy = false;
        });
      }
    }
  }

  Future<void> _share() async {
    if (_shareBusy ||
        widget.reel.id.isEmpty) {
      return;
    }

    setState(() {
      _shareBusy = true;
    });

    try {
      await _showShareSheet();
    } finally {
      if (mounted) {
        setState(() {
          _shareBusy = false;
        });
      }
    }
  }

  Future<void> _showShareSheet() async {
    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (
        BuildContext sheetContext,
      ) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(
              18,
              4,
              18,
              22,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: <Widget>[
                const Align(
                  alignment:
                      Alignment.centerLeft,
                  child: Text(
                    'Share this Reel',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 14,
                ),
                _ShareOption(
                  icon:
                      Icons.people_alt_outlined,
                  title:
                      'Send to a farmer',
                  subtitle:
                      'Share inside AgriAI through DM',
                  onTap: () {
                    Navigator.of(
                      sheetContext,
                    ).pop();
                    unawaited(
                      _shareToFarmer(),
                    );
                  },
                ),
                const SizedBox(
                  height: 9,
                ),
                _ShareOption(
                  icon:
                      Icons.ios_share_rounded,
                  title:
                      'Share outside AgriAI',
                  subtitle:
                      'Use WhatsApp, Telegram, SMS and other apps',
                  onTap: () {
                    Navigator.of(
                      sheetContext,
                    ).pop();
                    unawaited(
                      _shareOutside(),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _shareOutside() async {
    final StringBuffer text =
        StringBuffer();

    text.writeln(
      'AgriAI Farming Reel',
    );
    text.writeln(
      'By ${widget.reel.userId.isEmpty ? widget.reel.author : '@${widget.reel.userId}'}',
    );
    text.writeln();
    text.writeln(
      widget.reel.title,
    );
    text.writeln();
    text.writeln(
      widget.reel.url,
    );
    text.writeln();
    text.writeln(
      'Shared from AgriAI',
    );

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: text.toString(),
          subject:
              'AgriAI Farming Reel',
          title:
              'Share AgriAI Reel',
        ),
      );

      await _incrementShares();
    } catch (error) {
      if (mounted) {
        _showMessage(
          'Unable to share Reel: $error',
        );
      }
    }
  }

  Future<void> _shareToFarmer() async {
    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (
        BuildContext sheetContext,
      ) {
        return _ReelFarmerShareSheet(
          reel: widget.reel,
          onShared: () async {
            await _incrementShares();
          },
        );
      },
    );
  }

  Future<void> _incrementShares() async {
    if (widget.reel.id.isEmpty) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('farmerVideos')
          .doc(widget.reel.id)
          .set(
        <String, dynamic>{
          'sharesCount':
              FieldValue.increment(1),
        },
        SetOptions(merge: true),
      );

      if (mounted) {
        setState(() {
          _shares++;
        });
      }
    } catch (_) {
      // Share itself succeeded; counter is secondary.
    }
  }

  Future<void> _showComments() async {
    if (!mounted ||
        widget.reel.id.isEmpty) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (
        BuildContext sheetContext,
      ) {
        return _ReelCommentsSheet(
          reel: widget.reel,
        );
      },
    );

    if (!mounted) {
      return;
    }

    await _refreshCommentCount();
  }

  Future<void> _refreshCommentCount() async {
    try {
      final DocumentSnapshot<
          Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('farmerVideos')
              .doc(widget.reel.id)
              .get();

      final int count =
          _readInt(
        snapshot.data()?['commentsCount'],
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _comments = count;
      });
    } catch (_) {}
  }

  Future<void> _showMore() async {
    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (
        BuildContext sheetContext,
      ) {
        return SafeArea(
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(
                  Icons.not_interested_rounded,
                ),
                title: const Text(
                  'Not interested',
                ),
                subtitle: const Text(
                  'Show fewer Reels like this',
                ),
                onTap: () {
                  Navigator.of(
                    sheetContext,
                  ).pop();
                  _showMessage(
                    'We will reduce similar recommendations.',
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.report_outlined,
                ),
                title:
                    const Text('Report Reel'),
                subtitle: const Text(
                  'Report inappropriate or harmful content',
                ),
                onTap: () {
                  Navigator.of(
                    sheetContext,
                  ).pop();
                  _showMessage(
                    'Report submitted.',
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.link_rounded,
                ),
                title:
                    const Text('Copy Reel link'),
                onTap: () {
                  Navigator.of(
                    sheetContext,
                  ).pop();
                  _showMessage(
                    'Reel link copied.',
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _togglePlayback() async {
    final VideoPlayerController? controller =
        _controller;

    if (controller == null ||
        !controller.value.isInitialized) {
      return;
    }

    if (controller.value.isPlaying) {
      await controller.pause();
    } else if (widget.isActive) {
      await controller.play();
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _showPlayIcon =
          !controller.value.isPlaying;
    });

    _hidePlayIconTimer?.cancel();
    _hidePlayIconTimer = Timer(
      const Duration(milliseconds: 900),
      () {
        if (!mounted) {
          return;
        }

        setState(() {
          _showPlayIcon = false;
        });
      },
    );
  }

  Future<void> _toggleMute() async {
    final VideoPlayerController? controller =
        _controller;

    if (controller == null ||
        !controller.value.isInitialized) {
      return;
    }

    final bool newMuted = !_muted;

    await controller.setVolume(
      newMuted ? 0 : 1,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _muted = newMuted;
    });
  }

  void _doubleTapLike() {
    if (!_liked) {
      unawaited(_toggleLike());
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _showPlayIcon = false;
      _showHeartAnimation = true;
    });

    Timer(
      const Duration(milliseconds: 720),
      () {
        if (!mounted) {
          return;
        }

        setState(() {
          _showHeartAnimation = false;
        });
      },
    );
  }

  void _toggleCaption() {
    if (!mounted) {
      return;
    }

    setState(() {
      _captionExpanded = !_captionExpanded;
    });
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
  }

  String _formatCount(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(value >= 10000000 ? 0 : 1)}M';
    }

    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1)}K';
    }

    return value.toString();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final VideoPlayerController? controller =
        _controller;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Container(
          color: Colors.black,
        ),
        if (controller != null &&
            controller.value.isInitialized)
          GestureDetector(
            onTap: _togglePlayback,
            onDoubleTap: _doubleTapLike,
            behavior:
                HitTestBehavior.opaque,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width:
                    controller.value.size.width,
                height:
                    controller.value.size.height,
                child:
                    VideoPlayer(controller),
              ),
            ),
          )
        else
          Center(
            child: _failed
                ? const Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons
                            .video_library_outlined,
                        color:
                            Colors.white70,
                        size: 48,
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Text(
                        'Unable to load this Reel',
                        style:
                            TextStyle(
                          color:
                              Colors.white,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ],
                  )
                : const CircularProgressIndicator(
                    color: Colors.white,
                  ),
          ),

        if (_showPlayIcon)
          Center(
            child: Container(
              width: 66,
              height: 66,
              decoration:
                  const BoxDecoration(
                color: Colors.black54,
                shape:
                    BoxShape.circle,
              ),
              child: Icon(
                controller != null &&
                        controller.value.isPlaying
                    ? Icons
                        .pause_rounded
                    : Icons
                        .play_arrow_rounded,
                color:
                    Colors.white,
                size: 39,
              ),
            ),
          ),

        if (_showHeartAnimation)
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: 0.55,
                end: 1.18,
              ),
              duration:
                  const Duration(milliseconds: 360),
              curve: Curves.elasticOut,
              builder: (
                BuildContext context,
                double scale,
                Widget? child,
              ) {
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: const Icon(
                Icons.favorite_rounded,
                color: Colors.white,
                size: 112,
                shadows: <Shadow>[
                  Shadow(
                    color: Colors.black54,
                    blurRadius: 18,
                  ),
                ],
              ),
            ),
          ),

        // Bottom readability gradient.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 300,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration:
                  BoxDecoration(
                gradient:
                    LinearGradient(
                  begin:
                      Alignment.topCenter,
                  end:
                      Alignment.bottomCenter,
                  colors:
                      <Color>[
                    Colors.transparent,
                    Colors.black.withValues(
                      alpha: 0.08,
                    ),
                    Colors.black.withValues(
                      alpha: 0.78,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Right action rail.
        Positioned(
          right: 10,
          bottom: 112,
          child: _ReelActionRail(
            liked: _liked,
            saved: _saved,
            likes:
                _formatCount(_likes),
            comments:
                _formatCount(_comments),
            shares:
                _formatCount(_shares),
            onLike:
                _toggleLike,
            onComment:
                _showComments,
            onShare:
                _share,
            onSave:
                _toggleSaved,
            onMore:
                _showMore,
          ),
        ),

        // Creator information.
        Positioned(
          left: 16,
          right: 76,
          bottom: 30,
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  _ReelAvatar(
                    photoUrl:
                        widget.reel.photoUrl,
                    name:
                        widget.reel.author,
                    size: 43,
                  ),
                  const SizedBox(
                    width: 9,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          widget.reel.author,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                            fontSize:
                                13,
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),
                        const SizedBox(
                          height: 2,
                        ),
                        Text(
                          widget.reel.userId.isEmpty
                              ? '@farmer'
                              : '@${widget.reel.userId}',
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              const TextStyle(
                            color:
                                Colors.white70,
                            fontSize:
                                8.5,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.reel.authorUid !=
                      FirebaseAuth.instance
                          .currentUser
                          ?.uid)
                    Padding(
                      padding:
                          const EdgeInsets.only(
                        left: 7,
                      ),
                      child:
                          _ConnectButton(
                        connected:
                            _followed,
                        busy:
                            _followBusy,
                        onTap:
                            _toggleFollow,
                      ),
                    ),
                ],
              ),
              const SizedBox(
                height: 11,
              ),
              GestureDetector(
                onTap: _toggleCaption,
                child: Text(
                  widget.reel.title,
                  maxLines:
                      _captionExpanded ? 8 : 3,
                  overflow:
                      _captionExpanded
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize:
                        13,
                    height:
                        1.38,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
              if (widget.reel.title.length > 95)
                GestureDetector(
                  onTap: _toggleCaption,
                  child: Padding(
                    padding:
                        const EdgeInsets.only(top: 3),
                    child: Text(
                      _captionExpanded
                          ? 'show less'
                          : 'more',
                      style:
                          const TextStyle(
                        color:
                            Colors.white70,
                        fontSize:
                            8.5,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              const SizedBox(
                height: 9,
              ),
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.music_note_rounded,
                    color:
                        Colors.white70,
                    size: 14,
                  ),
                  const SizedBox(
                    width: 4,
                  ),
                  Expanded(
                    child: Text(
                      'Original farming audio • ${_formatCount(_views)} views • ${_formatCount(_shares)} shares',
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        color:
                            Colors.white70,
                        fontSize:
                            8.5,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Mute control.
        Positioned(
          top:
              MediaQuery.of(context)
                      .padding
                      .top +
                  66,
          right: 14,
          child: Material(
            color:
                Colors.black.withValues(
              alpha: 0.30,
            ),
            shape:
                const CircleBorder(),
            child: InkWell(
              customBorder:
                  const CircleBorder(),
              onTap:
                  _toggleMute,
              child:
                  Padding(
                padding:
                    const EdgeInsets.all(
                  10,
                ),
                child:
                    Icon(
                  _muted
                      ? Icons
                          .volume_off_rounded
                      : Icons
                          .volume_up_rounded,
                  color:
                      Colors.white,
                  size:
                      19,
                ),
              ),
            ),
          ),
        ),

        // Progress bar.
        if (controller != null &&
            controller.value.isInitialized)
          Positioned(
            left: 10,
            right: 10,
            bottom: 4,
            child: ClipRRect(
              borderRadius:
                  BorderRadius.circular(
                5,
              ),
              child:
                  VideoProgressIndicator(
                controller,
                allowScrubbing:
                    true,
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 3,
                ),
                colors:
                    const VideoProgressColors(
                  playedColor:
                      Colors.white,
                  bufferedColor:
                      Colors.white38,
                  backgroundColor:
                      Colors.white24,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance
        .removeObserver(this);

    _hidePlayIconTimer?.cancel();

    final VideoPlayerController? controller =
        _controller;

    if (controller != null) {
      unawaited(
        controller.dispose(),
      );
    }

    super.dispose();
  }

  static int _readInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          '$value',
        ) ??
        0;
  }
}

// ============================================================================
// ACTION RAIL
// ============================================================================

class _ReelActionRail
    extends StatelessWidget {
  final bool liked;
  final bool saved;
  final String likes;
  final String comments;
  final String shares;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onSave;
  final VoidCallback onMore;

  const _ReelActionRail({
    required this.liked,
    required this.saved,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onSave,
    required this.onMore,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      children: <Widget>[
        _ReelAction(
          icon: liked
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          label: likes,
          active: liked,
          onTap: onLike,
        ),
        const SizedBox(
          height: 17,
        ),
        _ReelAction(
          icon:
              Icons.chat_bubble_outline_rounded,
          label: comments,
          onTap: onComment,
        ),
        const SizedBox(
          height: 17,
        ),
        _ReelAction(
          icon: Icons.send_rounded,
          label: shares,
          onTap: onShare,
        ),
        const SizedBox(
          height: 17,
        ),
        _ReelAction(
          icon: saved
              ? Icons.bookmark_rounded
              : Icons.bookmark_border_rounded,
          label: 'Save',
          active: saved,
          onTap: onSave,
        ),
        const SizedBox(
          height: 17,
        ),
        _ReelAction(
          icon: Icons.more_horiz_rounded,
          label: '',
          onTap: onMore,
        ),
      ],
    );
  }
}

class _ReelAction
    extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ReelAction({
    required this.icon,
    required this.label,
    this.active = false,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius:
            BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 2,
          ),
          child: Column(
            children: <Widget>[
              Container(
                width: 45,
                height: 45,
                decoration:
                    BoxDecoration(
                  color:
                      Colors.black.withValues(
                    alpha: 0.28,
                  ),
                  shape:
                      BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: active
                      ? Colors.redAccent
                      : Colors.white,
                  size: 25,
                ),
              ),
              if (label.isNotEmpty)
                Padding(
                  padding:
                      const EdgeInsets.only(
                    top: 3,
                  ),
                  child: Text(
                    label,
                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontSize:
                          8.5,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// CONNECT BUTTON
// ============================================================================

class _ConnectButton
    extends StatelessWidget {
  final bool connected;
  final bool busy;
  final VoidCallback onTap;

  const _ConnectButton({
    required this.connected,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(10),
      child: InkWell(
        onTap:
            connected || busy
                ? null
                : onTap,
        borderRadius:
            BorderRadius.circular(10),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          child: Row(
            mainAxisSize:
                MainAxisSize.min,
            children: <Widget>[
              if (busy)
                const SizedBox(
                  width: 11,
                  height: 11,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 1.8,
                  ),
                )
              else
                Icon(
                  connected
                      ? Icons.check_rounded
                      : Icons.person_add_alt_1_rounded,
                  size: 13,
                  color: AppColors.primary,
                ),
              const SizedBox(
                width: 4,
              ),
              Text(
                connected
                    ? 'Connected'
                    : 'Connect',
                style:
                    const TextStyle(
                  fontSize: 8,
                  fontWeight:
                      FontWeight.w900,
                  color:
                      AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SHARE TO FARMER
// ============================================================================

class _ReelFarmerShareSheet
    extends StatefulWidget {
  final _Reel reel;
  final Future<void> Function() onShared;

  const _ReelFarmerShareSheet({
    required this.reel,
    required this.onShared,
  });

  @override
  State<_ReelFarmerShareSheet> createState() =>
      _ReelFarmerShareSheetState();
}

class _ReelFarmerShareSheetState
    extends State<_ReelFarmerShareSheet> {
  final TextEditingController _searchController =
      TextEditingController();

  Timer? _debounce;
  List<_Farmer> _farmers =
      <_Farmer>[];
  bool _loading = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    unawaited(
      _searchFarmers(''),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(
    String value,
  ) {
    _query =
        value.trim().toLowerCase();

    _debounce?.cancel();
    _debounce = Timer(
      const Duration(
        milliseconds: 300,
      ),
      () => unawaited(
        _searchFarmers(_query),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _searchFarmers(
    String query,
  ) async {
    if (!mounted) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final User? currentUser =
          FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        throw FirebaseException(
          plugin: 'firebase_auth',
          code: 'not-authenticated',
        );
      }

      final CollectionReference<
          Map<String, dynamic>> users =
          FirebaseFirestore.instance
              .collection('users');

      final Query<Map<String, dynamic>>
          searchQuery =
          query.isEmpty
              ? users
                  .orderBy('userIdLower')
                  .limit(30)
              : users
                  .orderBy('userIdLower')
                  .startAt(
                    <String>[query],
                  )
                  .endAt(
                    <String>[
                      '$query\uf8ff',
                    ],
                  )
                  .limit(30);

      final QuerySnapshot<
          Map<String, dynamic>> snapshot =
          await searchQuery.get();

      final List<_Farmer> loaded =
          <_Farmer>[];

      for (final QueryDocumentSnapshot<
          Map<String, dynamic>> document
          in snapshot.docs) {
        final Map<String, dynamic> data =
            document.data();

        final String uid =
            '${data['uid'] ?? document.id}'
                .trim();

        if (uid.isEmpty ||
            uid == currentUser.uid) {
          continue;
        }

        final String userId =
            '${data['userId'] ?? ''}'
                .trim();

        if (userId.isEmpty) {
          continue;
        }

        final String lower =
            '${data['userIdLower'] ?? userId}'
                .trim()
                .toLowerCase();

        if (query.isNotEmpty &&
            !lower.startsWith(query)) {
          continue;
        }

        loaded.add(
          _Farmer(
            uid: uid,
            userId: userId,
            name:
                '${data['displayName'] ?? 'AgriAI Farmer'}'
                    .trim(),
            photoUrl:
                '${data['photoUrl'] ?? ''}'
                    .trim(),
          ),
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _farmers = loaded;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _farmers = <_Farmer>[];
        _loading = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content:
                Text('Search failed: $error'),
            behavior:
                SnackBarBehavior.floating,
          ),
        );
    }
  }

  Future<void> _sendToFarmer(
    _Farmer farmer,
  ) async {
    if (_loading) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final String conversationId =
          await DirectMessagesService
              .getOrCreateConversation(
        otherUid: farmer.uid,
      );

      await DirectMessagesService
          .sendReelMessage(
        conversationId:
            conversationId,
        receiverUid:
            farmer.uid,
        reelId:
            widget.reel.id,
        text:
            widget.reel.title,
        mediaUrl:
            widget.reel.url,
      );

      await widget.onShared();

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();

      ScaffoldMessenger.of(
        context,
      )
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Reel sent to @${farmer.userId}.',
            ),
            behavior:
                SnackBarBehavior.floating,
          ),
        );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content:
                Text('Unable to send Reel: $error'),
            behavior:
                SnackBarBehavior.floating,
          ),
        );
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return SafeArea(
      child: SizedBox(
        height:
            MediaQuery.sizeOf(context)
                    .height *
                0.72,
        child: Column(
          children: <Widget>[
            const Padding(
              padding:
                  EdgeInsets.fromLTRB(
                18,
                3,
                18,
                12,
              ),
              child: Align(
                alignment:
                    Alignment.centerLeft,
                child: Text(
                  'Send to a Farmer',
                  style:
                      TextStyle(
                    fontSize:
                        20,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 18,
              ),
              child: TextField(
                controller:
                    _searchController,
                onChanged:
                    _onSearchChanged,
                decoration:
                    InputDecoration(
                  hintText:
                      'Search @User ID…',
                  prefixIcon:
                      const Icon(
                    Icons.search_rounded,
                  ),
                  suffixIcon:
                      _query.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController
                                    .clear();
                                _onSearchChanged(
                                  '',
                                );
                              },
                              icon:
                                  const Icon(
                                Icons
                                    .close_rounded,
                              ),
                            ),
                  filled:
                      true,
                  fillColor:
                      AppColors
                          .background,
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                    borderSide:
                        BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Expanded(
              child: _loading &&
                      _farmers.isEmpty
                  ? const Center(
                      child:
                          CircularProgressIndicator(
                        strokeWidth:
                            2.2,
                      ),
                    )
                  : _farmers.isEmpty
                      ? Center(
                          child: Text(
                            _query.isEmpty
                                ? 'No farmers available.'
                                : 'No farmer found for “$_query”.',
                            textAlign:
                                TextAlign.center,
                            style:
                                const TextStyle(
                              color:
                                  AppColors
                                      .textSecondary,
                              fontSize:
                                  11,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(
                            18,
                            3,
                            18,
                            22,
                          ),
                          itemCount:
                              _farmers.length,
                          separatorBuilder:
                              (
                            BuildContext context,
                            int index,
                          ) =>
                                  const SizedBox(
                            height: 8,
                          ),
                          itemBuilder:
                              (
                            BuildContext context,
                            int index,
                          ) {
                            final _Farmer farmer =
                                _farmers[index];

                            return Material(
                              color:
                                  Colors.transparent,
                              child:
                                  InkWell(
                                onTap:
                                    _loading
                                        ? null
                                        : () =>
                                            _sendToFarmer(
                                          farmer,
                                        ),
                                borderRadius:
                                    BorderRadius.circular(
                                  16,
                                ),
                                child:
                                    Container(
                                  padding:
                                      const EdgeInsets.all(
                                    11,
                                  ),
                                  decoration:
                                      BoxDecoration(
                                    color:
                                        AppColors.surface,
                                    borderRadius:
                                        BorderRadius.circular(
                                      16,
                                    ),
                                    border:
                                        Border.all(
                                      color:
                                          AppColors.border,
                                    ),
                                  ),
                                  child:
                                      Row(
                                    children:
                                        <Widget>[
                                      _ReelAvatar(
                                        photoUrl:
                                            farmer.photoUrl,
                                        name:
                                            farmer.name,
                                        size:
                                            46,
                                      ),
                                      const SizedBox(
                                        width:
                                            11,
                                      ),
                                      Expanded(
                                        child:
                                            Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children:
                                              <Widget>[
                                            Text(
                                              farmer.name.isEmpty
                                                  ? 'AgriAI Farmer'
                                                  : farmer.name,
                                              maxLines:
                                                  1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style:
                                                  const TextStyle(
                                                fontSize:
                                                    12,
                                                fontWeight:
                                                    FontWeight.w900,
                                              ),
                                            ),
                                            const SizedBox(
                                              height:
                                                  2,
                                            ),
                                            Text(
                                              '@${farmer.userId}',
                                              style:
                                                  const TextStyle(
                                                fontSize:
                                                    9,
                                                color:
                                                    AppColors.primary,
                                                fontWeight:
                                                    FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                          horizontal:
                                              11,
                                          vertical:
                                              8,
                                        ),
                                        decoration:
                                            BoxDecoration(
                                          color:
                                              AppColors.primary,
                                          borderRadius:
                                              BorderRadius.circular(
                                            11,
                                          ),
                                        ),
                                        child:
                                            const Icon(
                                          Icons
                                              .send_rounded,
                                          color:
                                              Colors.white,
                                          size:
                                              15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Farmer {
  final String uid;
  final String userId;
  final String name;
  final String photoUrl;

  const _Farmer({
    required this.uid,
    required this.userId,
    required this.name,
    required this.photoUrl,
  });
}

// ============================================================================
// COMMENTS
// ============================================================================

class _ReelCommentsSheet
    extends StatefulWidget {
  final _Reel reel;

  const _ReelCommentsSheet({
    required this.reel,
  });

  @override
  State<_ReelCommentsSheet> createState() =>
      _ReelCommentsSheetState();
}

class _ReelCommentsSheetState
    extends State<_ReelCommentsSheet> {
  final TextEditingController _controller =
      TextEditingController();

  List<_ReelComment> _comments =
      <_ReelComment>[];

  bool _loading = true;
  bool _posting = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadComments());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    try {
      final QuerySnapshot<
          Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('farmerVideos')
              .doc(widget.reel.id)
              .collection('comments')
              .orderBy(
                'createdAt',
                descending: true,
              )
              .limit(100)
              .get();

      final List<_ReelComment> comments =
          snapshot.docs
              .map(
                (
                  QueryDocumentSnapshot<
                      Map<String, dynamic>> document,
                ) =>
                    _ReelComment.fromDocument(
                  document,
                ),
              )
              .toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _comments = comments;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content:
                Text('Unable to load comments: $error'),
            behavior:
                SnackBarBehavior.floating,
          ),
        );
    }
  }

  Future<void> _postComment() async {
    final User? user =
        FirebaseAuth.instance.currentUser;

    final String text =
        _controller.text.trim();

    if (user == null ||
        text.isEmpty ||
        _posting ||
        widget.reel.id.isEmpty) {
      return;
    }

    setState(() {
      _posting = true;
    });

    try {
      final DocumentSnapshot<
          Map<String, dynamic>> userSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      final Map<String, dynamic> userData =
          userSnapshot.data() ??
              <String, dynamic>{};

      final String displayName =
          '${userData['displayName'] ?? user.displayName ?? 'AgriAI Farmer'}'
              .trim();

      final String userId =
          '${userData['userId'] ?? ''}'
              .trim();

      await FirebaseFirestore.instance
          .collection('farmerVideos')
          .doc(widget.reel.id)
          .collection('comments')
          .add(
        <String, dynamic>{
          'uid':
              user.uid,
          'userId':
              userId,
          'displayName':
              displayName.isEmpty
                  ? 'AgriAI Farmer'
                  : displayName,
          'photoUrl':
              '${userData['photoUrl'] ?? ''}'
                  .trim(),
          'text':
              text,
          'createdAt':
              FieldValue.serverTimestamp(),
        },
      );

      await FirebaseFirestore.instance
          .collection('farmerVideos')
          .doc(widget.reel.id)
          .set(
        <String, dynamic>{
          'commentsCount':
              FieldValue.increment(1),
        },
        SetOptions(merge: true),
      );

      _controller.clear();

      await _loadComments();

      if (!mounted) {
        return;
      }

      setState(() {
        _posting = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _posting = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content:
                Text('Unable to post comment: $error'),
            behavior:
                SnackBarBehavior.floating,
          ),
        );
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return SafeArea(
      child: SizedBox(
        height:
            MediaQuery.sizeOf(context)
                    .height *
                0.70,
        child: Column(
          children: <Widget>[
            const Padding(
              padding:
                  EdgeInsets.fromLTRB(
                18,
                3,
                18,
                12,
              ),
              child: Align(
                alignment:
                    Alignment.centerLeft,
                child: Text(
                  'Comments',
                  style:
                      TextStyle(
                    fontSize:
                        20,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child:
                          CircularProgressIndicator(
                        strokeWidth:
                            2.2,
                      ),
                    )
                  : _comments.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize:
                                MainAxisSize.min,
                            children:
                                <Widget>[
                              Icon(
                                Icons
                                    .chat_bubble_outline_rounded,
                                size:
                                    40,
                                color:
                                    AppColors.primary,
                              ),
                              SizedBox(
                                height:
                                    8,
                              ),
                              Text(
                                'No comments yet',
                                style:
                                    TextStyle(
                                  fontWeight:
                                      FontWeight.w800,
                                ),
                              ),
                              SizedBox(
                                height:
                                    4,
                              ),
                              Text(
                                'Start the farming conversation.',
                                style:
                                    TextStyle(
                                  fontSize:
                                      10,
                                  color:
                                      AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(
                            18,
                            0,
                            18,
                            12,
                          ),
                          itemCount:
                              _comments.length,
                          separatorBuilder:
                              (
                            BuildContext context,
                            int index,
                          ) =>
                                  const SizedBox(
                            height: 10,
                          ),
                          itemBuilder:
                              (
                            BuildContext context,
                            int index,
                          ) {
                            final _ReelComment comment =
                                _comments[index];

                            return Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children:
                                  <Widget>[
                                _ReelAvatar(
                                  photoUrl:
                                      comment.photoUrl,
                                  name:
                                      comment.displayName,
                                  size:
                                      39,
                                ),
                                const SizedBox(
                                  width:
                                      9,
                                ),
                                Expanded(
                                  child:
                                      Container(
                                    padding:
                                        const EdgeInsets.fromLTRB(
                                      11,
                                      9,
                                      11,
                                      10,
                                    ),
                                    decoration:
                                        BoxDecoration(
                                      color:
                                          AppColors.background,
                                      borderRadius:
                                          BorderRadius.circular(
                                        14,
                                      ),
                                    ),
                                    child:
                                        Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children:
                                          <Widget>[
                                        Row(
                                          children:
                                              <Widget>[
                                            Expanded(
                                              child:
                                                  Text(
                                                comment.displayName,
                                                maxLines:
                                                    1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style:
                                                    const TextStyle(
                                                  fontSize:
                                                      10.5,
                                                  fontWeight:
                                                      FontWeight.w900,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              _formatCommentDate(
                                                comment.createdAt,
                                              ),
                                              style:
                                                  const TextStyle(
                                                fontSize:
                                                    7.5,
                                                color:
                                                    AppColors.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (comment.userId.isNotEmpty)
                                          Text(
                                            '@${comment.userId}',
                                            style:
                                                const TextStyle(
                                              fontSize:
                                                  7.5,
                                              color:
                                                  AppColors.primary,
                                              fontWeight:
                                                  FontWeight.w700,
                                            ),
                                          ),
                                        const SizedBox(
                                          height:
                                              4,
                                        ),
                                        Text(
                                          comment.text,
                                          style:
                                              const TextStyle(
                                            fontSize:
                                                10,
                                            height:
                                                1.35,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
            ),
            Padding(
              padding:
                  EdgeInsets.fromLTRB(
                12,
                7,
                12,
                MediaQuery.of(context)
                        .viewInsets
                        .bottom +
                    10,
              ),
              child:
                  Row(
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children:
                    <Widget>[
                  Expanded(
                    child:
                        TextField(
                      controller:
                          _controller,
                      minLines:
                          1,
                      maxLines:
                          3,
                      textInputAction:
                          TextInputAction.send,
                      onSubmitted:
                          (_) =>
                              _postComment(),
                      decoration:
                          InputDecoration(
                        hintText:
                            'Add a farming comment…',
                        filled:
                            true,
                        fillColor:
                            AppColors
                                .background,
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                            18,
                          ),
                          borderSide:
                              BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width:
                        7,
                  ),
                  Material(
                    color:
                        AppColors.primary,
                    shape:
                        const CircleBorder(),
                    child:
                        InkWell(
                      customBorder:
                          const CircleBorder(),
                      onTap:
                          _posting
                              ? null
                              : _postComment,
                      child:
                          Padding(
                        padding:
                            const EdgeInsets.all(
                          12,
                        ),
                        child:
                            _posting
                                ? const SizedBox(
                                    width:
                                        19,
                                    height:
                                        19,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth:
                                          2,
                                      color:
                                          Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons
                                        .arrow_upward_rounded,
                                    color:
                                        Colors.white,
                                    size:
                                        19,
                                  ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCommentDate(
    DateTime? date,
  ) {
    if (date == null) {
      return 'now';
    }

    final Duration difference =
        DateTime.now().difference(date);

    if (difference.inMinutes < 1) {
      return 'now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h';
    }

    return '${date.day}/${date.month}';
  }
}

class _ReelComment {
  final String id;
  final String uid;
  final String userId;
  final String displayName;
  final String photoUrl;
  final String text;
  final DateTime? createdAt;

  const _ReelComment({
    required this.id,
    required this.uid,
    required this.userId,
    required this.displayName,
    required this.photoUrl,
    required this.text,
    required this.createdAt,
  });

  factory _ReelComment.fromDocument(
    DocumentSnapshot<Map<String, dynamic>>
        document,
  ) {
    final Map<String, dynamic> data =
        document.data() ??
            <String, dynamic>{};

    final dynamic timestamp =
        data['createdAt'];

    return _ReelComment(
      id: document.id,
      uid:
          '${data['uid'] ?? ''}',
      userId:
          '${data['userId'] ?? ''}',
      displayName:
          '${data['displayName'] ?? 'AgriAI Farmer'}',
      photoUrl:
          '${data['photoUrl'] ?? ''}',
      text:
          '${data['text'] ?? ''}',
      createdAt:
          timestamp is Timestamp
              ? timestamp.toDate()
              : null,
    );
  }
}

// ============================================================================
// REEL MODEL
// ============================================================================

class _Reel {
  final String id;
  final String url;
  final String title;
  final String authorUid;
  final String author;
  final String userId;
  final String photoUrl;
  final DateTime createdAt;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final int viewsCount;

  double get recommendationScore {
    final double engagement =
        (likesCount * 4.0) +
        (commentsCount * 6.0) +
        (sharesCount * 7.0) +
        (viewsCount * 0.35);

    final double ageHours =
        DateTime.now().difference(createdAt).inMinutes / 60.0;

    final double freshness =
        ageHours <= 0
            ? 24.0
            : (24.0 / (1.0 + ageHours / 12.0));

    return engagement + freshness;
  }

  const _Reel({
    required this.id,
    required this.url,
    required this.title,
    required this.authorUid,
    required this.author,
    required this.userId,
    required this.photoUrl,
    required this.createdAt,
    required this.likesCount,
    required this.commentsCount,
    required this.sharesCount,
    required this.viewsCount,
  });

  factory _Reel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>>
        document,
  ) {
    final Map<String, dynamic> data =
        document.data() ??
            <String, dynamic>{};

    final dynamic created =
        data['createdAt'];

    final DateTime createdAt =
        created is Timestamp
            ? created.toDate()
            : DateTime.tryParse(
                  '${created ?? ''}',
                ) ??
                DateTime.fromMillisecondsSinceEpoch(
                  0,
                );

    return _Reel(
      id: document.id,
      url:
          '${data['cloudinaryUrl'] ?? ''}'
              .trim(),
      title:
          '${data['title'] ?? 'Farming Reel'}'
              .trim(),
      authorUid:
          '${data['authorId'] ?? ''}'
              .trim(),
      author:
          '${data['author'] ?? 'AgriAI Farmer'}'
              .trim(),
      userId:
          '${data['userId'] ?? ''}'
              .trim(),
      photoUrl:
          '${data['photoUrl'] ?? ''}'
              .trim(),
      createdAt:
          createdAt,
      likesCount:
          _readInt(
        data['likesCount'],
      ),
      commentsCount:
          _readInt(
        data['commentsCount'],
      ),
      sharesCount:
          _readInt(
        data['sharesCount'],
      ),
      viewsCount:
          _readInt(
        data['viewsCount'],
      ),
    );
  }

  static int _readInt(
    dynamic value,
  ) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          '$value',
        ) ??
        0;
  }
}

// ============================================================================
// AVATAR
// ============================================================================

class _ReelAvatar
    extends StatelessWidget {
  final String photoUrl;
  final String name;
  final double size;

  const _ReelAvatar({
    required this.photoUrl,
    required this.name,
    required this.size,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final String initial =
        name.trim().isEmpty
            ? 'A'
            : name.trim()[0]
                .toUpperCase();

    return Container(
      width:
          size,
      height:
          size,
      decoration:
          BoxDecoration(
        shape:
            BoxShape.circle,
        color:
            AppColors.cardGreen,
        border:
            Border.all(
          color:
              Colors.white.withValues(
            alpha: 0.65,
          ),
          width:
              1.5,
        ),
      ),
      child:
          ClipOval(
        child:
            photoUrl.isNotEmpty
                ? Image.network(
                    photoUrl,
                    fit:
                        BoxFit.cover,
                    errorBuilder:
                        (
                      BuildContext context,
                      Object error,
                      StackTrace? stackTrace,
                    ) =>
                            _initial(
                      initial,
                    ),
                  )
                : _initial(
                    initial,
                  ),
      ),
    );
  }

  Widget _initial(
    String initial,
  ) {
    return Center(
      child:
          Text(
        initial,
        style:
            TextStyle(
          color:
              AppColors.primary,
          fontWeight:
              FontWeight.w900,
          fontSize:
              size * 0.34,
        ),
      ),
    );
  }
}

// ============================================================================
// SHARE OPTION
// ============================================================================

class _ShareOption
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color:
          Colors.transparent,
      child:
          InkWell(
        onTap:
            onTap,
        borderRadius:
            BorderRadius.circular(
          17,
        ),
        child:
            Container(
          padding:
              const EdgeInsets.all(
            13,
          ),
          decoration:
              BoxDecoration(
            color:
                AppColors.surface,
            borderRadius:
                BorderRadius.circular(
              17,
            ),
            border:
                Border.all(
              color:
                  AppColors.border,
            ),
          ),
          child:
              Row(
            children:
                <Widget>[
              Container(
                width:
                    45,
                height:
                    45,
                decoration:
                    const BoxDecoration(
                  color:
                      AppColors.cardGreen,
                  shape:
                      BoxShape.circle,
                ),
                child:
                    Icon(
                  icon,
                  color:
                      AppColors.primary,
                  size:
                      22,
                ),
              ),
              const SizedBox(
                width:
                    11,
              ),
              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children:
                      <Widget>[
                    Text(
                      title,
                      style:
                          const TextStyle(
                        fontSize:
                            12,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    const SizedBox(
                      height:
                          3,
                    ),
                    Text(
                      subtitle,
                      style:
                          const TextStyle(
                        fontSize:
                            9,
                        color:
                            AppColors
                                .textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons
                    .chevron_right_rounded,
                color:
                    AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// EMPTY REELS
// ============================================================================

class _EmptyReels
    extends StatelessWidget {
  final Future<void> Function()
      onRefresh;
  final Future<void> Function()
      onCreate;

  const _EmptyReels({
    required this.onRefresh,
    required this.onCreate,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Center(
      child:
          Padding(
        padding:
            const EdgeInsets.all(
          28,
        ),
        child:
            Column(
          mainAxisSize:
              MainAxisSize.min,
          children:
              <Widget>[
            Container(
              width:
                  92,
              height:
                  92,
              decoration:
                  BoxDecoration(
                color:
                    AppColors.primary
                        .withValues(
                  alpha:
                      0.18,
                ),
                shape:
                    BoxShape.circle,
              ),
              child:
                  const Icon(
                Icons
                    .play_circle_fill_rounded,
                color:
                    AppColors.primary,
                size:
                    49,
              ),
            ),
            const SizedBox(
              height:
                  18,
            ),
            const Text(
              'No farming Reels yet',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                color:
                    Colors.white,
                fontSize:
                    21,
                fontWeight:
                    FontWeight.w900,
              ),
            ),
            const SizedBox(
              height:
                  8,
            ),
            const Text(
              'Be the first farmer to share a crop update, farming tip or field moment.',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                color:
                    Colors.white70,
                fontSize:
                    11,
                height:
                    1.5,
              ),
            ),
            const SizedBox(
              height:
                  18,
            ),
            Row(
              mainAxisSize:
                  MainAxisSize.min,
              children:
                  <Widget>[
                FilledButton.icon(
                  onPressed:
                      () =>
                          unawaited(
                    onCreate(),
                  ),
                  icon:
                      const Icon(
                    Icons
                        .add_rounded,
                  ),
                  label:
                      const Text(
                    'Create Reel',
                  ),
                ),
                const SizedBox(
                  width:
                      9,
                ),
                OutlinedButton(
                  onPressed:
                      () =>
                          unawaited(
                    onRefresh(),
                  ),
                  style:
                      OutlinedButton.styleFrom(
                    foregroundColor:
                        Colors.white,
                    side:
                        const BorderSide(
                      color:
                          Colors.white54,
                    ),
                  ),
                  child:
                      const Text(
                    'Refresh',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
