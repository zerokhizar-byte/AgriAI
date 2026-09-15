import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../services/cloudinary_media_service.dart';
import '../../services/community_posts_service.dart';
import '../../services/community_comments_service.dart';
import '../../services/community_saved_posts_service.dart';
import '../../services/community_share_service.dart';
import '../../services/direct_messages_service.dart';
import '../direct_messages/direct_messages_screen.dart';

class HomeScreen extends StatefulWidget {
  final String? farmerName;

  final VoidCallback? onYieldPrediction;
  final VoidCallback? onDiseaseDetection;
  final VoidCallback? onSoilAnalysis;
  final VoidCallback? onWeather;
  final VoidCallback? onRecommendations;
  final VoidCallback? onProfile;
  final VoidCallback? onCropHistory;

  /// Opens the farmer/user search screen.
  final VoidCallback? onSearch;

  const HomeScreen({
    super.key,
    this.farmerName,
    this.onYieldPrediction,
    this.onDiseaseDetection,
    this.onSoilAnalysis,
    this.onWeather,
    this.onRecommendations,
    this.onProfile,
    this.onCropHistory,
    this.onSearch,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _clockTimer;

  DateTime _now = DateTime.now();

  // ---------------------------------------------------------------------------
  // WEATHER
  // ---------------------------------------------------------------------------

  WeatherSnapshot? _weather;
  bool _weatherLoading = true;
  String _locationName = 'Getting your location…';

  // ---------------------------------------------------------------------------
  // MEDIA / POSTS
  // ---------------------------------------------------------------------------

  final ImagePicker _picker = ImagePicker();

  final TextEditingController _postController =
      TextEditingController();

  final List<CommunityPost> _posts = <CommunityPost>[];
  bool _postsLoading = true;
  bool _photoPostUploading = false;

  // Videos are intentionally not shown on Home.
  // They belong to the dedicated Reels/Videos tab.
  final List<CommunityVideo> _videos = <CommunityVideo>[];

  // ---------------------------------------------------------------------------
  // NEWS
  // ---------------------------------------------------------------------------

  List<AgriNewsItem> _news = <AgriNewsItem>[];
  bool _newsLoading = true;
  String _newsRegion = 'India';

  // ---------------------------------------------------------------------------
  // ASSISTANT
  // ---------------------------------------------------------------------------

  final TextEditingController _chatController =
      TextEditingController();

  final ScrollController _chatScrollController =
      ScrollController();

  final stt.SpeechToText _speech =
      stt.SpeechToText();

  final FlutterTts _tts =
      FlutterTts();

  final List<ChatMessage> _messages =
      <ChatMessage>[
    const ChatMessage(
      isUser: false,
      text:
          'Namaste! Ask me about crops, soil, fertilizer, irrigation, pests or weather.',
    ),
  ];

  bool _assistantOpen = false;
  bool _listening = false;
  bool _speechAvailable = false;
  bool _assistantBusy = false;
  bool _ttsReady = false;

  final String _speechLocaleId = 'en-IN';

  @override
  void initState() {
    super.initState();

    _clockTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) {
          return;
        }

        setState(() {
          _now = DateTime.now();
        });
      },
    );

