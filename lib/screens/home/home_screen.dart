import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  final String? farmerName;
  final VoidCallback? onYieldPrediction;
  final VoidCallback? onDiseaseDetection;
  final VoidCallback? onSoilAnalysis;
  final VoidCallback? onWeather;
  final VoidCallback? onRecommendations;
  final VoidCallback? onProfile;
  final VoidCallback? onCropHistory;

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
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  WeatherSnapshot? _weather;
  bool _weatherLoading = true;
  String _locationName = 'Getting your location…';
  double? _gpsAccuracy;

  final ImagePicker _picker = ImagePicker();
  final TextEditingController _postController = TextEditingController();

  final List<CommunityPost> _posts = <CommunityPost>[
    const CommunityPost(
      author: 'AgriAI Farmer',
      text: 'Share your farming experience, crop tips, ideas and suggestions with the AgriAI community.',
      time: 'Just now',
      likes: 12,
      comments: 3,
    ),
    const CommunityPost(
      author: 'Farmer Community',
      text: 'What crop management practice has helped your farm the most this season?',
      time: 'Today',
      likes: 28,
      comments: 7,
    ),
  ];

  final List<CommunityVideo> _videos = <CommunityVideo>[
    const CommunityVideo(
      author: 'AgriAI Community',
      title: 'Share a useful farming video with other farmers',
      duration: 'Up to 2 min',
    ),
  ];

  List<AgriNewsItem> _news = <AgriNewsItem>[];
  bool _newsLoading = true;
  String _newsRegion = 'India';

  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final List<ChatMessage> _messages = <ChatMessage>[
    const ChatMessage(
      isUser: false,
      text: 'Namaste! Ask me about crops, soil, fertilizer, irrigation, pests or weather.',
    ),
  ];

  bool _assistantOpen = false;
  bool _listening = false;
  bool _speechAvailable = false;
  bool _assistantBusy = false;
  bool _ttsReady = false;
  String _speechLocaleId = 'en-IN';

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
    unawaited(_initializeSpeech());
    unawaited(_initializeTts());
    unawaited(_loadLocationAndWeather());
    unawaited(_loadNews());
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

  String get _greeting {
    if (_now.hour >= 5 && _now.hour < 12) return 'Good Morning';
    if (_now.hour >= 12 && _now.hour < 17) return 'Good Afternoon';
    if (_now.hour >= 17 && _now.hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  String get _name {
    final String value = widget.farmerName?.trim() ?? '';
    return value.isEmpty ? 'Farmer' : value;
  }

  String get _clock {
    final int hour = _now.hour % 12 == 0 ? 12 : _now.hour % 12;
    final String minute = _now.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${_now.hour >= 12 ? 'PM' : 'AM'}';
  }

  Future<void> _initializeTts() async {
    try {
      await _tts.setSpeechRate(0.48);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      await _tts.setLanguage(_speechLocaleId);
      if (mounted) {
        setState(() {
          _ttsReady = true;
        });
      }
    } catch (_) {}
  }

  Future<void> _initializeSpeech() async {
    try {
      final bool available = await _speech.initialize(
        onStatus: (String status) {
          if (mounted) {
            setState(() {
              _listening = status == 'listening';
            });
          }
        },
        onError: (_) {
          if (mounted) {
            setState(() {
              _listening = false;
            });
          }
        },
      );

      if (!mounted) return;
      setState(() {
        _speechAvailable = available;
      });

      if (!available) return;

      final List<stt.LocaleName> locales = await _speech.locales();
      for (final stt.LocaleName locale in locales) {
        if (locale.localeId.toLowerCase().startsWith('en-in')) {
          _speechLocaleId = locale.localeId;
          break;
        }
      }

      try {
        await _tts.setLanguage(_speechLocaleId);
      } catch (_) {}
    } catch (_) {
      if (mounted) {
        setState(() {
          _speechAvailable = false;
        });
      }
    }
  }

  Future<bool> _locationReady() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission != LocationPermission.denied &&
        permission != LocationPermission.deniedForever;
  }

  Future<void> _loadLocationAndWeather() async {
    if (mounted) {
      setState(() {
        _weatherLoading = true;
      });
    }

    try {
      if (!await _locationReady()) {
        throw Exception('Location unavailable');
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 25));

      await _loadWeather(
        position.latitude,
        position.longitude,
        position.accuracy,
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _weatherLoading = false;
          _locationName = 'Location unavailable';
        });
      }
    }
  }

  Future<void> _loadWeather(
    double latitude,
    double longitude,
    double accuracy,
  ) async {
    final Uri uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$latitude'
      '&longitude=$longitude'
      '&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m'
      '&timezone=auto',
    );

    try {
      final http.Response response = await http
          .get(uri)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Weather request failed');
      }

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      final Map<String, dynamic> current =
          (data['current'] as Map<String, dynamic>?) ?? <String, dynamic>{};

      if (!mounted) return;

      setState(() {
        _weather = WeatherSnapshot(
          temperature: _toDouble(current['temperature_2m']),
          feelsLike: _toDouble(current['apparent_temperature']),
          humidity: _toDouble(current['relative_humidity_2m']),
          wind: _toDouble(current['wind_speed_10m']),
          code: _toInt(current['weather_code']),
        );
        _gpsAccuracy = accuracy;
        _locationName = 'Current GPS location';
        _weatherLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _weatherLoading = false;
        });
      }
    }
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  String _weatherText(int code) {
    if (code == 0) return 'Clear sky';
    if (code <= 3) return 'Cloudy';
    if (code <= 48) return 'Fog';
    if (code <= 57) return 'Drizzle';
    if (code <= 67) return 'Rain';
    if (code <= 77) return 'Snow';
    if (code <= 86) return 'Rain showers';
    return 'Thunderstorm';
  }

  IconData _weatherIcon(int code) {
    if (code == 0) return Icons.wb_sunny_rounded;
    if (code <= 3) return Icons.cloud_rounded;
    if (code <= 67) return Icons.water_drop_rounded;
    if (code <= 77) return Icons.ac_unit_rounded;
    return Icons.thunderstorm_rounded;
  }

  Future<void> _loadNews() async {
    if (mounted) {
      setState(() {
        _newsLoading = true;
      });
    }

    try {
      final String query = _newsRegion == 'India'
          ? 'agriculture India farming government schemes mandi crop prices'
          : 'global agriculture farming food security crop prices';

      final Uri uri = Uri.parse(
        'https://news.google.com/rss/search'
        '?q=${Uri.encodeComponent(query)}'
        '&hl=en-IN&gl=IN&ceid=IN:en',
      );

      final http.Response response = await http
          .get(uri)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('News request failed');
      }

      final List<AgriNewsItem> parsed = _parseNews(response.body);
      if (mounted) {
        setState(() {
          _news = parsed;
          _newsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _newsLoading = false;
        });
      }
    }
  }

  List<AgriNewsItem> _parseNews(String xml) {
    final List<AgriNewsItem> items = <AgriNewsItem>[];
    final RegExp itemRegex = RegExp(
      r'<item>(.*?)</item>',
      dotAll: true,
      caseSensitive: false,
    );

    for (final Match match in itemRegex.allMatches(xml)) {
      final String block = match.group(1) ?? '';
      final String title = _xml(block, 'title');
      final String link = _xml(block, 'link');
      final String source = _xml(block, 'source');
      final String date = _xml(block, 'pubDate');

      if (title.isEmpty || link.isEmpty) continue;

      items.add(
        AgriNewsItem(
          title: _clean(title),
          link: link.trim(),
          source: source.isEmpty ? 'Google News' : _clean(source),
          date: DateTime.tryParse(date) ?? DateTime.now(),
        ),
      );

      if (items.length == 6) break;
    }

    return items;
  }

  String _xml(String block, String tag) {
    final RegExp regex = RegExp(
      '<$tag(?:\\s[^>]*)?>(.*?)</$tag>',
      dotAll: true,
      caseSensitive: false,
    );
    return regex.firstMatch(block)?.group(1)?.trim() ?? '';
  }

  String _clean(String text) {
    return text
        .replaceAll(RegExp(r'<!\[CDATA\['), '')
        .replaceAll(']]>', '')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .trim();
  }

  Future<void> _openNews(AgriNewsItem item) async {
    final Uri? uri = Uri.tryParse(item.link);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _createPost() async {
    _postController.clear();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            4,
            18,
            MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Create a community post',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'Share a note, idea, suggestion, feedback or farming tip.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _postController,
                maxLines: 5,
                maxLength: 1000,
                decoration: const InputDecoration(
                  hintText: 'Write something for farmers…',
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: () => _addPhotoPost(sheetContext),
                    icon: const Icon(Icons.photo_outlined),
                    label: const Text('Photo'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _addVideoPost(sheetContext),
                    icon: const Icon(Icons.videocam_outlined),
                    label: const Text('Video'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => _publishTextPost(sheetContext),
                    child: const Text('Post'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _publishTextPost(BuildContext sheetContext) {
    final String text = _postController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _posts.insert(
        0,
        CommunityPost(
          author: _name,
          text: text,
          time: 'Just now',
          likes: 0,
          comments: 0,
        ),
      );
    });

    Navigator.of(sheetContext).pop();
  }

  Future<void> _addPhotoPost(BuildContext sheetContext) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (file == null) return;

      final String text = _postController.text.trim();
      setState(() {
        _posts.insert(
          0,
          CommunityPost(
            author: _name,
            text: text.isEmpty
                ? 'Shared a farm photo with the community.'
                : text,
            time: 'Just now',
            likes: 0,
            comments: 0,
            mediaPath: file.path,
            mediaType: 'photo',
          ),
        );
      });

      if (sheetContext.mounted) {
        Navigator.of(sheetContext).pop();
      }
    } catch (_) {
      if (sheetContext.mounted) {
        ScaffoldMessenger.of(sheetContext).showSnackBar(
          const SnackBar(content: Text('Unable to select the photo.')),
        );
      }
    }
  }

  Future<void> _addVideoPost(BuildContext sheetContext) async {
    try {
      final XFile? file = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 2),
      );
      if (file == null) return;

      final String title = _postController.text.trim();
      setState(() {
        _videos.insert(
          0,
          CommunityVideo(
            author: _name,
            title: title.isEmpty ? 'Shared a farming video.' : title,
            duration: 'Up to 2 min',
            path: file.path,
          ),
        );
      });

      if (sheetContext.mounted) {
        Navigator.of(sheetContext).pop();
      }
    } catch (_) {
      if (sheetContext.mounted) {
        ScaffoldMessenger.of(sheetContext).showSnackBar(
          const SnackBar(content: Text('Unable to select the video.')),
        );
      }
    }
  }

  void _openNewsPanel() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.88,
          child: Column(
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 0, 18, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Agriculture News',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: SegmentedButton<String>(
                  segments: const <ButtonSegment<String>>[
                    ButtonSegment<String>(
                      value: 'India',
                      label: Text('India'),
                      icon: Icon(Icons.location_on_outlined),
                    ),
                    ButtonSegment<String>(
                      value: 'Global',
                      label: Text('Global'),
                      icon: Icon(Icons.public_rounded),
                    ),
                  ],
                  selected: <String>{_newsRegion},
                  onSelectionChanged: (Set<String> value) {
                    if (value.isEmpty) return;
                    setState(() {
                      _newsRegion = value.first;
                    });
                    unawaited(_loadNews());
                  },
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _newsLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _news.isEmpty
                        ? const Center(
                            child: Text('No current agriculture news available.'),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(18),
                            itemCount: _news.length,
                            separatorBuilder: (_, int index) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, int index) {
                              final AgriNewsItem item = _news[index];
                              return _NewsCard(
                                item: item,
                                onTap: () => _openNews(item),
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

  void _openAssistant() {
    setState(() {
      _assistantOpen = true;
    });
  }

  Future<void> _toggleListening() async {
    if (!_speechAvailable) {
      await _initializeSpeech();
      if (!_speechAvailable) {
        _showMessage('Speech recognition is not available.');
        return;
      }
    }

    if (_listening) {
      await _speech.stop();
      if (mounted) {
        setState(() {
          _listening = false;
        });
      }
      return;
    }

    final stt.SpeechListenOptions options = stt.SpeechListenOptions(
      localeId: _speechLocaleId,
      partialResults: true,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 4),
      cancelOnError: true,
      listenMode: stt.ListenMode.confirmation,
    );

    await _speech.listen(
      onResult: _onSpeechResult,
      listenOptions: options,
    );

    if (mounted) {
      setState(() {
        _listening = true;
      });
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (!mounted || result.recognizedWords.trim().isEmpty) return;

    setState(() {
      _chatController.text = result.recognizedWords;
    });
    _chatController.selection = TextSelection.fromPosition(
      TextPosition(offset: _chatController.text.length),
    );

    if (result.finalResult) {
      unawaited(_sendMessage());
    }
  }

  Future<void> _sendMessage() async {
    final String question = _chatController.text.trim();
    if (question.isEmpty || _assistantBusy) return;

    await _speech.stop();
    if (!mounted) return;

    setState(() {
      _messages.add(ChatMessage(isUser: true, text: question));
      _chatController.clear();
      _assistantBusy = true;
      _listening = false;
    });
    _scrollChat();

    await Future<void>.delayed(const Duration(milliseconds: 350));
    final String answer = _assistantReply(question);

    if (!mounted) return;

    setState(() {
      _messages.add(ChatMessage(isUser: false, text: answer));
      _assistantBusy = false;
    });
    _scrollChat();

    try {
      if (!_ttsReady) await _initializeTts();
      await _tts.stop();
      await _tts.speak(answer);
    } catch (_) {}
  }

  String _assistantReply(String question) {
    final String q = question.toLowerCase();
    final String weather = _weather == null
        ? ''
        : ' Current temperature is ${_weather!.temperature.round()}°C with '
            '${_weatherText(_weather!.code).toLowerCase()} and '
            '${_weather!.humidity.round()}% humidity.';

    if (q.contains('fertilizer') ||
        q.contains('fertiliser') ||
        q.contains('urea') ||
        q.contains('npk')) {
      return 'Use soil-test results, crop type and growth stage before selecting fertilizer. Avoid applying nutrients blindly.$weather';
    }

    if (q.contains('irrigation') || q.contains('water')) {
      return 'Irrigation should consider soil moisture, crop stage and recent rainfall. Avoid unnecessary watering when soil moisture is already adequate.$weather';
    }

    if (q.contains('disease') || q.contains('pest') || q.contains('leaf')) {
      return 'Check the crop, affected plant part and visible symptoms. You can use Disease Detection for image-based assessment.$weather';
    }

    if (q.contains('weather') ||
        q.contains('temperature') ||
        q.contains('rain')) {
      if (_weather == null) {
        return 'Live weather is not available right now. Refresh the Home screen and allow GPS access.';
      }
      return 'Current weather: ${_weather!.temperature.round()}°C, ${_weatherText(_weather!.code)}, humidity ${_weather!.humidity.round()}%, wind ${_weather!.wind.round()} km/h.';
    }

    if (q.contains('price') ||
        q.contains('mandi') ||
        q.contains('market')) {
      return 'Agricultural prices change frequently. Check the latest official market or mandi data for your crop and market before selling.';
    }

    if (q.contains('soil') || q.contains('ph')) {
      return 'A current soil test is the best basis for fertilizer and soil-management decisions. Consider pH, organic matter and available nutrients.';
    }

    return 'I can help with crops, soil, fertilizer, irrigation, pests, disease, weather and farming practices. Ask me a specific agriculture question.';
  }

  void _scrollChat() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await _loadLocationAndWeather();
            await _loadNews();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(<Widget>[
                    _Header(
                      greeting: _greeting,
                      name: _name,
                      clock: _clock,
                      onProfile: widget.onProfile,
                    ),
                    const SizedBox(height: 14),
                    _CompactWeather(
                      weather: _weather,
                      loading: _weatherLoading,
                      location: _locationName,
                      accuracy: _gpsAccuracy,
                      description: _weather == null
                          ? 'Loading live weather…'
                          : _weatherText(_weather!.code),
                      icon: _weatherIcon(_weather?.code ?? 0),
                      onRefresh: _loadLocationAndWeather,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: <Widget>[
                        const Expanded(child: _Title('Agri Community')),
                        FilledButton.icon(
                          onPressed: _createPost,
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Create Post'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Ideas • tips • suggestions • feedback',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._posts.map(
                      (CommunityPost post) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _PostCard(post: post),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        const Expanded(child: _Title('Farmer Videos')),
                        TextButton(
                          onPressed: _createPost,
                          child: const Text('Add Video'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 205,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _videos.length,
                        separatorBuilder: (_, int index) =>
                            const SizedBox(width: 12),
                        itemBuilder: (_, int index) =>
                            _VideoCard(video: _videos[index]),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: <Widget>[
                        const Expanded(child: _Title('Agriculture News')),
                        TextButton(
                          onPressed: _openNewsPanel,
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_newsLoading)
                      const SizedBox(
                        height: 100,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else if (_news.isEmpty)
                      const _EmptyNews()
                    else
                      ..._news.take(3).map(
                        (AgriNewsItem item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _NewsCard(
                            item: item,
                            onTap: () => _openNews(item),
                          ),
                        ),
                      ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _assistantOpen
          ? null
          : _FloatingButtons(
              onNews: _openNewsPanel,
              onAssistant: _openAssistant,
            ),
      bottomSheet: _assistantOpen
          ? _AssistantSheet(
              messages: _messages,
              controller: _chatController,
              scrollController: _chatScrollController,
              busy: _assistantBusy,
              listening: _listening,
              onClose: () {
                setState(() {
                  _assistantOpen = false;
                });
              },
              onVoice: _toggleListening,
              onSend: _sendMessage,
            )
          : null,
    );
  }
}

class _Header extends StatelessWidget {
  final String greeting;
  final String name;
  final String clock;
  final VoidCallback? onProfile;

  const _Header({
    required this.greeting,
    required this.name,
    required this.clock,
    this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '$greeting,',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$name 👋',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.cardGreen,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            children: <Widget>[
              const Icon(
                Icons.schedule_rounded,
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
              Text(
                clock,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: onProfile,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: AppColors.cardGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }
}

class _CompactWeather extends StatelessWidget {
  final WeatherSnapshot? weather;
  final bool loading;
  final String location;
  final double? accuracy;
  final String description;
  final IconData icon;
  final Future<void> Function() onRefresh;

  const _CompactWeather({
    required this.weather,
    required this.loading,
    required this.location,
    required this.accuracy,
    required this.description,
    required this.icon,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.cardGreen,
              borderRadius: BorderRadius.circular(13),
            ),
            child: loading
                ? const Padding(
                    padding: EdgeInsets.all(11),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  weather == null
                      ? '--°C'
                      : '${weather!.temperature.round()}°C',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$location${accuracy == null ? '' : ' • ±${accuracy!.round()}m'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 8,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (weather != null) ...<Widget>[
            Text(
              '${weather!.humidity.round()}%',
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 9),
            Text(
              '${weather!.wind.round()} km/h',
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
            ),
          ],
          IconButton(
            onPressed: loading ? null : () => unawaited(onRefresh()),
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _Title extends StatelessWidget {
  final String text;

  const _Title(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w900,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final CommunityPost post;

  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: AppColors.cardGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      post.author,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      post.time,
                      style: const TextStyle(
                        fontSize: 8,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.more_horiz_rounded,
                size: 19,
                color: AppColors.textMuted,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            post.text,
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.4,
              color: AppColors.textPrimary,
            ),
          ),
          if (post.mediaPath != null && post.mediaType == 'photo')
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Image.file(
                  File(post.mediaPath!),
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, Object error, StackTrace? stackTrace) {
                    return Container(
                      height: 180,
                      color: AppColors.cardGreen,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        color: AppColors.primary,
                        size: 40,
                      ),
                    );
                  },
                ),
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              const Icon(
                Icons.favorite_border_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                '${post.likes}',
                style: const TextStyle(
                  fontSize: 9,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 18),
              const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 17,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                '${post.comments}',
                style: const TextStyle(
                  fontSize: 9,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.share_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  final CommunityVideo video;

  const _VideoCard({required this.video});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 255,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.cardGreen,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Center(
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            video.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: <Widget>[
              const Icon(
                Icons.person_outline_rounded,
                size: 13,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  video.author,
                  style: const TextStyle(
                    fontSize: 8.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                video.duration,
                style: const TextStyle(
                  fontSize: 8.5,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final AgriNewsItem item;
  final VoidCallback onTap;

  const _NewsCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.cardGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.newspaper_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.source,
                      style: const TextStyle(
                        fontSize: 8.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.3,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Open original source ↗',
                      style: TextStyle(
                        fontSize: 8.5,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
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

class _EmptyNews extends StatelessWidget {
  const _EmptyNews();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(
        child: Text(
          'Live agriculture news is temporarily unavailable.',
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _FloatingButtons extends StatelessWidget {
  final VoidCallback onNews;
  final VoidCallback onAssistant;

  const _FloatingButtons({
    required this.onNews,
    required this.onAssistant,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FloatingActionButton.small(
          heroTag: 'agri_news',
          onPressed: onNews,
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.primary,
          child: const Icon(Icons.newspaper_outlined),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.extended(
          heroTag: 'agri_ai',
          onPressed: onAssistant,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.auto_awesome_rounded),
          label: const Text(
            'AgriAI Assistant',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _AssistantSheet extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.68,
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 8, 8),
                child: Row(
                  children: <Widget>[
                    const Expanded(
                      child: Text(
                        'AgriAI Assistant',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onClose,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: messages.length,
                  itemBuilder: (_, int index) =>
                      _ChatBubble(message: messages[index]),
                ),
              ),
              if (busy)
                const Padding(
                  padding: EdgeInsets.all(6),
                  child: Text(
                    'Thinking…',
                    style: TextStyle(
                      fontSize: 9,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    IconButton(
                      onPressed: onVoice,
                      icon: Icon(
                        listening
                            ? Icons.stop_circle_outlined
                            : Icons.mic_none_rounded,
                        color: listening
                            ? AppColors.danger
                            : AppColors.primary,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        minLines: 1,
                        maxLines: 3,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => onSend(),
                        decoration: InputDecoration(
                          hintText: 'Ask an agriculture question…',
                          suffixIcon: IconButton(
                            onPressed: onSend,
                            icon: const Icon(
                              Icons.send_rounded,
                              color: AppColors.primary,
                            ),
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
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: message.isUser ? AppColors.primary : AppColors.cardGreen,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            fontSize: 10.5,
            height: 1.35,
            color: message.isUser ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

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
  final String author;
  final String text;
  final String time;
  final int likes;
  final int comments;
  final String? mediaPath;
  final String? mediaType;

  const CommunityPost({
    required this.author,
    required this.text,
    required this.time,
    required this.likes,
    required this.comments,
    this.mediaPath,
    this.mediaType,
  });
}

class CommunityVideo {
  final String author;
  final String title;
  final String duration;
  final String? path;

  const CommunityVideo({
    required this.author,
    required this.title,
    required this.duration,
    this.path,
  });
}

class ChatMessage {
  final bool isUser;
  final String text;

  const ChatMessage({required this.isUser, required this.text});
}