    unawaited(_initializeSpeech());
    unawaited(_initializeTts());
    unawaited(_loadLocationAndWeather());
    unawaited(_loadNews());
    unawaited(_loadCommunityPosts());
    unawaited(_loadVideosFromFirestore());
  }

  @override
  void dispose() {
    _clockTimer?.cancel();

    _postController.dispose();
    _chatController.dispose();
    _chatScrollController.dispose();

    unawaited(_speech.stop());
    unawaited(_tts.stop());

    super.dispose();
  }

  // ===========================================================================
  // BASIC HELPERS
  // ===========================================================================

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
  }


  String get _greeting {
    final int hour = _now.hour;

    if (hour >= 5 && hour < 12) {
      return 'Good Morning';
    }

    if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    }

    if (hour >= 17 && hour < 21) {
      return 'Good Evening';
    }

    return 'Good Night';
  }

  String get _name {
    final String value =
        widget.farmerName?.trim() ?? '';

    if (value.isEmpty) {
      return 'Farmer';
    }

    return value;
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse('$value') ?? 0;
  }

  int _toInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse('$value') ?? 0;
  }

  // ===========================================================================
  // SPEECH / TTS
  // ===========================================================================

  Future<void> _initializeTts() async {
    try {
      await _tts.setSpeechRate(0.48);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      await _tts.setLanguage(_speechLocaleId);

      if (!mounted) {
        return;
      }

      setState(() {
        _ttsReady = true;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _ttsReady = false;
      });
    }
  }

  Future<void> _initializeSpeech() async {
    try {
      final bool available =
          await _speech.initialize(
        onStatus: (String status) {
          if (!mounted) {
            return;
          }

          if (status == 'done' ||
              status == 'notListening') {
            setState(() {
              _listening = false;
            });
          }
        },
        onError: (_) {
          if (!mounted) {
            return;
          }

          setState(() {
            _listening = false;
          });
        },
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _speechAvailable = available;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _speechAvailable = false;
      });
    }
  }

  Future<void> _toggleListening() async {
    if (!_speechAvailable) {
      _showMessage(
        'Voice input is not available on this device.',
      );
      return;
    }

    if (_listening) {
      await _speech.stop();

      if (!mounted) {
        return;
      }

      setState(() {
        _listening = false;
      });

      return;
    }

    setState(() {
      _listening = true;
    });

    await _speech.listen(
      listenOptions: stt.SpeechListenOptions(
        localeId: _speechLocaleId,
      ),
      onResult: (SpeechRecognitionResult result) {
        if (!mounted) {
          return;
        }

        setState(() {
          _chatController.text =
              result.recognizedWords;

          _chatController.selection =
              TextSelection.fromPosition(
            TextPosition(
              offset:
                  _chatController.text.length,
            ),
          );
        });

        if (result.finalResult) {
          setState(() {
            _listening = false;
          });
        }
      },
    );
  }

  Future<void> _speak(String text) async {
    if (!_ttsReady) {
      return;
    }

    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {
      // TTS failure should not break the assistant.
    }
  }

  // ===========================================================================
  // WEATHER
  // ===========================================================================

  Future<void> _loadLocationAndWeather() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _weatherLoading = true;
      _locationName = 'Getting your location…';
    });

    try {
      bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) {
          return;
        }

        setState(() {
          _weatherLoading = false;
          _locationName = 'Location unavailable';
        });

        _showMessage(
          'Please enable location services for live weather.',
        );
        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission ==
              LocationPermission.deniedForever) {
        if (!mounted) {
          return;
        }

        setState(() {
          _weatherLoading = false;
          _locationName = 'Location permission required';
        });

        _showMessage(
          'Allow location permission to load live weather.',
        );
        return;
      }

      final Position position =
          await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      await _loadWeatherForCoordinates(
        position.latitude,
        position.longitude,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _weatherLoading = false;
        _locationName = 'Weather unavailable';
      });
    }
  }

  Future<void> _loadWeatherForCoordinates(
    double latitude,
    double longitude,
  ) async {
    final Uri uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$latitude'
      '&longitude=$longitude'
      '&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m'
      '&timezone=auto',
    );

    try {
      final http.Response response =
          await http.get(uri).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Weather request failed.',
        );
      }

      final Map<String, dynamic> data =
          jsonDecode(response.body)
              as Map<String, dynamic>;

      final Map<String, dynamic> current =
          (data['current']
                  as Map<String, dynamic>?) ??
              <String, dynamic>{};

      if (!mounted) {
        return;
      }

      setState(() {
        _weather = WeatherSnapshot(
          temperature:
              _toDouble(
            current['temperature_2m'],
          ),
          feelsLike:
              _toDouble(
            current['apparent_temperature'],
          ),
          humidity:
              _toDouble(
            current['relative_humidity_2m'],
          ),
          wind:
              _toDouble(
            current['wind_speed_10m'],
          ),
          code:
              _toInt(
            current['weather_code'],
          ),
        );

        _locationName =
            'Current GPS location';

        _weatherLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _weatherLoading = false;
        _locationName = 'Weather unavailable';
      });
    }
  }

  String _weatherText(int code) {
    if (code == 0) {
      return 'Clear sky';
    }

    if (code <= 3) {
      return 'Partly cloudy';
    }

    if (code <= 48) {
      return 'Foggy';
    }

    if (code <= 57) {
      return 'Drizzle';
    }

    if (code <= 67) {
      return 'Rain';
    }

    if (code <= 77) {
      return 'Snow';
    }

    if (code <= 82) {
      return 'Rain showers';
    }

    if (code <= 86) {
      return 'Snow showers';
    }

    return 'Thunderstorm';
  }

  IconData _weatherIcon(int code) {
    if (code == 0) {
      return Icons.wb_sunny_rounded;
    }

    if (code <= 3) {
      return Icons.cloud_rounded;
    }

    if (code <= 48) {
      return Icons.foggy;
    }

    if (code <= 67) {
      return Icons.water_drop_rounded;
    }

    if (code <= 77) {
      return Icons.ac_unit_rounded;
    }

    if (code <= 82) {
      return Icons.grain_rounded;
    }

    return Icons.thunderstorm_rounded;
  }

  // ===========================================================================
  // NEWS
  // ===========================================================================

  Future<void> _loadNews() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _newsLoading = true;
    });

    final String query =
        _newsRegion == 'India'
            ? 'agriculture farming India'
            : 'agriculture farming technology';

    final Uri uri = Uri.parse(
      'https://news.google.com/rss/search?q='
      '${Uri.encodeQueryComponent(query)}'
      '&hl=en-IN&gl=IN&ceid=IN:en',
    );

    try {
      final http.Response response =
          await http.get(uri).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'News request failed.',
        );
      }

      final String body = response.body;

      final RegExp itemPattern =
          RegExp(
        r'<item>(.*?)</item>',
        caseSensitive: false,
        dotAll: true,
      );

      final RegExp titlePattern =
          RegExp(
        r'<title><!\[CDATA\[(.*?)\]\]></title>|<title>(.*?)</title>',
        caseSensitive: false,
        dotAll: true,
      );

      final RegExp linkPattern =
          RegExp(
        r'<link>(.*?)</link>',
        caseSensitive: false,
        dotAll: true,
      );

      final RegExp pubDatePattern =
          RegExp(
        r'<pubDate>(.*?)</pubDate>',
        caseSensitive: false,
        dotAll: true,
      );

      final List<AgriNewsItem> loaded =
          <AgriNewsItem>[];

      for (final RegExpMatch match
          in itemPattern.allMatches(body)) {
        final String item =
            match.group(1) ?? '';

        final RegExpMatch? titleMatch =
            titlePattern.firstMatch(item);

        final RegExpMatch? linkMatch =
            linkPattern.firstMatch(item);

        final RegExpMatch? dateMatch =
            pubDatePattern.firstMatch(item);

        final String title =
            _cleanXml(
          titleMatch?.group(1) ??
              titleMatch?.group(2) ??
              '',
        );

        final String link =
            _cleanXml(
          linkMatch?.group(1) ?? '',
        );

        final String rawDate =
            _cleanXml(
          dateMatch?.group(1) ?? '',
        );

        if (title.isEmpty ||
            link.isEmpty) {
          continue;
        }

        DateTime date =
            DateTime.now();

        try {
          date = DateTime.parse(
            rawDate,
          );
        } catch (_) {}

        loaded.add(
          AgriNewsItem(
            title: title,
            link: link,
            source: 'Google News',
            date: date,
          ),
        );

        if (loaded.length >= 8) {
          break;
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _news = loaded;
        _newsLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _news = <AgriNewsItem>[];
        _newsLoading = false;
      });
    }
  }

  String _cleanXml(String value) {
    return value
        .replaceAll(
          RegExp(r'<[^>]*>'),
          '',
        )
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }

  Future<void> _openNews(
    AgriNewsItem item,
  ) async {
    final Uri uri =
        Uri.parse(item.link);

    try {
      final bool launched =
          await launchUrl(
        uri,
        mode:
            LaunchMode.externalApplication,
      );

      if (!launched) {
        _showMessage(
          'Unable to open the news article.',
        );
      }
    } catch (_) {
      _showMessage(
        'Unable to open the news article.',
      );
    }
  }

  Future<void> _openNewsPanel() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (
        BuildContext sheetContext,
      ) {
        return SizedBox(
          height:
              MediaQuery.of(
                    sheetContext,
                  ).size.height *
                  0.82,
          child: Column(
            children: <Widget>[
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  18,
                  4,
                  18,
                  8,
                ),
                child: Row(
                  children: <Widget>[
                    const Expanded(
                      child: Text(
                        'Agriculture News',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          Navigator.of(
                        sheetContext,
                      ).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 18,
                ),
                child:
                    SegmentedButton<String>(
                  segments:
                      const <ButtonSegment<String>>[
                    ButtonSegment<String>(
                      value: 'India',
                      label: Text('India'),
                      icon: Icon(
                        Icons.location_on_outlined,
                      ),
                    ),
                    ButtonSegment<String>(
                      value: 'Global',
                      label: Text('Global'),
                      icon: Icon(
                        Icons.public_rounded,
                      ),
                    ),
                  ],
                  selected: <String>{
                    _newsRegion,
                  },
                  onSelectionChanged:
                      (
                    Set<String> selection,
                  ) {
                    if (selection.isEmpty) {
                      return;
                    }

                    setState(() {
                      _newsRegion =
                          selection.first;
                    });

                    unawaited(
                      _loadNews(),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _newsLoading
                    ? const Center(
                        child:
                            CircularProgressIndicator(),
                      )
                    : _news.isEmpty
                        ? const _EmptyNews()
                        : ListView.separated(
                            padding:
                                const EdgeInsets
                                    .fromLTRB(
                              18,
                              4,
                              18,
                              30,
                            ),
                            itemCount:
                                _news.length,
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
                              final AgriNewsItem item =
                                  _news[index];

                              return _NewsCard(
                                item: item,
                                onTap: () =>
                                    _openNews(
                                  item,
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // FIRESTORE COMMUNITY POSTS
  // ===========================================================================

  Future<void> _loadCommunityPosts() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _postsLoading = true;
    });

    try {
      final List<CommunityPostData> data =
          await CommunityPostsService.getPosts(
        limit: 50,
      );

      final List<CommunityPost> loadedPosts =
          data
              .map(
                (CommunityPostData post) =>
                    CommunityPost(
                  id: post.id,
                  uid: post.uid,
                  userId: post.userId,
                  author: post.displayName,
                  text: post.text,
                  time: _formatPostTime(
                    post.createdAt,
                  ),
                  likes: post.likesCount,
                  comments: post.commentsCount,
                  mediaPath: null,
                  mediaType:
                      post.mediaType.isEmpty
                          ? null
                          : post.mediaType,
                  mediaUrl:
                      post.mediaUrl.isEmpty
                          ? null
                          : post.mediaUrl,
                  createdAt: post.createdAt,
                ),
              )
              .toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _posts
          ..clear()
          ..addAll(loadedPosts);
        _postsLoading = false;
      });
    } on FirebaseException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _postsLoading = false;
      });

      _showMessage(
        'Community feed load failed: ${error.code}',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _postsLoading = false;
      });

      _showMessage(
        'Community feed load failed: $error',
      );
    }
  }

  String _formatPostTime(DateTime? createdAt) {
    if (createdAt == null) {
      return 'Just now';
    }

    final Duration difference =
        DateTime.now().difference(createdAt);

    if (difference.isNegative ||
        difference.inMinutes < 1) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays}d';
    }

    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  // ===========================================================================
  // FIRESTORE VIDEOS
  // ===========================================================================

  Future<void> _loadVideosFromFirestore() async {
    try {
      final QuerySnapshot<
          Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('farmerVideos')
              .limit(50)
              .get();

      final List<
          QueryDocumentSnapshot<
              Map<String, dynamic>>> documents =
          List<
              QueryDocumentSnapshot<
                  Map<String, dynamic>>>.from(
        snapshot.docs,
      );

      documents.sort(
        (
          QueryDocumentSnapshot<
              Map<String, dynamic>> a,
          QueryDocumentSnapshot<
              Map<String, dynamic>> b,
        ) {
          final dynamic aValue =
              a.data()['createdAt'];

          final dynamic bValue =
              b.data()['createdAt'];

          DateTime aDate =
              DateTime.fromMillisecondsSinceEpoch(
            0,
          );

          DateTime bDate =
              DateTime.fromMillisecondsSinceEpoch(
            0,
          );

          if (aValue is Timestamp) {
            aDate = aValue.toDate();
          }

          if (bValue is Timestamp) {
            bDate = bValue.toDate();
          }

          return bDate.compareTo(aDate);
        },
      );

      final List<CommunityVideo> loadedVideos =
          <CommunityVideo>[];

      for (final QueryDocumentSnapshot<
          Map<String, dynamic>> document
          in documents) {
        final Map<String, dynamic> data =
            document.data();

        final String cloudinaryUrl =
            '${data['cloudinaryUrl'] ?? ''}'
                .trim();

        if (cloudinaryUrl.isEmpty) {
          continue;
        }

        final String author =
            '${data['author'] ?? 'AgriAI Farmer'}'
                .trim();

        final String title =
            '${data['title'] ?? 'Shared a farming video.'}'
                .trim();

        final dynamic durationValue =
            data['duration'];

        final String duration;

        if (durationValue is num) {
          duration =
              _formatDuration(
            durationValue.toDouble(),
          );
        } else {
          final String storedDuration =
              '${durationValue ?? ''}'.trim();

          duration =
              storedDuration.isEmpty
                  ? 'Up to 2 min'
                  : storedDuration;
        }

        loadedVideos.add(
          CommunityVideo(
            author:
                author.isEmpty
                    ? 'AgriAI Farmer'
                    : author,
            title:
                title.isEmpty
                    ? 'Shared a farming video.'
                    : title,
            duration: duration,
            cloudinaryUrl:
                cloudinaryUrl,
            publicId:
                '${data['publicId'] ?? ''}',
          ),
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _videos
          ..clear()
          ..addAll(loadedVideos);

      });
    } on FirebaseException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
      });

      _showMessage(
        'Firestore load failed: ${error.code}',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
      });

      _showMessage(
        'Firestore load failed: $error',
      );
    }
  }

  Future<void> _saveVideoToFirestore({
    required CommunityVideo video,
    required CloudinaryUploadResult result,
  }) async {
    final User? user =
        FirebaseAuth.instance.currentUser;

    final DocumentReference<
        Map<String, dynamic>> document =
        FirebaseFirestore.instance
            .collection('farmerVideos')
            .doc();

    await document.set(
      <String, dynamic>{
        'author': video.author,
        'authorId': user?.uid,
        'title': video.title,
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
        'createdAt':
            Timestamp.now(),
      },
    );

    final DocumentSnapshot<
        Map<String, dynamic>> saved =
        await document.get();

    if (!saved.exists) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code:
            'write-verification-failed',
        message:
            'The video document was not found after saving.',
      );
    }
  }

  Future<void> _createVideoDirectly() async {
    final XFile? file =
        await _picker.pickVideo(
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
        final TextEditingController
            titleController =
            TextEditingController();

        return AlertDialog(
          title: const Text(
            'Add Farmer Reel',
          ),
          content: TextField(
            controller:
                titleController,
            maxLength: 120,
            decoration:
                const InputDecoration(
              hintText:
                  'Enter reel title',
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
                titleController.text
                    .trim(),
              ),
              child:
                  const Text('Upload'),
            ),
          ],
        );
      },
    );

    if (!mounted ||
        title == null) {
      return;
    }

    await _uploadVideoToCloudinary(
      file,
      title,
    );
  }

  Future<void> _uploadVideoToCloudinary(
    XFile file,
    String title,
  ) async {
    bool dialogVisible = false;

    try {
      unawaited(
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (
            BuildContext dialogContext,
          ) {
            dialogVisible = true;

            return const AlertDialog(
              content: Row(
                children: <Widget>[
                  SizedBox(
                    width: 26,
                    height: 26,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2.5,
                    ),
                  ),
                  SizedBox(width: 18),
                  Expanded(
                    child: Text(
                      'Uploading reel to Cloudinary…',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      final CloudinaryUploadResult
          result =
          await CloudinaryMediaService
              .uploadVideo(file);

      if (dialogVisible &&
          mounted) {
        Navigator.of(context).pop();
        dialogVisible = false;
      }

      if (!mounted) {
        return;
      }

      final CommunityVideo video =
          CommunityVideo(
        author: _name,
        title:
            title.isEmpty
                ? 'Shared a farming video.'
                : title,
        duration:
            result.duration == null
                ? 'Up to 2 min'
                : _formatDuration(
                    result.duration!,
                  ),
        cloudinaryUrl:
            result.secureUrl,
        publicId:
            result.publicId,
      );

      await _saveVideoToFirestore(
        video: video,
        result: result,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _videos.insert(
          0,
          video,
        );
      });

      _showMessage(
        'Reel uploaded and saved successfully.',
      );
    } catch (error) {
      if (dialogVisible &&
          mounted) {
        Navigator.of(context).pop();
      }

      if (!mounted) {
        return;
      }

      _showMessage(
        'Reel upload failed: $error',
      );
    }
  }

  String _formatDuration(
    double seconds,
  ) {
    final int totalSeconds =
        seconds.round();

    final int minutes =
        totalSeconds ~/ 60;

    final int remainingSeconds =
        totalSeconds % 60;

    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // ===========================================================================
  // COMMUNITY POSTS
  // ===========================================================================

  Future<void> _createPost() async {
    _postController.clear();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (
        BuildContext sheetContext,
      ) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            4,
            18,
            MediaQuery.of(
                  sheetContext,
                ).viewInsets.bottom +
                20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Create a community post',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Share an idea, question, farming experience, suggestion or tip.',
                  style: TextStyle(
                    color:
                        AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller:
                      _postController,
                  maxLines: 5,
                  maxLength: 1000,
                  decoration:
                      const InputDecoration(
                    hintText:
                        'Write something for farmers…',
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    OutlinedButton.icon(
                      onPressed: () =>
                          _addPhotoPost(
                        sheetContext,
                      ),
                      icon: const Icon(
                        Icons.photo_outlined,
                      ),
                      label:
                          const Text('Photo'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () =>
                          _createVideoDirectly(),
                      icon: const Icon(
                        Icons.video_camera_back_outlined,
                      ),
                      label:
                          const Text('Reel'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () =>
                          _createPresetPost(
                        'Idea',
                        sheetContext,
                      ),
                      icon: const Icon(
                        Icons.lightbulb_outline_rounded,
                      ),
                      label:
                          const Text('Idea'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () =>
                          _createPresetPost(
                        'Question',
                        sheetContext,
                      ),
                      icon: const Icon(
                        Icons.help_outline_rounded,
                      ),
                      label:
                          const Text('Question'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () =>
                        _publishTextPost(
                      sheetContext,
                    ),
                    icon: const Icon(
                      Icons.send_rounded,
                    ),
                    label:
                        const Text('Post'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _publishTextPost(
    BuildContext sheetContext,
  ) async {
    final String text =
        _postController.text.trim();

    if (text.isEmpty) {
      _showMessage(
        'Write something before posting.',
      );
      return;
    }

    try {
      await CommunityPostsService.createPost(
        text: text,
        postType: 'farming_update',
      );

      if (!mounted || !sheetContext.mounted) {
        return;
      }

      Navigator.of(sheetContext).pop();

      _postController.clear();

      await _loadCommunityPosts();

      if (!mounted) {
        return;
      }

      _showMessage(
        'Post published successfully.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to publish post: $error',
      );
    }
  }

  Future<void> _createPresetPost(
    String type,
    BuildContext sheetContext,
  ) async {
    final String text =
        _postController.text.trim();

    final String finalText =
        text.isEmpty
            ? type == 'Idea'
                ? 'I have an idea for improving farming and would like to discuss it with the community.'
                : 'What farming practice has worked best for you this season?'
            : '$type: $text';

    try {
      await CommunityPostsService.createPost(
        text: finalText,
        postType:
            type == 'Idea'
                ? 'idea'
                : 'question',
      );

      if (!mounted || !sheetContext.mounted) {
        return;
      }

      Navigator.of(sheetContext).pop();
      _postController.clear();

      await _loadCommunityPosts();

      if (!mounted) {
        return;
      }

      _showMessage(
        '$type posted successfully.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to publish $type: $error',
      );
    }
  }

  Future<void> _addPhotoPost(
    BuildContext sheetContext,
  ) async {
    try {
      final XFile? file =
          await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (file == null ||
          !mounted) {
        return;
      }

      final String text =
          _postController.text.trim();

      if (!sheetContext.mounted) {
        return;
      }

      Navigator.of(sheetContext).pop();

      await _uploadPhotoPost(
        file: file,
        text: text.isEmpty
            ? 'Shared a farm photo with the community.'
            : text,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to add photo: $error',
      );
    }
  }

  Future<void> _uploadPhotoPost({
    required XFile file,
    required String text,
  }) async {
    if (_photoPostUploading) {
      return;
    }

    setState(() {
      _photoPostUploading = true;
    });

    try {
      _showMessage(
        'Uploading photo to Cloudinary…',
      );

      final CloudinaryUploadResult result =
          await CloudinaryMediaService.uploadImage(
        File(file.path),
      );

      await CommunityPostsService.createPost(
        text: text,
        postType: 'photo',
        mediaUrl: result.secureUrl,
        mediaType: 'photo',
      );

      await _loadCommunityPosts();

      if (!mounted) {
        return;
      }

      _showMessage(
        'Photo uploaded and published successfully.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Photo upload failed: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _photoPostUploading = false;
        });
      }
    }
  }

  // ===========================================================================
  // POST ACTIONS
  // ===========================================================================

  Future<void> _showPostMenu(
    CommunityPost post,
  ) async {
    final User? currentUser =
        FirebaseAuth.instance.currentUser;

    final bool isOwner =
        currentUser != null &&
        post.uid.isNotEmpty &&
        post.uid == currentUser.uid;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (
        BuildContext sheetContext,
      ) {
        if (isOwner) {
          final bool isPhoto =
              post.mediaType == 'photo' ||
              (post.mediaUrl?.isNotEmpty ?? false);

          return SafeArea(
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: const Icon(
                    Icons.edit_outlined,
                  ),
                  title: Text(
                    isPhoto
                        ? 'Edit Caption'
                        : 'Edit Post',
                  ),
                  onTap: () {
                    Navigator.of(
                      sheetContext,
                    ).pop();
                    unawaited(
                      _editCommunityPost(post),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red.shade700,
                  ),
                  title: Text(
                    'Delete Post',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(
                      sheetContext,
                    ).pop();
                    unawaited(
                      _deleteCommunityPost(post),
                    );
                  },
                ),
              ],
            ),
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(
                  Icons.bookmark_border_rounded,
                ),
                title:
                    const Text('Save post'),
                onTap: () {
                  Navigator.of(
                    sheetContext,
                  ).pop();

                  _showMessage(
                    'Post saved.',
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.flag_outlined,
                ),
                title:
                    const Text('Report post'),
                onTap: () {
                  Navigator.of(
                    sheetContext,
                  ).pop();

                  _showMessage(
                    'Report option selected.',
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editCommunityPost(
    CommunityPost post,
  ) async {
    final User? currentUser =
        FirebaseAuth.instance.currentUser;

    if (currentUser == null ||
        post.uid != currentUser.uid ||
        post.id.isEmpty) {
      _showMessage(
        'You can only edit your own posts.',
      );
      return;
    }

    final TextEditingController controller =
        TextEditingController(
      text: post.text,
    );

    try {
      final String? editedText =
          await showDialog<String>(
        context: context,
        builder: (
          BuildContext dialogContext,
        ) {
          final bool isPhoto =
              post.mediaType == 'photo' ||
              (post.mediaUrl?.isNotEmpty ?? false);

          return AlertDialog(
            title: Text(
              isPhoto
                  ? 'Edit Caption'
                  : 'Edit Post',
            ),
            content: TextField(
              controller: controller,
              maxLines: 6,
              maxLength: 1000,
              autofocus: true,
              decoration: InputDecoration(
                hintText: isPhoto
                    ? 'Write a caption…'
                    : 'Write your post…',
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
                onPressed: () {
                  final String value =
                      controller.text.trim();

                  if (value.isEmpty) {
                    _showMessage(
                      'Caption cannot be empty.',
                    );
                    return;
                  }

                  Navigator.of(
                    dialogContext,
                  ).pop(value);
                },
                child:
                    const Text('Save'),
              ),
            ],
          );
        },
      );

      if (!mounted ||
          editedText == null ||
          editedText.trim().isEmpty) {
        return;
      }

      await CommunityPostsService.updatePost(
        postId: post.id,
        text: editedText.trim(),
      );

      await _loadCommunityPosts();

      if (!mounted) {
        return;
      }

      _showMessage(
        'Post updated successfully.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to update post: $error',
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _deleteCommunityPost(
    CommunityPost post,
  ) async {
    final User? currentUser =
        FirebaseAuth.instance.currentUser;

    if (currentUser == null ||
        post.uid != currentUser.uid ||
        post.id.isEmpty) {
      _showMessage(
        'You can only delete your own posts.',
      );
      return;
    }

    final bool? confirmed =
        await showDialog<bool>(
      context: context,
      builder: (
        BuildContext dialogContext,
      ) {
        return AlertDialog(
          title: const Text(
            'Delete post?',
          ),
          content: const Text(
            'This will permanently remove the post from the AgriAI community.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () =>
                  Navigator.of(
                dialogContext,
              ).pop(false),
              child:
                  const Text('Cancel'),
            ),
            FilledButton(
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    Colors.red.shade700,
              ),
              onPressed: () =>
                  Navigator.of(
                dialogContext,
              ).pop(true),
              child:
                  const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (!mounted ||
        confirmed != true) {
      return;
    }

    try {
      await CommunityPostsService.deletePost(
        postId: post.id,
      );

      await _loadCommunityPosts();

      if (!mounted) {
        return;
      }

      _showMessage(
        'Post deleted successfully.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to delete post: $error',
      );
    }
  }

  Future<void> _showComments(
    CommunityPost post,
  ) async {
    if (post.id.trim().isEmpty) {
      _showMessage(
        'This post cannot receive comments.',
      );
      return;
    }

    // The Comments sheet owns its TextEditingController.
    // This prevents the controller from being disposed by the
    // parent while Flutter is still tearing down the modal route.
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (
        BuildContext sheetContext,
      ) {
        return _CommentsSheet(
          postId: post.id,
        );
      },
    );

    if (!mounted) {
      return;
    }

    await _loadCommunityPosts();
  }

  Future<void> _sharePost(
    CommunityPost post,
  ) async {
    if (post.id.trim().isEmpty) {
      _showMessage(
        'This post cannot be shared.',
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return _ShareChoiceSheet(
          onShareToAgriAI: () {
            Navigator.of(sheetContext).pop();
            unawaited(
              _sharePostToAgriAI(post),
            );
          },
          onShareOutsideAgriAI: () {
            Navigator.of(sheetContext).pop();
            unawaited(
              _sharePostOutsideAgriAI(post),
            );
          },
        );
      },
    );
  }

  Future<void> _sharePostToAgriAI(
    CommunityPost post,
  ) async {
    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return _AgriAIShareSheet(post: post);
      },
    );
  }

  Future<void> _sharePostOutsideAgriAI(
    CommunityPost post,
  ) async {
    final String author =
        post.userId.trim().isEmpty
            ? post.author.trim()
            : '@${post.userId.trim()}';

    final String postText =
        post.text.trim().isEmpty
            ? 'Shared a farming post on AgriAI.'
            : post.text.trim();

    final StringBuffer shareText =
        StringBuffer();

    shareText.writeln('AgriAI Community Post');
    shareText.writeln('By $author');
    shareText.writeln();
    shareText.writeln(postText);

    final String mediaUrl =
        post.mediaUrl?.trim() ?? '';

    if (mediaUrl.isNotEmpty) {
      shareText.writeln();
      shareText.writeln('Media: $mediaUrl');
    }

    shareText.writeln();
    shareText.writeln('Shared from AgriAI');

    try {
      final ShareResult result =
          await SharePlus.instance.share(
        ShareParams(
          text: shareText.toString(),
          subject: 'AgriAI Community Post',
          title: 'Share AgriAI Post',
        ),
      );

      if (!mounted) {
        return;
      }

      if (result.status == ShareResultStatus.unavailable) {
        _showMessage(
          'No sharing apps are available on this device.',
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to open the share sheet: $error',
      );
    }
  }

  // ===========================================================================
  // AGriAI ASSISTANT
  // ===========================================================================

  Future<void> _openAssistant() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _assistantOpen = true;
    });

    _scrollChat();
  }

  void _closeAssistant() {
    if (!mounted) {
      return;
    }

    setState(() {
      _assistantOpen = false;
    });

    unawaited(
      _speech.stop(),
    );
  }

  Future<void> _sendMessage() async {
    final String question =
        _chatController.text.trim();

    if (question.isEmpty ||
        _assistantBusy) {
      return;
    }

    _chatController.clear();

    setState(() {
      _messages.add(
        ChatMessage(
          isUser: true,
          text: question,
        ),
      );

      _assistantBusy = true;
    });

    _scrollChat();

    await Future<void>.delayed(
      const Duration(
        milliseconds: 350,
      ),
    );

    final String response =
        _assistantResponse(question);

    if (!mounted) {
      return;
    }

    setState(() {
      _messages.add(
        ChatMessage(
          isUser: false,
          text: response,
        ),
      );

      _assistantBusy = false;
    });

    _scrollChat();

    await _speak(response);
  }

  String _assistantResponse(
    String question,
  ) {
    final String q =
        question.toLowerCase();

    String weatherSuffix = '';

    if (_weather != null) {
      weatherSuffix =
          ' Current Home weather is ${_weather!.temperature.round()}°C with ${_weatherText(_weather!.code).toLowerCase()}.';
    }

    if (q.contains('fertilizer') ||
        q.contains('urea') ||
        q.contains('nutrient')) {
      return 'Fertilizer decisions should be based on crop stage, soil test results and nutrient requirements. Avoid applying nutrients blindly.$weatherSuffix';
    }

    if (q.contains('irrigation') ||
        q.contains('water')) {
      return 'Irrigation should consider soil moisture, crop stage and recent rainfall. Avoid unnecessary watering when soil moisture is already adequate.$weatherSuffix';
    }

    if (q.contains('disease') ||
        q.contains('pest') ||
        q.contains('leaf')) {
      return 'Check the crop, affected plant part and visible symptoms. You can use Disease Detection for image-based assessment.$weatherSuffix';
    }

    if (q.contains('weather') ||
        q.contains('temperature') ||
        q.contains('rain')) {
      if (_weather == null) {
        return 'Live weather is not available right now. Refresh the Home screen and allow GPS access.';
      }

      return 'Current weather: '
          '${_weather!.temperature.round()}°C, '
          '${_weatherText(_weather!.code)}, '
          'humidity ${_weather!.humidity.round()}%, '
          'wind ${_weather!.wind.round()} km/h.';
    }

    if (q.contains('price') ||
        q.contains('mandi') ||
        q.contains('market')) {
      return 'Agricultural prices change frequently. Check the latest official market or mandi data for your crop and market before selling.';
    }

    if (q.contains('soil') ||
        q.contains('ph')) {
      return 'A current soil test is the best basis for fertilizer and soil-management decisions. Consider pH, organic matter and available nutrients.';
    }

    if (q.contains('yield') ||
        q.contains('production')) {
      return 'For yield prediction, use the Yield section and provide crop, area, rainfall, temperature, humidity, fertilizer and soil information where available.';
    }

    return 'I can help with crops, soil, fertilizer, irrigation, pests, disease, weather and farming practices. Ask me a specific agriculture question.';
  }

  void _scrollChat() {
    WidgetsBinding.instance
        .addPostFrameCallback(
      (_) {
        if (!_chatScrollController
            .hasClients) {
          return;
        }

        _chatScrollController.animateTo(
          _chatScrollController
              .position
              .maxScrollExtent,
          duration:
              const Duration(
            milliseconds: 250,
          ),
          curve:
              Curves.easeOut,
        );
      },
    );
  }

  // ===========================================================================
  // UI
  // ===========================================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color:
              AppColors.primary,
          onRefresh: () async {
            await Future.wait<void>(
              <Future<void>>[
                _loadLocationAndWeather(),
                _loadNews(),
                _loadCommunityPosts(),
              ],
            );
          },
          child:
              CustomScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            slivers:
                <Widget>[
              SliverPadding(
                padding:
                    const EdgeInsets.fromLTRB(
                  18,
                  10,
                  18,
                  120,
                ),
                sliver:
                    SliverList(
                  delegate:
                      SliverChildListDelegate(
                    <Widget>[
                      _Header(
                        greeting:
                            _greeting,
                        name: _name,
                        onSearch:
                            widget.onSearch,
                        onNotifications:
                            () {
                          _showMessage(
                            'Notifications will appear here.',
                          );
                        },
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      _CompactWeather(
                        weather:
                            _weather,
                        loading:
                            _weatherLoading,
                        location:
                            _locationName,
                        description:
                            _weather == null
                                ? 'Loading live weather…'
                                : _weatherText(
                                    _weather!.code,
                                  ),
                        icon:
                            _weatherIcon(
                          _weather?.code ??
                              0,
                        ),
                        onRefresh:
                            _loadLocationAndWeather,
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      const Padding(
                        padding: EdgeInsets.only(left: 2, bottom: 10),
                        child: Text(
                          'SHARE WITH YOUR FARMING COMMUNITY',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ),

                      _ComposerCard(
                        name: _name,
                        onCreatePost:
                            _createPost,
                        onPhoto: () =>
                            _quickPhotoPost(),
                        onReel:
                            _createVideoDirectly,
                        onIdea: () =>
                            _quickPresetPost(
                          'Idea',
                        ),
                        onQuestion: () =>
                            _quickPresetPost(
                          'Question',
                        ),
                      ),

                      const SizedBox(
                        height: 24,
                      ),

                      Row(
                        children:
                            <Widget>[
                          const Expanded(
                            child:
                                _Title(
                              'Agri Community',
                            ),
                          ),
                          TextButton(
                            onPressed:
                                _createPost,
                            child:
                                const Text(
                              'Create Post',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      const Text(
                        'Ideas • tips • questions • farming experiences • suggestions',
                        style:
                            TextStyle(
                          fontSize:
                              10.5,
                          color:
                              AppColors
                                  .textSecondary,
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      if (_postsLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 28,
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                            ),
                          ),
                        )
                      else if (_posts.isEmpty)
                        const _EmptyPosts()
                      else
                        ..._posts.map(
                          (
                            CommunityPost
                                post,
                          ) =>
                              Padding(
                            padding:
                                const EdgeInsets.only(
                              bottom:
                                  10,
                            ),
                            child:
                                _PostCard(
                              post:
                                  post,
                              onMenu:
                                  () =>
                                      _showPostMenu(
                                    post,
                                  ),
                              onComments:
                                  () =>
                                      _showComments(
                                    post,
                                  ),
                              onShare:
                                  () =>
                                      _sharePost(
                                    post,
                                  ),
                            ),
                          ),
                        ),

                      const SizedBox(
                        height: 14,
                      ),

                      Row(
                        children:
                            <Widget>[
                          const Expanded(
                            child:
                                _Title(
                              'Agriculture News',
                            ),
                          ),
                          TextButton(
                            onPressed:
                                _openNewsPanel,
                            child:
                                const Text(
                              'View All',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      if (_newsLoading)
                        const SizedBox(
                          height:
                              100,
                          child:
                              Center(
                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  2,
                            ),
                          ),
                        )
                      else if (_news.isEmpty)
                        const _EmptyNews()
                      else
                        ..._news
                            .take(3)
                            .map(
                          (
                            AgriNewsItem
                                item,
                          ) =>
                              Padding(
                            padding:
                                const EdgeInsets.only(
                              bottom:
                                  10,
                            ),
                            child:
                                _NewsCard(
                              item:
                                  item,
                              onTap:
                                  () =>
                                      _openNews(
                                    item,
                                  ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton:
          _assistantOpen
              ? null
              : _FloatingButtons(
                  onDm:
                      _openDirectMessages,
                  onNews:
                      _openNewsPanel,
                  onAssistant:
                      _openAssistant,
                ),
      bottomSheet:
          _assistantOpen
              ? _AssistantSheet(
                  messages:
                      _messages,
                  controller:
                      _chatController,
                  scrollController:
                      _chatScrollController,
                  busy:
                      _assistantBusy,
                  listening:
                      _listening,
                  onClose:
                      _closeAssistant,
                  onVoice:
                      _toggleListening,
                  onSend:
                      _sendMessage,
                )
              : null,
    );
  }

  void _openDirectMessages() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const DirectMessagesScreen(),
      ),
    );
  }

  Future<void> _quickPhotoPost() async {
    if (_photoPostUploading) {
      return;
    }

    final XFile? file =
        await _picker.pickImage(
      source:
          ImageSource.gallery,
      imageQuality: 85,
    );

    if (file == null ||
        !mounted) {
      return;
    }

    await _uploadPhotoPost(
      file: file,
      text:
          'Shared a farm photo with the community.',
    );
  }

  Future<void> _quickPresetPost(
    String type,
  ) async {
    final String text =
        type == 'Idea'
            ? 'I have an idea for improving farming and would like to discuss it with the community.'
            : 'What farming practice has worked best for you this season?';

    try {
      await CommunityPostsService.createPost(
        text: '$type: $text',
        postType:
            type == 'Idea'
                ? 'idea'
                : 'question',
      );

      await _loadCommunityPosts();

      if (!mounted) {
        return;
      }

      _showMessage(
        '$type posted successfully.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to publish $type: $error',
      );
    }
  }
}

// ============================================================================
// HEADER
// ============================================================================

class _Header extends StatelessWidget {
  final String greeting;
  final String name;
  final VoidCallback? onSearch;
  final VoidCallback? onNotifications;

  const _Header({
    required this.greeting,
    required this.name,
    this.onSearch,
    this.onNotifications,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 10, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.82),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.28),
              ),
            ),
            child: const Icon(
              Icons.agriculture_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  greeting,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.82),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$name 👋',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Grow better. Farm smarter.',
                  style: TextStyle(
                    fontSize: 9.5,
                    color: Colors.white.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _HeaderButton(
            icon: Icons.search_rounded,
            tooltip: 'Find Farmers',
            onTap: onSearch,
            foregroundColor: Colors.white,
            backgroundColor: Colors.white.withValues(alpha: 0.14),
          ),
          _HeaderButton(
            icon: Icons.notifications_none_rounded,
            tooltip: 'Notifications',
            onTap: onNotifications,
            foregroundColor: Colors.white,
            backgroundColor: Colors.white.withValues(alpha: 0.14),
          ),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color? foregroundColor;
  final Color? backgroundColor;

  const _HeaderButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.foregroundColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor ?? AppColors.textPrimary,
      ),
      icon: Icon(
        icon,
        size: 22,
      ),
    );
  }
}

// ============================================================================
// WEATHER
// ============================================================================

class _CompactWeather
    extends StatelessWidget {
  final WeatherSnapshot? weather;
  final bool loading;
  final String location;
  final String description;
  final IconData icon;
  final Future<void> Function()
      onRefresh;

  const _CompactWeather({
    required this.weather,
    required this.loading,
    required this.location,
    required this.description,
    required this.icon,
    required this.onRefresh,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(16),
      decoration:
          BoxDecoration(
        color:
            AppColors.surface,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        border:
            Border.all(
          color:
              AppColors.border,
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration:
                BoxDecoration(
              color:
                  AppColors.cardGreen,
              borderRadius:
                  BorderRadius.circular(
                16,
              ),
            ),
            child:
                Icon(
              icon,
              color:
                  AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children:
                  <Widget>[
                Text(
                  loading
                      ? 'Live Weather'
                      : weather == null
                          ? 'Weather'
                          : '${weather!.temperature.round()}°C • $description',
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  location,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    fontSize: 10,
                    color:
                        AppColors
                            .textSecondary,
                  ),
                ),
                if (weather != null)
                  Padding(
                    padding:
                        const EdgeInsets.only(
                      top: 4,
                    ),
                    child:
                        Text(
                      'Humidity ${weather!.humidity.round()}%  •  Wind ${weather!.wind.round()} km/h',
                      style:
                          const TextStyle(
                        fontSize:
                            9.5,
                        color:
                            AppColors
                                .textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip:
                'Refresh weather',
            onPressed:
                loading
                    ? null
                    : onRefresh,
            icon:
                const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// COMPOSER
// ============================================================================

class _ComposerCard
    extends StatelessWidget {
  final String name;
  final VoidCallback onCreatePost;
  final VoidCallback onPhoto;
  final VoidCallback onReel;
  final VoidCallback onIdea;
  final VoidCallback onQuestion;

  const _ComposerCard({
    required this.name,
    required this.onCreatePost,
    required this.onPhoto,
    required this.onReel,
    required this.onIdea,
    required this.onQuestion,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(16),
      decoration:
          BoxDecoration(
        color:
            AppColors.surface,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        border:
            Border.all(
          color:
              AppColors.border,
        ),
      ),
      child:
          Column(
        children:
            <Widget>[
          InkWell(
            borderRadius:
                BorderRadius.circular(
              16,
            ),
            onTap:
                onCreatePost,
            child:
                Row(
              children:
                  <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration:
                      const BoxDecoration(
                    color:
                        AppColors.cardGreen,
                    shape:
                        BoxShape.circle,
                  ),
                  child:
                      const Icon(
                    Icons
                        .person_outline_rounded,
                    color:
                        AppColors.primary,
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child:
                      Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal:
                          14,
                      vertical:
                          12,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          AppColors.background,
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                    ),
                    child:
                        Text(
                      'What is happening on your farm, $name?',
                      maxLines:
                          1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        color:
                            AppColors
                                .textSecondary,
                        fontSize:
                            11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 14,
          ),
          Row(
            children:
                <Widget>[
              Expanded(
                child:
                    _ComposerAction(
                  icon:
                      Icons.photo_outlined,
                  label:
                      'Photo',
                  onTap:
                      onPhoto,
                ),
              ),
              Expanded(
                child:
                    _ComposerAction(
                  icon:
                      Icons.play_circle_outline_rounded,
                  label:
                      'Reel',
                  onTap:
                      onReel,
                ),
              ),
              Expanded(
                child:
                    _ComposerAction(
                  icon:
                      Icons.lightbulb_outline_rounded,
                  label:
                      'Idea',
                  onTap:
                      onIdea,
                ),
              ),
              Expanded(
                child:
                    _ComposerAction(
                  icon:
                      Icons.help_outline_rounded,
                  label:
                      'Question',
                  onTap:
                      onQuestion,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComposerAction
    extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ComposerAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return InkWell(
      onTap:
          onTap,
      borderRadius:
          BorderRadius.circular(
        14,
      ),
      child:
          Padding(
        padding:
            const EdgeInsets.symmetric(
          vertical:
              6,
        ),
        child:
            Column(
          children:
              <Widget>[
            Icon(
              icon,
              size: 22,
              color:
                  AppColors.primary,
            ),
            const SizedBox(
              height: 4,
            ),
            Text(
              label,
              style:
                  const TextStyle(
                fontSize:
                    9.5,
                fontWeight:
                    FontWeight.w700,
                color:
                    AppColors
                        .textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// TITLE
// ============================================================================

class _Title
    extends StatelessWidget {
  final String text;

  const _Title(
    this.text,
  );

  @override
  Widget build(
    BuildContext context,
  ) {
    return Text(
      text,
      style:
          const TextStyle(
        fontSize: 17,
        fontWeight:
            FontWeight.w900,
        color:
            AppColors.textPrimary,
      ),
    );
  }
}

// ============================================================================
// POST CARD
// ============================================================================

class _PostCard extends StatefulWidget {
  final CommunityPost post;
  final VoidCallback onMenu;
  final VoidCallback onComments;
  final VoidCallback onShare;

  const _PostCard({
    required this.post,
    required this.onMenu,
    required this.onComments,
    required this.onShare,
  });

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {

  int _toInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse('$value') ?? 0;
  }

  late int _likes;
  bool _liked = false;
  bool _saved = false;
  bool _likeBusy = false;
  bool _saveBusy = false;

  @override
  void initState() {
    super.initState();
    _likes = widget.post.likes;
    unawaited(_loadLikeState());
    unawaited(_loadSavedState());
  }

  Future<void> _loadSavedState() async {
    if (widget.post.id.trim().isEmpty) {
      return;
    }

    try {
      final bool saved =
          await CommunitySavedPostsService.hasSaved(
        postId: widget.post.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _saved = saved;
      });
    } catch (_) {
      // A failed saved-state read should not break the feed.
    }
  }

  Future<void> _toggleSaved() async {
    if (_saveBusy || widget.post.id.trim().isEmpty) {
      return;
    }

    setState(() {
      _saveBusy = true;
    });

    try {
      final bool saved =
          await CommunitySavedPostsService.toggleSaved(
        postId: widget.post.id,
        postOwnerUid: widget.post.uid,
        userId: widget.post.userId,
        displayName: widget.post.author,
        text: widget.post.text,
        postType: widget.post.mediaType ?? '',
        mediaUrl: widget.post.mediaUrl ?? '',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _saved = saved;
        _saveBusy = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                saved
                    ? 'Post saved.'
                    : 'Post removed from Saved.',
              ),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _saveBusy = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Save failed: $error',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  Future<void> _loadLikeState() async {
    if (widget.post.id.trim().isEmpty) {
      return;
    }

    try {
      final bool liked =
          await CommunityPostsService.hasLiked(
        postId: widget.post.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _liked = liked;
      });
    } catch (_) {
      // A failed like-state read should not break the feed.
    }
  }

  Future<void> _toggleLike() async {
    if (_likeBusy || widget.post.id.trim().isEmpty) {
      return;
    }

    setState(() {
      _likeBusy = true;
    });

    try {
      final User? user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception(
          'User is not signed in.',
        );
      }

      final String postId =
          widget.post.id.trim();

      final DocumentReference<Map<String, dynamic>> postRef =
          FirebaseFirestore.instance
              .collection('communityPosts')
              .doc(postId);

      final DocumentReference<Map<String, dynamic>> likeRef =
          postRef
              .collection('likes')
              .doc(user.uid);

      final DocumentSnapshot<Map<String, dynamic>> postSnapshot =
          await postRef.get(
        const GetOptions(
          source: Source.server,
        ),
      );

      if (!postSnapshot.exists) {
        throw Exception(
          'The community post could not be found in Firestore.',
        );
      }

      final DocumentSnapshot<Map<String, dynamic>> likeSnapshot =
          await likeRef.get(
        const GetOptions(
          source: Source.server,
        ),
      );

      if (likeSnapshot.exists) {
        // UNLIKE
        final Map<String, dynamic> postData =
            postSnapshot.data() ?? <String, dynamic>{};

        final int currentCount =
            _toInt(postData['likesCount']);

        final int newCount =
            currentCount > 0
                ? currentCount - 1
                : 0;

        await likeRef.delete();

        await postRef.update(
          <String, dynamic>{
            'likesCount': newCount,
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );
      } else {
        // LIKE
        await likeRef.set(
          <String, dynamic>{
            'uid': user.uid,
            'createdAt':
                FieldValue.serverTimestamp(),
          },
        );

        await postRef.update(
          <String, dynamic>{
            'likesCount':
                FieldValue.increment(1),
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );
      }

      // Always read the server value after writing.
      final DocumentSnapshot<Map<String, dynamic>> verifyPost =
          await postRef.get(
        const GetOptions(
          source: Source.server,
        ),
      );

      final DocumentSnapshot<Map<String, dynamic>> verifyLike =
          await likeRef.get(
        const GetOptions(
          source: Source.server,
        ),
      );

      if (!verifyPost.exists) {
        throw Exception(
          'Firestore could not verify the post after the Like operation.',
        );
      }

      final int serverLikes =
          _toInt(
        verifyPost.data()?['likesCount'],
      );

      final bool serverLiked =
          verifyLike.exists;

      if (!mounted) {
        return;
      }

      setState(() {
        _liked = serverLiked;
        _likes = serverLikes;
        _likeBusy = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _likeBusy = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Like failed: $error',
            ),
            behavior:
                SnackBarBehavior.floating,
            duration:
                const Duration(seconds: 5),
          ),
        );
    }
  }

  String get _postType {
    final String text = widget.post.text.trim().toLowerCase();
    if (text.startsWith('idea:')) return 'IDEA';
    if (text.startsWith('question:')) return 'QUESTION';
    if (widget.post.mediaType == 'photo') return 'FARM PHOTO';
    return 'FARMING UPDATE';
  }

  IconData get _postTypeIcon {
    switch (_postType) {
      case 'IDEA':
        return Icons.lightbulb_outline_rounded;
      case 'QUESTION':
        return Icons.help_outline_rounded;
      case 'FARM PHOTO':
        return Icons.photo_camera_outlined;
      default:
        return Icons.agriculture_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 11),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.cardGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      widget.post.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${widget.post.userId.isEmpty ? '@farmer' : '@${widget.post.userId}'}  •  ${widget.post.time}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardGreen,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      _postTypeIcon,
                      size: 12,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _postType,
                      style: const TextStyle(
                        fontSize: 7.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        letterSpacing: 0.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 2),
              IconButton(
                tooltip: 'More',
                visualDensity: VisualDensity.compact,
                onPressed: widget.onMenu,
                icon: const Icon(
                  Icons.more_horiz_rounded,
                  size: 21,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            widget.post.text,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.48,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (widget.post.mediaType == 'photo' &&
              (widget.post.mediaUrl?.isNotEmpty == true ||
                  widget.post.mediaPath?.isNotEmpty == true))
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 1.42,
                  child: widget.post.mediaUrl?.isNotEmpty == true
                      ? Image.network(
                          widget.post.mediaUrl!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (
                            BuildContext context,
                            Widget child,
                            ImageChunkEvent? loadingProgress,
                          ) {
                            if (loadingProgress == null) {
                              return child;
                            }

                            return Container(
                              color: AppColors.cardGreen,
                              alignment: Alignment.center,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            );
                          },
                          errorBuilder: (
                            BuildContext context,
                            Object error,
                            StackTrace? stackTrace,
                          ) {
                            return Container(
                              color: AppColors.cardGreen,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.broken_image_outlined,
                                color: AppColors.primary,
                                size: 42,
                              ),
                            );
                          },
                        )
                      : Image.file(
                          File(widget.post.mediaPath!),
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (
                            BuildContext context,
                            Object error,
                            StackTrace? stackTrace,
                          ) {
                            return Container(
                              color: AppColors.cardGreen,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.broken_image_outlined,
                                color: AppColors.primary,
                                size: 42,
                              ),
                            );
                          },
                        ),
                ),
              ),
            ),
          const SizedBox(height: 11),
          Row(
            children: <Widget>[
              if (_likes > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: AppColors.cardGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        size: 12,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$_likes',
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              const Spacer(),
              Text(
                '${widget.post.comments} comments',
                style: const TextStyle(
                  fontSize: 8.5,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(top: 9),
            child: Divider(height: 1, color: AppColors.border),
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: _PostAction(
                  icon: _liked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  label: 'Like',
                  active: _liked,
                  onTap: _likeBusy ? () {} : _toggleLike,
                ),
              ),
              Expanded(
                child: _PostAction(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Comment',
                  onTap: widget.onComments,
                ),
              ),
              Expanded(
                child: _PostAction(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  onTap: widget.onShare,
                ),
              ),
              Expanded(
                child: _PostAction(
                  icon: _saved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  label: 'Save',
                  active: _saved,
                  onTap: _saveBusy ? () {} : _toggleSaved,
                ),
              ),
            ],
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
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              icon,
              size: 17,
              color: active
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 8.5,
                color: active
                    ? AppColors.primary
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SHARE CHOICE SHEET
// ============================================================================

class _ShareChoiceSheet extends StatelessWidget {
  final VoidCallback onShareToAgriAI;
  final VoidCallback onShareOutsideAgriAI;

  const _ShareChoiceSheet({
    required this.onShareToAgriAI,
    required this.onShareOutsideAgriAI,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.fromLTRB(2, 4, 2, 14),
              child: Text(
                'Share Post',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            _ShareChoiceTile(
              icon: Icons.people_alt_outlined,
              title: 'Share to AgriAI',
              subtitle: 'Send this post directly to another farmer',
              onTap: onShareToAgriAI,
            ),
            const SizedBox(height: 10),
            _ShareChoiceTile(
              icon: Icons.ios_share_rounded,
              title: 'Share outside AgriAI',
              subtitle: 'WhatsApp, Telegram, Instagram, SMS, Email and more',
              onTap: onShareOutsideAgriAI,
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareChoiceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ShareChoiceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.border,
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.cardGreen,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 9.5,
                        height: 1.3,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// AGRIAI SHARE SHEET
// ============================================================================

class _AgriAIShareSheet extends StatefulWidget {
  final CommunityPost post;

  const _AgriAIShareSheet({
    required this.post,
  });

  @override
  State<_AgriAIShareSheet> createState() =>
      _AgriAIShareSheetState();
}

class _AgriAIShareSheetState extends State<_AgriAIShareSheet> {
  final TextEditingController _searchController =
      TextEditingController();

  Timer? _searchDebounce;
  List<_ShareUser> _users = <_ShareUser>[];
  bool _loading = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    unawaited(_searchUsers(''));
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    final String query = value.trim().toLowerCase();

    setState(() {
      _query = query;
    });

    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 350),
      () => unawaited(_searchUsers(query)),
    );
  }

  Future<void> _searchUsers(String query) async {
    if (!mounted) return;

    setState(() => _loading = true);

    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        throw FirebaseException(
          plugin: 'firebase_auth',
          code: 'not-authenticated',
          message: 'You must be signed in to share a post.',
        );
      }

      final CollectionReference<Map<String, dynamic>> users =
          FirebaseFirestore.instance.collection('users');

      final Query<Map<String, dynamic>> searchQuery =
          query.isEmpty
              ? users.orderBy('userIdLower').limit(20)
              : users
                  .orderBy('userIdLower')
                  .startAt(<String>[query])
                  .endAt(<String>['$query\\uf8ff'])
                  .limit(20);

      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await searchQuery.get();

      final List<_ShareUser> loaded = <_ShareUser>[];

      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in snapshot.docs) {
        final Map<String, dynamic> data = doc.data();
        final String uid = '${data['uid'] ?? doc.id}'.trim();

        if (uid.isEmpty || uid == currentUser.uid) continue;

        final String userId = '${data['userId'] ?? ''}'.trim();
        if (userId.isEmpty) continue;

        final String userIdLower =
            '${data['userIdLower'] ?? userId}'.trim().toLowerCase();

        if (query.isNotEmpty && !userIdLower.startsWith(query)) {
          continue;
        }

        final String displayName =
            '${data['displayName'] ?? 'AgriAI Farmer'}'.trim();

        loaded.add(
          _ShareUser(
            uid: uid,
            userId: userId,
            displayName:
                displayName.isEmpty ? 'AgriAI Farmer' : displayName,
            photoUrl: '${data['photoUrl'] ?? ''}'.trim(),
            location: '${data['location'] ?? ''}'.trim(),
          ),
        );
      }

      if (!mounted) return;

      setState(() {
        _users = loaded;
        _loading = false;
      });
    } on FirebaseException catch (error) {
      if (!mounted) return;

      setState(() {
        _users = <_ShareUser>[];
        _loading = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Unable to find farmers: ${error.code}',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _users = <_ShareUser>[];
        _loading = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Unable to find farmers: $error'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  Future<void> _shareWithUser(_ShareUser user) async {
    if (_loading) return;

    setState(() => _loading = true);

    try {
      // Create/open the DM conversation first. A share inside AgriAI
      // must also appear as a real message in the farmer's inbox.
      final String conversationId =
          await DirectMessagesService.getOrCreateConversation(
        otherUid: user.uid,
      );

      // Send the actual post into the DM conversation so the recipient
      // gets a conversation, unread count, and a mixed-media message.
      await DirectMessagesService.sendPostMessage(
        conversationId: conversationId,
        receiverUid: user.uid,
        postId: widget.post.id,
        text: widget.post.text.trim(),
        mediaUrl: widget.post.mediaUrl?.trim() ?? '',
      );

      // Keep the existing share-history record as well.
      await CommunityShareService.sharePostToUser(
        postId: widget.post.id,
        toUid: user.uid,
      );

      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Post shared with @${user.userId}.'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
    } on FirebaseException catch (error) {
      if (!mounted) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              error.message ?? 'Unable to share this post.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (error) {
      if (!mounted) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Unable to share this post: $error'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: AppColors.cardGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.share_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Share to AgriAI',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Send this post to another farmer',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search by @User ID…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear',
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _loading && _users.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : _users.isEmpty
                      ? Center(
                          child: Text(
                            _query.isEmpty
                                ? 'No farmers available yet.'
                                : 'No AgriAI User ID found for “$_query”.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(18, 2, 18, 20),
                          itemCount: _users.length,
                          separatorBuilder:
                              (BuildContext context, int index) =>
                                  const SizedBox(height: 8),
                          itemBuilder:
                              (BuildContext context, int index) {
                            final _ShareUser user = _users[index];

                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: _loading
                                    ? null
                                    : () => _shareWithUser(user),
                                child: Container(
                                  padding: const EdgeInsets.all(11),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius:
                                        BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppColors.border,
                                    ),
                                  ),
                                  child: Row(
                                    children: <Widget>[
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor:
                                            AppColors.cardGreen,
                                        backgroundImage:
                                            user.photoUrl.isEmpty
                                                ? null
                                                : NetworkImage(
                                                    user.photoUrl,
                                                  ),
                                        child: user.photoUrl.isEmpty
                                            ? const Icon(
                                                Icons.person_rounded,
                                                color:
                                                    AppColors.primary,
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 11),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Text(
                                              user.displayName,
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '@${user.userId}',
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 9.5,
                                                color:
                                                    AppColors.primary,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            if (user.location.isNotEmpty)
                                              Padding(
                                                padding:
                                                    const EdgeInsets.only(
                                                  top: 2,
                                                ),
                                                child: Text(
                                                  user.location,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 8,
                                                    color:
                                                        AppColors.textMuted,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 11,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            Icon(
                                              Icons.send_rounded,
                                              size: 13,
                                              color: Colors.white,
                                            ),
                                            SizedBox(width: 5),
                                            Text(
                                              'Share',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
                                              ),
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
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareUser {
  final String uid;
  final String userId;
  final String displayName;
  final String photoUrl;
  final String location;

  const _ShareUser({
    required this.uid,
    required this.userId,
    required this.displayName,
    required this.photoUrl,
    required this.location,
  });
}

// ============================================================================
// COMMENTS SHEET
// ============================================================================


class _CommentsSheet extends StatefulWidget {
  final String postId;

  const _CommentsSheet({
    required this.postId,
  });

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _commentController =
      TextEditingController();

  bool _loading = true;
  bool _posting = false;
  List<CommunityCommentData> _comments =
      <CommunityCommentData>[];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    unawaited(_loadComments());
  }

  Future<void> _loadComments() async {
    try {
      final List<CommunityCommentData> comments =
          await CommunityCommentsService.getComments(
        postId: widget.postId,
        limit: 100,
      );

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
            content: Text(
              'Unable to load comments: $error',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  Future<void> _postComment() async {
    if (_posting) {
      return;
    }

    final String text =
        _commentController.text.trim();

    if (text.isEmpty) {
      return;
    }

    setState(() {
      _posting = true;
    });

    try {
      await CommunityCommentsService.createComment(
        postId: widget.postId,
        text: text,
      );

      _commentController.clear();

      final List<CommunityCommentData> comments =
          await CommunityCommentsService.getComments(
        postId: widget.postId,
        limit: 100,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _comments = comments;
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
            content: Text(
              'Unable to post comment: $error',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  String _formatTime(DateTime? createdAt) {
    if (createdAt == null) {
      return 'Just now';
    }

    final Duration difference =
        DateTime.now().difference(createdAt);

    if (difference.isNegative ||
        difference.inMinutes < 1) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays}d';
    }

    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height:
            MediaQuery.of(context).size.height * 0.72,
        child: Column(
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                4,
                18,
                12,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Comments',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                      ),
                    )
                  : _comments.isEmpty
                      ? const Center(
                          child: Text(
                            'No comments yet.\nBe the first to comment.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
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
                          itemCount: _comments.length,
                          separatorBuilder:
                              (
                            BuildContext context,
                            int index,
                          ) =>
                                  const SizedBox(height: 12),
                          itemBuilder:
                              (
                            BuildContext context,
                            int index,
                          ) {
                            final CommunityCommentData comment =
                                _comments[index];

                            return Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: <Widget>[
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor:
                                      AppColors.cardGreen,
                                  backgroundImage:
                                      comment.photoUrl.isEmpty
                                          ? null
                                          : NetworkImage(
                                              comment.photoUrl,
                                            ),
                                  child: comment.photoUrl.isEmpty
                                      ? const Icon(
                                          Icons.person_rounded,
                                          color:
                                              AppColors.primary,
                                          size: 21,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Container(
                                    padding:
                                        const EdgeInsets.fromLTRB(
                                      12,
                                      9,
                                      12,
                                      10,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.background,
                                      borderRadius:
                                          BorderRadius.circular(
                                        14,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Row(
                                          children: <Widget>[
                                            Expanded(
                                              child: Text(
                                                comment.displayName,
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style:
                                                    const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight:
                                                      FontWeight.w900,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              _formatTime(
                                                comment.createdAt,
                                              ),
                                              style:
                                                  const TextStyle(
                                                fontSize: 8,
                                                color:
                                                    AppColors.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (comment.userId.isNotEmpty)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(
                                              top: 2,
                                            ),
                                            child: Text(
                                              '@${comment.userId}',
                                              style:
                                                  const TextStyle(
                                                fontSize: 8,
                                                color:
                                                    AppColors.textMuted,
                                                fontWeight:
                                                    FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        const SizedBox(height: 5),
                                        Text(
                                          comment.text,
                                          style:
                                              const TextStyle(
                                            fontSize: 10.5,
                                            height: 1.35,
                                            color:
                                                AppColors.textPrimary,
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
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.of(context).viewInsets.bottom + 10,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      minLines: 1,
                      maxLines: 3,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _postComment(),
                      decoration: InputDecoration(
                        hintText: 'Write a comment…',
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  IconButton(
                    tooltip: 'Post comment',
                    onPressed: _posting
                        ? null
                        : _postComment,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    icon: _posting
                        ? const SizedBox(
                            width: 19,
                            height: 19,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            size: 19,
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
}

// NEWS CARD
// ============================================================================

class _NewsCard
    extends StatelessWidget {
  final AgriNewsItem item;
  final VoidCallback onTap;

  const _NewsCard({
    required this.item,
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
          16,
        ),
        child:
            Container(
          padding:
              const EdgeInsets.all(
            14,
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
              Container(
                width:
                    42,
                height:
                    42,
                decoration:
                    const BoxDecoration(
                  color:
                      AppColors.cardGreen,
                  shape:
                      BoxShape.circle,
                ),
                child:
                    const Icon(
                  Icons
                      .newspaper_outlined,
                  color:
                      AppColors.primary,
                ),
              ),
              const SizedBox(
                width:
                    10,
              ),
              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children:
                      <Widget>[
                    Text(
                      item.title,
                      maxLines:
                          2,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        fontSize:
                            11,
                        fontWeight:
                            FontWeight.w800,
                        height:
                            1.3,
                      ),
                    ),
                    const SizedBox(
                      height:
                          5,
                    ),
                    Text(
                      '${item.source} • ${_formatNewsDate(item.date)}',
                      style:
                          const TextStyle(
                        fontSize:
                            8.5,
                        color:
                            AppColors
                                .textMuted,
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

  String _formatNewsDate(
    DateTime date,
  ) {
    return '${date.day}/${date.month}';
  }
}

// ============================================================================
// EMPTY STATES
// ============================================================================

class _EmptyNews
    extends StatelessWidget {
  const _EmptyNews();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(
        18,
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
          const Center(
        child:
            Text(
          'Live agriculture news is temporarily unavailable.',
          textAlign:
              TextAlign.center,
          style:
              TextStyle(
            fontSize:
                10,
            color:
                AppColors
                    .textSecondary,
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _EmptyPosts
    extends StatelessWidget {
  const _EmptyPosts();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(
        20,
      ),
      decoration:
          BoxDecoration(
        color:
            AppColors.surface,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        border:
            Border.all(
          color:
              AppColors.border,
        ),
      ),
      child:
          const Column(
        children:
            <Widget>[
          Icon(
            Icons
                .forum_outlined,
            color:
                AppColors
                    .primary,
            size:
                36,
          ),
          SizedBox(
            height:
                8,
          ),
          Text(
            'No community posts yet.',
            style:
                TextStyle(
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// FLOATING BUTTONS
// ============================================================================

class _FloatingButtons
    extends StatelessWidget {
  final VoidCallback onDm;
  final VoidCallback onNews;
  final VoidCallback onAssistant;

  const _FloatingButtons({
    required this.onDm,
    required this.onNews,
    required this.onAssistant,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      mainAxisSize:
          MainAxisSize.min,
      crossAxisAlignment:
          CrossAxisAlignment.end,
      children:
          <Widget>[
        _HomeQuickAction(
          heroTag: 'agri_dm',
          icon: Icons.forum_rounded,
          label: 'DM',
          onTap: onDm,
        ),
        const SizedBox(height: 8),
        _HomeQuickAction(
          heroTag: 'agri_ai',
          icon: Icons.auto_awesome_rounded,
          label: 'AgriAI',
          onTap: onAssistant,
          filled: true,
        ),
        const SizedBox(height: 8),
        _HomeQuickAction(
          heroTag: 'agri_news',
          icon: Icons.newspaper_rounded,
          label: 'News',
          onTap: onNews,
        ),
      ],
    );
  }
}

class _HomeQuickAction extends StatelessWidget {
  final String heroTag;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  const _HomeQuickAction({
    required this.heroTag,
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 118,
      height: 48,
      child: FloatingActionButton.extended(
        heroTag: heroTag,
        onPressed: onTap,
        elevation: 5,
        backgroundColor:
            filled ? AppColors.primary : AppColors.surface,
        foregroundColor:
            filled ? Colors.white : AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: filled
              ? BorderSide.none
              : const BorderSide(
                  color: AppColors.border,
                ),
        ),
        icon: Icon(
          icon,
          size: 19,
        ),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// ASSISTANT SHEET
// ============================================================================

class _AssistantSheet
    extends StatelessWidget {
  final List<ChatMessage> messages;
  final TextEditingController controller;
  final ScrollController scrollController;
  final bool busy;
  final bool listening;
  final VoidCallback onClose;
  final VoidCallback onVoice;
  final VoidCallback onSend;

  const _AssistantSheet({
    required this.messages,
    required this.controller,
    required this.scrollController,
    required this.busy,
    required this.listening,
    required this.onClose,
    required this.onVoice,
    required this.onSend,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color:
          Theme.of(context)
              .colorScheme
              .surface,
      child:
          SafeArea(
        top:
            false,
        child:
            SizedBox(
          height:
              MediaQuery.of(context)
                      .size
                      .height *
                  0.68,
          child:
              Column(
            children:
                <Widget>[
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  16,
                  10,
                  8,
                  8,
                ),
                child:
                    Row(
                  children:
                      <Widget>[
                    Container(
                      width:
                          38,
                      height:
                          38,
                      decoration:
                          const BoxDecoration(
                        color:
                            AppColors
                                .cardGreen,
                        shape:
                            BoxShape.circle,
                      ),
                      child:
                          const Icon(
                        Icons
                            .auto_awesome_rounded,
                        color:
                            AppColors
                                .primary,
                      ),
                    ),
                    const SizedBox(
                      width:
                          10,
                    ),
                    const Expanded(
                      child:
                          Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children:
                            <Widget>[
                          Text(
                            'AgriAI Assistant',
                            style:
                                TextStyle(
                              fontSize:
                                  17,
                              fontWeight:
                                  FontWeight.w900,
                            ),
                          ),
                          Text(
                            'Your agriculture companion',
                            style:
                                TextStyle(
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
                    IconButton(
                      onPressed:
                          onClose,
                      icon:
                          const Icon(
                        Icons
                            .close_rounded,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child:
                    ListView.builder(
                  controller:
                      scrollController,
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal:
                        14,
                  ),
                  itemCount:
                      messages.length,
                  itemBuilder:
                      (
                    BuildContext context,
                    int index,
                  ) {
                    final ChatMessage
                        message =
                        messages[index];

                    return Align(
                      alignment:
                          message.isUser
                              ? Alignment
                                  .centerRight
                              : Alignment
                                  .centerLeft,
                      child:
                          Container(
                        constraints:
                            const BoxConstraints(
                          maxWidth:
                              320,
                        ),
                        margin:
                            const EdgeInsets.only(
                          bottom:
                              8,
                        ),
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal:
                              12,
                          vertical:
                              9,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              message.isUser
                                  ? AppColors
                                      .primary
                                  : AppColors
                                      .cardGreen,
                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                        ),
                        child:
                            Text(
                          message.text,
                          style:
                              TextStyle(
                            fontSize:
                                10.5,
                            height:
                                1.35,
                            color:
                                message.isUser
                                    ? Colors.white
                                    : AppColors
                                        .textPrimary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (busy)
                const Padding(
                  padding:
                      EdgeInsets.symmetric(
                    horizontal:
                        16,
                    vertical:
                        4,
                  ),
                  child:
                      Align(
                    alignment:
                        Alignment.centerLeft,
                    child:
                        Text(
                      'AgriAI is thinking…',
                      style:
                          TextStyle(
                        fontSize:
                            9,
                        color:
                            AppColors
                                .textSecondary,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  12,
                  6,
                  12,
                  10,
                ),
                child:
                    Row(
                  children:
                      <Widget>[
                    IconButton(
                      tooltip:
                          'Voice input',
                      onPressed:
                          onVoice,
                      icon:
                          Icon(
                        listening
                            ? Icons
                                .mic_rounded
                            : Icons
                                .mic_none_rounded,
                        color:
                            listening
                                ? AppColors
                                    .primary
                                : AppColors
                                    .textSecondary,
                      ),
                    ),
                    Expanded(
                      child:
                          TextField(
                        controller:
                            controller,
                        minLines:
                            1,
                        maxLines:
                            3,
                        textInputAction:
                            TextInputAction.send,
                        onSubmitted:
                            (_) =>
                                onSend(),
                        decoration:
                            InputDecoration(
                          hintText:
                              'Ask AgriAI…',
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
                          6,
                    ),
                    IconButton(
                      tooltip:
                          'Send',
                      onPressed:
                          busy
                              ? null
                              : onSend,
                      style:
                          IconButton.styleFrom(
                        backgroundColor:
                            AppColors
                                .primary,
                        foregroundColor:
                            Colors.white,
                      ),
                      icon:
                          const Icon(
                        Icons
                            .arrow_upward_rounded,
                        size:
                            20,
                      ),
                    ),
                  ],
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
// DATA MODELS
// ============================================================================

class WeatherSnapshot {
  final double temperature;
  final double feelsLike;
  final double humidity;
  final double wind;
  final int code;

  const WeatherSnapshot({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.wind,
    required this.code,
  });
}

class AgriNewsItem {
  final String title;
  final String link;
  final String source;
  final DateTime date;

  const AgriNewsItem({
    required this.title,
    required this.link,
    required this.source,
    required this.date,
  });
}

class CommunityPost {
  final String id;
  final String uid;
  final String userId;
  final String author;
  final String text;
  final String time;
  final int likes;
  final int comments;
  final String? mediaPath;
  final String? mediaType;
  final String? mediaUrl;
  final DateTime? createdAt;

  const CommunityPost({
    this.id = '',
    this.uid = '',
    this.userId = '',
    required this.author,
    required this.text,
    required this.time,
    required this.likes,
    required this.comments,
    this.mediaPath,
    this.mediaType,
    this.mediaUrl,
    this.createdAt,
  });
}

class CommunityVideo {
  final String author;
  final String title;
  final String duration;
  final String? path;
  final String? cloudinaryUrl;
  final String? publicId;

  const CommunityVideo({
    required this.author,
    required this.title,
    required this.duration,
    this.path,
    this.cloudinaryUrl,
    this.publicId,
  });
}

class ChatMessage {
  final bool isUser;
  final String text;

  const ChatMessage({
    required this.isUser,
    required this.text,
  });
}