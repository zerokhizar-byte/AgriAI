import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';

class YieldPredictionScreen extends StatefulWidget {
  final VoidCallback? onPredictionComplete;

  const YieldPredictionScreen({
    super.key,
    this.onPredictionComplete,
  });

  @override
  State<YieldPredictionScreen> createState() =>
      _YieldPredictionScreenState();
}

class _YieldPredictionScreenState
    extends State<YieldPredictionScreen> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final TextEditingController _areaController =
      TextEditingController();

  final TextEditingController _rainfallController =
      TextEditingController();

  final TextEditingController _temperatureController =
      TextEditingController();

  final TextEditingController _humidityController =
      TextEditingController();

  final TextEditingController _fertilizerController =
      TextEditingController();

  final TextEditingController _soilPhController =
      TextEditingController(text: '6.5');

  final TextEditingController _nitrogenController =
      TextEditingController();

  final TextEditingController _phosphorusController =
      TextEditingController();

  final TextEditingController _potassiumController =
      TextEditingController();

  final TextEditingController _previousYieldController =
      TextEditingController();

  bool _isLoading = false;
  bool _showAdvanced = false;
  bool _usingGps = false;

  String _selectedState = 'Maharashtra';
  String _selectedDistrict = 'Aurangabad';
  String _selectedCrop = 'Cotton';
  String _selectedSeason = 'Kharif';
  String _selectedSoil = 'Black Soil';
  String _selectedIrrigation = 'Rainfed';

  double? _latitude;
  double? _longitude;
  double? _gpsAccuracy;

  final List<YieldHistoryRecord> _history =
      <YieldHistoryRecord>[];

  static const Map<String, List<String>> stateDistricts =
      <String, List<String>>{
    'Andhra Pradesh': <String>[
      'Guntur',
      'Krishna',
      'Kurnool',
      'Alluri Sitharama Raju',
    ],
    'Assam': <String>[
      'Kamrup',
      'Dibrugarh',
      'Nagaon',
    ],
    'Bihar': <String>[
      'Patna',
      'Muzaffarpur',
      'Gaya',
    ],
    'Gujarat': <String>[
      'Ahmedabad',
      'Rajkot',
      'Surat',
    ],
    'Haryana': <String>[
      'Hisar',
      'Karnal',
      'Rohtak',
    ],
    'Karnataka': <String>[
      'Bengaluru Urban',
      'Belagavi',
      'Dharwad',
    ],
    'Madhya Pradesh': <String>[
      'Indore',
      'Bhopal',
      'Ujjain',
    ],
    'Maharashtra': <String>[
      'Aurangabad',
      'Nagpur',
      'Nashik',
      'Pune',
    ],
    'Odisha': <String>[
      'Khordha',
      'Cuttack',
      'Sambalpur',
    ],
    'Punjab': <String>[
      'Amritsar',
      'Ludhiana',
      'Bathinda',
    ],
    'Rajasthan': <String>[
      'Jaipur',
      'Kota',
      'Sri Ganganagar',
    ],
    'Tamil Nadu': <String>[
      'Coimbatore',
      'Thanjavur',
      'Salem',
    ],
    'Telangana': <String>[
      'Hyderabad',
      'Warangal',
      'Nizamabad',
    ],
    'Uttar Pradesh': <String>[
      'Lucknow',
      'Agra',
      'Kanpur Nagar',
    ],
    'West Bengal': <String>[
      'Kolkata',
      'Bardhaman',
      'Malda',
    ],
  };

  static const Map<String, Map<String, List<String>>>
      cropDatabase =
      <String, Map<String, List<String>>>{
    'Andhra Pradesh': <String, List<String>>{
      'Guntur': <String>[
        'Chilli',
        'Cotton',
        'Rice',
        'Maize',
        'Turmeric',
      ],
      'Krishna': <String>[
        'Rice',
        'Sugarcane',
        'Maize',
        'Cotton',
      ],
      'Kurnool': <String>[
        'Groundnut',
        'Cotton',
        'Maize',
        'Sunflower',
      ],
      'Alluri Sitharama Raju': <String>[
        'Rice',
        'Maize',
        'Ragi',
        'Pulses',
      ],
    },
    'Assam': <String, List<String>>{
      'Kamrup': <String>[
        'Rice',
        'Tea',
        'Jute',
        'Mustard',
      ],
      'Dibrugarh': <String>[
        'Tea',
        'Rice',
        'Mustard',
      ],
      'Nagaon': <String>[
        'Rice',
        'Jute',
        'Mustard',
        'Sugarcane',
      ],
    },
    'Bihar': <String, List<String>>{
      'Patna': <String>[
        'Rice',
        'Wheat',
        'Maize',
        'Pulses',
      ],
      'Muzaffarpur': <String>[
        'Litchi',
        'Rice',
        'Wheat',
        'Maize',
      ],
      'Gaya': <String>[
        'Rice',
        'Wheat',
        'Pulses',
      ],
    },
    'Gujarat': <String, List<String>>{
      'Ahmedabad': <String>[
        'Cotton',
        'Wheat',
        'Groundnut',
        'Castor',
      ],
      'Rajkot': <String>[
        'Groundnut',
        'Cotton',
        'Wheat',
        'Sesame',
      ],
      'Surat': <String>[
        'Sugarcane',
        'Cotton',
        'Banana',
        'Rice',
      ],
    },
    'Haryana': <String, List<String>>{
      'Hisar': <String>[
        'Wheat',
        'Cotton',
        'Mustard',
        'Pearl Millet',
      ],
      'Karnal': <String>[
        'Rice',
        'Wheat',
        'Sugarcane',
        'Potato',
      ],
      'Rohtak': <String>[
        'Wheat',
        'Rice',
        'Bajra',
        'Mustard',
      ],
    },
    'Karnataka': <String, List<String>>{
      'Bengaluru Urban': <String>[
        'Ragi',
        'Maize',
        'Vegetables',
        'Tomato',
      ],
      'Belagavi': <String>[
        'Sugarcane',
        'Cotton',
        'Maize',
        'Soybean',
      ],
      'Dharwad': <String>[
        'Cotton',
        'Maize',
        'Soybean',
        'Groundnut',
      ],
    },
    'Madhya Pradesh': <String, List<String>>{
      'Indore': <String>[
        'Soybean',
        'Wheat',
        'Maize',
        'Chickpea',
      ],
      'Bhopal': <String>[
        'Soybean',
        'Wheat',
        'Pulses',
        'Rice',
      ],
      'Ujjain': <String>[
        'Soybean',
        'Wheat',
        'Gram',
        'Maize',
      ],
    },
    'Maharashtra': <String, List<String>>{
      'Aurangabad': <String>[
        'Cotton',
        'Soybean',
        'Jowar',
        'Bajra',
        'Maize',
        'Wheat',
        'Turmeric',
      ],
      'Nagpur': <String>[
        'Cotton',
        'Soybean',
        'Rice',
        'Orange',
        'Wheat',
      ],
      'Nashik': <String>[
        'Grapes',
        'Onion',
        'Wheat',
        'Soybean',
        'Maize',
      ],
      'Pune': <String>[
        'Sugarcane',
        'Wheat',
        'Onion',
        'Maize',
        'Soybean',
      ],
    },
    'Odisha': <String, List<String>>{
      'Khordha': <String>[
        'Rice',
        'Pulses',
        'Groundnut',
        'Vegetables',
      ],
      'Cuttack': <String>[
        'Rice',
        'Jute',
        'Pulses',
        'Sugarcane',
      ],
      'Sambalpur': <String>[
        'Rice',
        'Cotton',
        'Pulses',
      ],
    },
    'Punjab': <String, List<String>>{
      'Amritsar': <String>[
        'Wheat',
        'Rice',
        'Maize',
        'Potato',
      ],
      'Ludhiana': <String>[
        'Wheat',
        'Rice',
        'Maize',
        'Vegetables',
      ],
      'Bathinda': <String>[
        'Cotton',
        'Wheat',
        'Rice',
        'Mustard',
      ],
    },
    'Rajasthan': <String, List<String>>{
      'Jaipur': <String>[
        'Pearl Millet',
        'Mustard',
        'Wheat',
        'Gram',
      ],
      'Kota': <String>[
        'Soybean',
        'Wheat',
        'Rice',
        'Coriander',
      ],
      'Sri Ganganagar': <String>[
        'Cotton',
        'Wheat',
        'Mustard',
        'Rice',
      ],
    },
    'Tamil Nadu': <String, List<String>>{
      'Coimbatore': <String>[
        'Coconut',
        'Maize',
        'Cotton',
        'Sugarcane',
      ],
      'Thanjavur': <String>[
        'Rice',
        'Sugarcane',
        'Banana',
      ],
      'Salem': <String>[
        'Tapioca',
        'Mango',
        'Maize',
        'Groundnut',
      ],
    },
    'Telangana': <String, List<String>>{
      'Hyderabad': <String>[
        'Rice',
        'Maize',
        'Cotton',
        'Vegetables',
      ],
      'Warangal': <String>[
        'Cotton',
        'Rice',
        'Maize',
        'Chilli',
      ],
      'Nizamabad': <String>[
        'Rice',
        'Turmeric',
        'Maize',
        'Soybean',
      ],
    },
    'Uttar Pradesh': <String, List<String>>{
      'Lucknow': <String>[
        'Wheat',
        'Rice',
        'Sugarcane',
        'Potato',
      ],
      'Agra': <String>[
        'Potato',
        'Wheat',
        'Mustard',
        'Millets',
      ],
      'Kanpur Nagar': <String>[
        'Wheat',
        'Rice',
        'Pulses',
        'Potato',
      ],
    },
    'West Bengal': <String, List<String>>{
      'Kolkata': <String>[
        'Rice',
        'Vegetables',
        'Jute',
      ],
      'Bardhaman': <String>[
        'Rice',
        'Potato',
        'Jute',
        'Wheat',
      ],
      'Malda': <String>[
        'Mango',
        'Rice',
        'Jute',
      ],
    },
  };

  static const Map<String, double> baseYieldPerHectare =
      <String, double>{
    'Rice': 3200,
    'Wheat': 3100,
    'Maize': 2800,
    'Cotton': 2200,
    'Soybean': 2500,
    'Sugarcane': 70000,
    'Potato': 22000,
    'Groundnut': 1800,
    'Mustard': 1500,
    'Chilli': 1500,
    'Jowar': 1700,
    'Bajra': 1400,
    'Ragi': 1800,
    'Turmeric': 5500,
    'Onion': 18000,
    'Grapes': 20000,
    'Orange': 12000,
    'Banana': 30000,
    'Tea': 1800,
    'Jute': 2200,
    'Litchi': 9000,
    'Coconut': 9000,
    'Tapioca': 22000,
    'Mango': 10000,
    'Vegetables': 18000,
    'Pearl Millet': 1200,
    'Gram': 1300,
    'Coriander': 1000,
    'Sesame': 700,
    'Sunflower': 1300,
    'Pulses': 1300,
    'Castor': 1500,
    'Chickpea': 1300,
    'Tomato': 25000,
    'Millets': 1400,
  };

  static const Map<String, double> idealRainfall =
      <String, double>{
    'Rice': 1200,
    'Wheat': 550,
    'Maize': 700,
    'Cotton': 700,
    'Soybean': 750,
    'Sugarcane': 1500,
    'Potato': 500,
    'Groundnut': 600,
    'Mustard': 350,
    'Chilli': 700,
    'Jowar': 550,
    'Bajra': 450,
    'Ragi': 700,
    'Turmeric': 1200,
    'Onion': 650,
    'Grapes': 600,
    'Orange': 900,
    'Banana': 1200,
    'Tea': 1800,
    'Jute': 1400,
    'Coconut': 1600,
    'Mango': 900,
    'Vegetables': 700,
    'Tomato': 600,
    'Pearl Millet': 450,
    'Gram': 500,
    'Coriander': 450,
    'Sesame': 500,
    'Sunflower': 500,
    'Pulses': 600,
    'Castor': 600,
    'Chickpea': 500,
    'Millets': 500,
  };

  static const Map<String, double> idealTemperature =
      <String, double>{
    'Rice': 27,
    'Wheat': 21,
    'Maize': 25,
    'Cotton': 27,
    'Soybean': 26,
    'Sugarcane': 28,
    'Potato': 18,
    'Groundnut': 27,
    'Mustard': 20,
    'Chilli': 25,
    'Jowar': 27,
    'Bajra': 28,
    'Ragi': 24,
    'Turmeric': 26,
    'Onion': 22,
    'Grapes': 24,
    'Orange': 25,
    'Banana': 27,
    'Tea': 22,
    'Jute': 28,
    'Coconut': 28,
    'Mango': 27,
    'Vegetables': 24,
    'Tomato': 24,
    'Pearl Millet': 29,
    'Gram': 20,
    'Coriander': 20,
    'Sesame': 28,
    'Sunflower': 25,
    'Pulses': 24,
    'Castor': 27,
    'Chickpea': 20,
    'Millets': 27,
  };

  static const Map<String, double> idealHumidity =
      <String, double>{
    'Rice': 80,
    'Wheat': 60,
    'Maize': 65,
    'Cotton': 65,
    'Soybean': 70,
    'Sugarcane': 75,
    'Potato': 65,
    'Groundnut': 60,
    'Mustard': 55,
    'Chilli': 65,
    'Jowar': 55,
    'Bajra': 50,
    'Ragi': 60,
    'Turmeric': 75,
    'Onion': 60,
    'Grapes': 55,
    'Orange': 65,
    'Banana': 75,
    'Tea': 80,
    'Jute': 80,
    'Coconut': 75,
    'Mango': 65,
    'Vegetables': 65,
    'Tomato': 65,
    'Pearl Millet': 50,
    'Gram': 50,
    'Coriander': 55,
    'Sesame': 50,
    'Sunflower': 55,
    'Pulses': 60,
    'Castor': 55,
    'Chickpea': 50,
    'Millets': 55,
  };

  List<String> get availableCrops {
    final Map<String, List<String>>? stateData =
        cropDatabase[_selectedState];

    if (stateData == null) {
      return baseYieldPerHectare.keys.toList()..sort();
    }

    final List<String> districtCrops =
        stateData[_selectedDistrict] ?? <String>[];

    if (districtCrops.isNotEmpty) {
      return List<String>.from(districtCrops);
    }

    final Set<String> allCrops = <String>{};

    for (final List<String> crops in stateData.values) {
      allCrops.addAll(crops);
    }

    return allCrops.toList()..sort();
  }

  List<String> get recommendedCrops {
    final List<String> result =
        List<String>.from(availableCrops);

    result.sort(
      (String a, String b) {
        final bool aKnown =
            baseYieldPerHectare.containsKey(a);

        final bool bKnown =
            baseYieldPerHectare.containsKey(b);

        if (aKnown != bKnown) {
          return aKnown ? -1 : 1;
        }

        return a.compareTo(b);
      },
    );

    return result.take(6).toList();
  }

  @override
  void initState() {
    super.initState();

    _loadHistory();

    if (!availableCrops.contains(_selectedCrop) &&
        availableCrops.isNotEmpty) {
      _selectedCrop = availableCrops.first;
    }
  }

  @override
  void dispose() {
    _areaController.dispose();
    _rainfallController.dispose();
    _temperatureController.dispose();
    _humidityController.dispose();
    _fertilizerController.dispose();
    _soilPhController.dispose();
    _nitrogenController.dispose();
    _phosphorusController.dispose();
    _potassiumController.dispose();
    _previousYieldController.dispose();

    super.dispose();
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
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  Future<void> _loadHistory() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    final List<String> saved =
        prefs.getStringList(
              'agriai_yield_history',
            ) ??
            <String>[];

    final List<YieldHistoryRecord> records =
        <YieldHistoryRecord>[];

    for (final String item in saved) {
      try {
        final Object? decoded = jsonDecode(item);

        if (decoded is Map<String, dynamic>) {
          records.add(
            YieldHistoryRecord.fromMap(decoded),
          );
        }
      } catch (_) {}
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _history
        ..clear()
        ..addAll(records);
    });
  }

  Future<void> _saveHistory() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    await prefs.setStringList(
      'agriai_yield_history',
      _history
          .map(
            (YieldHistoryRecord record) =>
                jsonEncode(record.toMap()),
          )
          .toList(),
    );
  }

  Future<bool> _checkLocationPermission() async {
    final bool enabled =
        await Geolocator.isLocationServiceEnabled();

    if (!enabled) {
      _showMessage(
        'GPS is OFF. Turn on Location Services.',
      );

      await Geolocator.openLocationSettings();

      return false;
    }

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      _showMessage(
        'Location permission was denied.',
      );

      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      _showMessage(
        'Location permission is permanently denied. Enable it in App Settings.',
      );

      await Geolocator.openAppSettings();

      return false;
    }

    return true;
  }

  Future<Position> _getPhoneGps() async {
    // On Android, force the native Android LocationManager so the
    // phone's own GPS/location provider is used instead of relying
    // only on the fused provider.
    final LocationSettings locationSettings =
        defaultTargetPlatform == TargetPlatform.android
            ? AndroidSettings(
                accuracy: LocationAccuracy.bestForNavigation,
                distanceFilter: 0,
                forceLocationManager: true,
                intervalDuration: const Duration(seconds: 2),
              )
            : const LocationSettings(
                accuracy: LocationAccuracy.high,
                distanceFilter: 0,
              );

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      ).timeout(
        const Duration(seconds: 30),
      );
    } on TimeoutException {
      // A cached/last-known position is a useful fallback when the
      // phone is taking too long to obtain a fresh satellite fix.
      final Position? lastPosition =
          await Geolocator.getLastKnownPosition();

      if (lastPosition != null) {
        return lastPosition;
      }

      rethrow;
    }
  }

  Future<Map<String, dynamic>>
      _getAddressFromCoordinates(
    Position position,
  ) async {
    final Uri url = Uri.https(
      'nominatim.openstreetmap.org',
      '/reverse',
      <String, String>{
        'format': 'jsonv2',
        'lat': position.latitude.toString(),
        'lon': position.longitude.toString(),
        'zoom': '10',
        'addressdetails': '1',
        'accept-language': 'en',
      },
    );

    final http.Response response =
        await http.get(
      url,
      headers: const <String, String>{
        'User-Agent': 'AgriAI/1.0',
        'Accept': 'application/json',
      },
    ).timeout(
      const Duration(seconds: 15),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Reverse geocoding failed',
      );
    }

    final Object? decoded =
        jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Invalid reverse geocoding response',
      );
    }

    final Object? address = decoded['address'];

    if (address is! Map<String, dynamic>) {
      throw Exception(
        'Address not found',
      );
    }

    return address;
  }

  Future<void> _useAutomaticGps() async {
    if (_isLoading) {
      return;
    }

    // Automatic mode owns the GPS state. Clear any old coordinates
    // and immediately switch the UI to Automatic before requesting
    // the Android location permission.
    setState(() {
      _usingGps = true;
      _isLoading = true;
      _latitude = null;
      _longitude = null;
      _gpsAccuracy = null;
    });

    try {
      final bool ready =
          await _checkLocationPermission();

      if (!ready) {
        if (!mounted) {
          return;
        }

        setState(() {
          _isLoading = false;
          _usingGps = false;
        });

        return;
      }

      // IMPORTANT:
      // Get and store the phone GPS coordinates BEFORE doing any
      // Internet/reverse-geocoding request. A Nominatim failure must
      // never make a successful GPS reading look like a GPS failure.
      final Position position = await _getPhoneGps();

      if (!mounted) {
        return;
      }

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _gpsAccuracy = position.accuracy;
        _usingGps = true;
        _isLoading = false;
      });

      _showMessage(
        'GPS detected. Accuracy: ${position.accuracy.toStringAsFixed(0)} m',
      );

      // Reverse geocoding is only used to automatically select the
      // configured State and District. GPS remains successful if
      // this network request fails.
      try {
        final Map<String, dynamic> address =
            await _getAddressFromCoordinates(position);

        final String detectedState = _firstValue(
          <String?>[
            address['state']?.toString(),
          ],
        );

        final String detectedDistrict = _firstValue(
          <String?>[
            address['state_district']?.toString(),
            address['district']?.toString(),
            address['county']?.toString(),
            address['municipality']?.toString(),
            address['city']?.toString(),
          ],
        );

        final String country = _firstValue(
          <String?>[
            address['country']?.toString(),
          ],
        );

        if (!mounted) {
          return;
        }

        if (country.isNotEmpty &&
            !_normalize(country).contains('india')) {
          _showMessage(
            'GPS is working, but the detected location is outside India. Coordinates were saved.',
          );
          return;
        }

        final String? matchedState =
            _findState(detectedState);

        if (matchedState == null) {
          _showMessage(
            detectedState.isEmpty
                ? 'GPS is working. State could not be identified automatically. Choose State and District manually.'
                : 'GPS is working. Detected "$detectedState", but this state is not configured in AgriAI. Choose State and District manually.',
          );
          return;
        }

        final String matchedDistrict =
            _findDistrict(
          matchedState,
          detectedDistrict,
        );

        setState(() {
          _selectedState = matchedState;
          _selectedDistrict = matchedDistrict;

          final List<String> crops = availableCrops;

          if (crops.isNotEmpty &&
              !crops.contains(_selectedCrop)) {
            _selectedCrop = crops.first;
          }
        });

        _showMessage(
          'GPS selected: $_selectedDistrict, $_selectedState',
        );
      } catch (_) {
        // Do NOT reset _usingGps or the coordinates here.
        // GPS has already succeeded; only reverse geocoding failed.
        if (!mounted) {
          return;
        }

        _showMessage(
          'GPS is working, but State/District could not be detected automatically. Choose them manually.',
        );
      }
    } on TimeoutException {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _usingGps = false;
      });

      _showMessage(
        'Phone GPS timed out. Move to an open area and try Automatic GPS again.',
      );
    } on LocationServiceDisabledException {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _usingGps = false;
      });

      _showMessage(
        'Phone Location Services are OFF. Turn on GPS and try again.',
      );
    } on PermissionDeniedException {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _usingGps = false;
      });

      _showMessage(
        'Location permission is required for Automatic GPS.',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _usingGps = false;
      });

      _showMessage(
        'Unable to read the phone GPS. Make sure Location Services and Location permission are enabled, then try again.',
      );
    }
  }

  String? _findState(String value) {
    final String target = _normalize(value);

    if (target.isEmpty) {
      return null;
    }

    for (final String state in stateDistricts.keys) {
      final String normalized = _normalize(state);

      if (normalized == target ||
          normalized.contains(target) ||
          target.contains(normalized)) {
        return state;
      }
    }

    return null;
  }

  String _findDistrict(
    String state,
    String value,
  ) {
    final List<String> districts =
        stateDistricts[state] ?? <String>[];

    if (districts.isEmpty) {
      return '';
    }

    final String target = _normalize(value);

    if (target.isEmpty) {
      return districts.first;
    }

    for (final String district in districts) {
      final String normalized =
          _normalize(district);

      if (normalized == target ||
          normalized.contains(target) ||
          target.contains(normalized)) {
        return district;
      }
    }

    return districts.first;
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(
          RegExp(r'[^a-z0-9]'),
          '',
        );
  }

  String _firstValue(List<String?> values) {
    for (final String? value in values) {
      if (value != null &&
          value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return '';
  }

  void _useManualLocation() {
    if (_isLoading) {
      return;
    }

    setState(() {
      _usingGps = false;

      // GPS data is valid only while Automatic mode is selected.
      _latitude = null;
      _longitude = null;
      _gpsAccuracy = null;
    });

    _showMessage(
      'Manual Location selected. Choose State and District.',
    );
  }

  void _stateChanged(String? value) {
    if (value == null) {
      return;
    }

    final List<String> districts =
        stateDistricts[value] ?? <String>[];

    if (districts.isEmpty) {
      return;
    }

    setState(() {
      _selectedState = value;
      _selectedDistrict = districts.first;
      _usingGps = false;
      _latitude = null;
      _longitude = null;
      _gpsAccuracy = null;

      final List<String> crops =
          availableCrops;

      if (crops.isNotEmpty) {
        _selectedCrop = crops.first;
      }
    });
  }

  void _districtChanged(String? value) {
    if (value == null) {
      return;
    }

    setState(() {
      _selectedDistrict = value;
      _usingGps = false;
      _latitude = null;
      _longitude = null;
      _gpsAccuracy = null;

      final List<String> crops =
          availableCrops;

      if (crops.isNotEmpty &&
          !crops.contains(_selectedCrop)) {
        _selectedCrop = crops.first;
      }
    });
  }

  Future<void> _selectCrop() async {
    final String? crop =
        await showDialog<String>(
      context: context,
      builder: (_) => CropSearchDialog(
        crops: availableCrops,
        selectedCrop: _selectedCrop,
      ),
    );

    if (!mounted || crop == null) {
      return;
    }

    setState(() {
      _selectedCrop = crop;
    });
  }

  double _number(
    TextEditingController controller,
  ) {
    return double.tryParse(
          controller.text.trim(),
        ) ??
        0;
  }

  String? _validateNumber(
    String? value,
    String label, {
    double minimum = 0,
    double? maximum,
  }) {
    if (value == null ||
        value.trim().isEmpty) {
      return '$label is required';
    }

    final double? parsed =
        double.tryParse(value.trim());

    if (parsed == null) {
      return 'Enter a valid number';
    }

    if (parsed < minimum) {
      return '$label is invalid';
    }

    if (maximum != null &&
        parsed > maximum) {
      return '$label is invalid';
    }

    return null;
  }

  Future<void> _predict() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    await Future<void>.delayed(
      const Duration(milliseconds: 600),
    );

    final double area =
        _number(_areaController);

    final double rainfall =
        _number(_rainfallController);

    final double temperature =
        _number(_temperatureController);

    final double humidity =
        _number(_humidityController);

    final double fertilizer =
        _number(_fertilizerController);

    final double soilPh =
        _number(_soilPhController);

    final double nitrogen =
        _number(_nitrogenController);

    final double phosphorus =
        _number(_phosphorusController);

    final double potassium =
        _number(_potassiumController);

    final double previousYield =
        _number(_previousYieldController);

    final double baseline =
        baseYieldPerHectare[_selectedCrop] ??
            2000;

    double factor = 1.0;

    factor *= _environmentFactor(
      rainfall,
      idealRainfall[_selectedCrop] ?? 700,
      0.55,
    );

    factor *= _environmentFactor(
      temperature,
      idealTemperature[_selectedCrop] ?? 25,
      0.30,
    );

    factor *= _environmentFactor(
      humidity,
      idealHumidity[_selectedCrop] ?? 65,
      0.35,
    );

    if (soilPh >= 6 && soilPh <= 7.5) {
      factor *= 1.08;
    } else if (soilPh >= 5.5 && soilPh <= 8) {
      factor *= 1.02;
    } else {
      factor *= 0.92;
    }

    factor *= _nutrientFactor(
      nitrogen,
      140,
    );

    factor *= _nutrientFactor(
      phosphorus,
      60,
    );

    factor *= _nutrientFactor(
      potassium,
      60,
    );

    if (fertilizer >= 100 &&
        fertilizer <= 350) {
      factor *= 1.06;
    } else if (fertilizer > 0) {
      factor *= 0.99;
    }

    if (previousYield > 0) {
      final double oldRate =
          previousYield /
              math.max(area, 0.01);

      final double ratio =
          oldRate / baseline;

      factor *=
          0.90 +
          ratio.clamp(0.70, 1.25) * 0.10;
    }

    switch (_selectedIrrigation) {
      case 'Drip':
        factor *= 1.07;
        break;

      case 'Sprinkler':
        factor *= 1.04;
        break;

      case 'Flood':
        factor *= 1.01;
        break;

      default:
        factor *= 0.97;
    }

    if (_selectedSeason == 'Kharif') {
      factor *= 1.02;
    }

    factor = factor.clamp(0.55, 1.30);

    final double yieldPerHectare =
        baseline * factor;

    final double totalYield =
        yieldPerHectare * area;

    double confidence = 50;

    if (rainfall > 0) {
      confidence += 7;
    }

    if (temperature > 0) {
      confidence += 7;
    }

    if (humidity > 0) {
      confidence += 6;
    }

    if (soilPh > 0) {
      confidence += 7;
    }

    if (fertilizer > 0) {
      confidence += 4;
    }

    if (area > 0) {
      confidence += 4;
    }

    if (_usingGps) {
      confidence += 5;
    }

    confidence = confidence.clamp(50, 95);

    final double uncertainty =
        (1 - confidence / 100) * 0.40;

    final YieldHistoryRecord record =
        YieldHistoryRecord(
      date: DateTime.now(),
      state: _selectedState,
      district: _selectedDistrict,
      crop: _selectedCrop,
      season: _selectedSeason,
      soil: _selectedSoil,
      irrigation: _selectedIrrigation,
      area: area,
      latitude: _latitude,
      longitude: _longitude,
      yieldValue: totalYield,
      yieldPerHectare: yieldPerHectare,
      confidence: confidence,
      minimumYield:
          totalYield * (1 - uncertainty),
      maximumYield:
          totalYield * (1 + uncertainty),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
      _history.insert(0, record);
    });

    await _saveHistory();

    if (!mounted) {
      return;
    }

    widget.onPredictionComplete?.call();

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => YieldResultScreen(
          record: record,
          history:
              List<YieldHistoryRecord>.from(
            _history,
          ),
        ),
      ),
    );
  }

  double _environmentFactor(
    double actual,
    double ideal,
    double toleranceRatio,
  ) {
    if (actual <= 0) {
      return 0.95;
    }

    final double difference =
        (actual - ideal).abs();

    final double tolerance = math.max(
      ideal * toleranceRatio,
      1,
    );

    return (1 - difference / tolerance)
        .clamp(0.70, 1.10);
  }

  double _nutrientFactor(
    double actual,
    double ideal,
  ) {
    if (actual <= 0) {
      return 1;
    }

    final double ratio = actual / ideal;

    if (ratio >= 0.85 &&
        ratio <= 1.25) {
      return 1.05;
    }

    if (ratio >= 0.55 &&
        ratio <= 1.50) {
      return 1.01;
    }

    return 0.96;
  }

  void _openHistory() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => YieldHistoryScreen(
          history:
              List<YieldHistoryRecord>.from(
            _history,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> crops = availableCrops;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Yield Production',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Yield History',
            onPressed:
                _history.isEmpty
                    ? null
                    : _openHistory,
            icon: const Icon(
              Icons.history_rounded,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              20,
              8,
              20,
              35,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                const _HeroCard(),
                const SizedBox(height: 20),

                const _SectionHeader(
                  title: '1. Farm Location',
                  subtitle:
                      'Use mobile GPS automatically or choose the location manually.',
                ),
                const SizedBox(height: 10),

                _Card(
                  child: Column(
                    children: [
                      // ===================================================
                      // LOCATION MODE: AUTOMATIC OR MANUAL
                      // ===================================================
                      Row(
                        children: [
                          Expanded(
                            child: _LocationButton(
                              title: 'Automatic',
                              subtitle: 'Use phone GPS',
                              icon: Icons.my_location_rounded,
                              selected: _usingGps,
                              loading: _isLoading && _usingGps,
                              onTap: _useAutomaticGps,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _LocationButton(
                              title: 'Manual',
                              subtitle: 'Enter location',
                              icon: Icons.edit_location_alt_outlined,
                              selected: !_usingGps,
                              loading: false,
                              onTap: _useManualLocation,
                            ),
                          ),
                        ],
                      ),

                      // ===================================================
                      // MANUAL MODE ONLY
                      // State and District are completely hidden when
                      // Automatic mode is selected.
                      // ===================================================
                      if (!_usingGps) ...[
                        const SizedBox(height: 14),

                        _DropdownField(
                          label: 'State',
                          icon: Icons.map_outlined,
                          value: _selectedState,
                          items: stateDistricts.keys.toList(),
                          onChanged: _stateChanged,
                        ),

                        const SizedBox(height: 12),

                        _DropdownField(
                          label: 'District',
                          icon: Icons.location_city_outlined,
                          value: _selectedDistrict,
                          items: stateDistricts[_selectedState] ?? <String>[],
                          onChanged: _districtChanged,
                        ),
                      ],

                      // ===================================================
                      // AUTOMATIC MODE ONLY
                      // No manual State/District controls are shown here.
                      // ===================================================
                      if (_usingGps) ...[
                        const SizedBox(height: 14),

                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: double.infinity,
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: AppColors.cardGreen,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.border,
                            ),
                          ),
                          child: _isLoading
                              ? const Row(
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Requesting GPS permission and detecting your current location...',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          height: 1.35,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : (_latitude != null && _longitude != null)
                                  ? Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.gps_fixed_rounded,
                                          size: 21,
                                          color: AppColors.primary,
                                        ),
                                        const SizedBox(width: 9),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'GPS Location Detected',
                                                style: TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w900,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                '$_selectedDistrict, $_selectedState',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Latitude: ${_latitude!.toStringAsFixed(5)}\n'
                                                'Longitude: ${_longitude!.toStringAsFixed(5)}'
                                                '${_gpsAccuracy != null ? '\nAccuracy: ${_gpsAccuracy!.toStringAsFixed(0)} m' : ''}',
                                                style: const TextStyle(
                                                  fontSize: 8.5,
                                                  height: 1.35,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    )
                                  : const Row(
                                      children: [
                                        Icon(
                                          Icons.location_searching_rounded,
                                          size: 20,
                                          color: AppColors.primary,
                                        ),
                                        SizedBox(width: 9),
                                        Expanded(
                                          child: Text(
                                            'Tap Automatic to request permission and detect your phone GPS location.',
                                            style: TextStyle(
                                              fontSize: 10,
                                              height: 1.35,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                _SectionHeader(
                  title: '2. Recommended Crops',
                  subtitle:
                      'Recommended crops for $_selectedDistrict, $_selectedState.',
                ),
                const SizedBox(height: 10),

                _RecommendedCrops(
                  crops: recommendedCrops,
                  selected: _selectedCrop,
                  onSelected: (String crop) {
                    setState(() {
                      _selectedCrop = crop;
                    });
                  },
                ),

                const SizedBox(height: 10),

                _CropSelector(
                  crop: _selectedCrop,
                  count: crops.length,
                  onTap: _selectCrop,
                ),

                const SizedBox(height: 20),

                const _SectionHeader(
                  title:
                      '3. Farm & Crop Parameters',
                  subtitle:
                      'Enter the parameters required for crop yield prediction.',
                ),
                const SizedBox(height: 10),

                _Card(
                  child: Column(
                    children: [
                      _NumberField(
                        controller:
                            _areaController,
                        label: 'Farm Area',
                        hint: 'Enter area',
                        suffix: 'hectare',
                        icon: Icons
                            .landscape_outlined,
                        validator:
                            (String? value) =>
                                _validateNumber(
                          value,
                          'Farm area',
                          minimum: 0.01,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _DropdownField(
                        label: 'Season',
                        icon: Icons
                            .calendar_month_outlined,
                        value: _selectedSeason,
                        items: const <String>[
                          'Kharif',
                          'Rabi',
                          'Zaid',
                          'Year Round',
                        ],
                        onChanged:
                            (String? value) {
                          if (value == null) {
                            return;
                          }

                          setState(() {
                            _selectedSeason =
                                value;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                const _SectionHeader(
                  title: '4. Weather Parameters',
                  subtitle:
                      'Enter rainfall, temperature and humidity.',
                ),
                const SizedBox(height: 10),

                _Card(
                  child: Column(
                    children: [
                      _NumberField(
                        controller:
                            _rainfallController,
                        label:
                            'Seasonal Rainfall',
                        hint:
                            'Enter rainfall',
                        suffix: 'mm',
                        icon: Icons
                            .water_drop_outlined,
                        validator:
                            (String? value) =>
                                _validateNumber(
                          value,
                          'Rainfall',
                        ),
                      ),
                      const SizedBox(height: 12),

                      _NumberField(
                        controller:
                            _temperatureController,
                        label:
                            'Average Temperature',
                        hint:
                            'Enter temperature',
                        suffix: '°C',
                        icon: Icons
                            .thermostat_outlined,
                        validator:
                            (String? value) =>
                                _validateNumber(
                          value,
                          'Temperature',
                        ),
                      ),
                      const SizedBox(height: 12),

                      _NumberField(
                        controller:
                            _humidityController,
                        label:
                            'Average Humidity',
                        hint:
                            'Enter humidity',
                        suffix: '%',
                        icon: Icons
                            .opacity_outlined,
                        validator:
                            (String? value) =>
                                _validateNumber(
                          value,
                          'Humidity',
                          minimum: 0,
                          maximum: 100,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                const _SectionHeader(
                  title:
                      '5. Soil & Farming Parameters',
                  subtitle:
                      'Add soil, pH, irrigation and fertilizer information.',
                ),
                const SizedBox(height: 10),

                _Card(
                  child: Column(
                    children: [
                      _DropdownField(
                        label: 'Soil Type',
                        icon: Icons
                            .grass_outlined,
                        value: _selectedSoil,
                        items: const <String>[
                          'Black Soil',
                          'Alluvial Soil',
                          'Red Soil',
                          'Loamy Soil',
                          'Clay Soil',
                          'Sandy Soil',
                        ],
                        onChanged:
                            (String? value) {
                          if (value == null) {
                            return;
                          }

                          setState(() {
                            _selectedSoil =
                                value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      _NumberField(
                        controller:
                            _soilPhController,
                        label: 'Soil pH',
                        hint: 'Enter pH',
                        suffix: 'pH',
                        icon: Icons
                            .science_outlined,
                        validator:
                            (String? value) =>
                                _validateNumber(
                          value,
                          'Soil pH',
                          minimum: 0,
                          maximum: 14,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _DropdownField(
                        label: 'Irrigation',
                        icon: Icons
                            .water_drop_rounded,
                        value:
                            _selectedIrrigation,
                        items: const <String>[
                          'Rainfed',
                          'Drip',
                          'Sprinkler',
                          'Flood',
                        ],
                        onChanged:
                            (String? value) {
                          if (value == null) {
                            return;
                          }

                          setState(() {
                            _selectedIrrigation =
                                value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      _NumberField(
                        controller:
                            _fertilizerController,
                        label:
                            'Fertilizer Usage',
                        hint:
                            'Enter fertilizer',
                        suffix: 'kg',
                        icon: Icons
                            .eco_outlined,
                        validator:
                            (String? value) =>
                                _validateNumber(
                          value,
                          'Fertilizer',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                _AdvancedCard(
                  expanded: _showAdvanced,
                  onTap: () {
                    setState(() {
                      _showAdvanced =
                          !_showAdvanced;
                    });
                  },
                  child: Column(
                    children: [
                      _NumberField(
                        controller:
                            _nitrogenController,
                        label: 'Nitrogen (N)',
                        hint: 'Optional',
                        suffix: 'kg/ha',
                        icon: Icons
                            .science_outlined,
                      ),
                      const SizedBox(height: 12),

                      _NumberField(
                        controller:
                            _phosphorusController,
                        label:
                            'Phosphorus (P)',
                        hint: 'Optional',
                        suffix: 'kg/ha',
                        icon: Icons
                            .science_outlined,
                      ),
                      const SizedBox(height: 12),

                      _NumberField(
                        controller:
                            _potassiumController,
                        label: 'Potassium (K)',
                        hint: 'Optional',
                        suffix: 'kg/ha',
                        icon: Icons
                            .science_outlined,
                      ),
                      const SizedBox(height: 12),

                      _NumberField(
                        controller:
                            _previousYieldController,
                        label:
                            'Previous Yield',
                        hint: 'Optional',
                        suffix: 'kg',
                        icon: Icons
                            .history_rounded,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed:
                        _isLoading
                            ? null
                            : _predict,
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          AppColors.primary,
                      foregroundColor:
                          Colors.white,
                      elevation: 0,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color:
                                  Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .center,
                            children: [
                              Icon(
                                Icons
                                    .auto_awesome_rounded,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Predict Crop Yield',
                                style:
                                    TextStyle(
                                  fontSize: 14.5,
                                  fontWeight:
                                      FontWeight.w800,
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
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(
          AppDimensions.radius22,
        ),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Yield Production',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'GPS location, crop recommendations, field parameters and prediction history.',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.45,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          Icon(
            Icons.analytics_rounded,
            color: Colors.white,
            size: 44,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 10.5,
            height: 1.35,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(
          AppDimensions.radius18,
        ),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: child,
    );
  }
}

class _LocationButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final bool loading;
  final VoidCallback onTap;

  const _LocationButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.cardGreen
                : AppColors.background,
            borderRadius:
                BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              if (loading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: AppColors.primary,
                  ),
                )
              else
                Icon(
                  icon,
                  size: 20,
                  color: selected
                      ? AppColors.primary
                      : AppColors.textMuted,
                ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight:
                            FontWeight.w800,
                        color: selected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 8,
                        color:
                            AppColors.textSecondary,
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

class _DropdownField extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final String safeValue =
        items.contains(value)
            ? value
            : items.first;

    return DropdownButtonFormField<String>(
      initialValue: safeValue,
      isExpanded: true,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: AppColors.primary,
        ),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.4,
          ),
        ),
      ),
      items: items
          .map(
            (String item) =>
                DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight:
                      FontWeight.w600,
                  color:
                      AppColors.textPrimary,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String suffix;
  final IconData icon;
  final String? Function(String?)? validator;

  const _NumberField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.suffix,
    required this.icon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType:
          const TextInputType.numberWithOptions(
        decimal: true,
      ),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        prefixIcon: Icon(
          icon,
          color: AppColors.primary,
        ),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

class _AdvancedCard extends StatelessWidget {
  final bool expanded;
  final VoidCallback onTap;
  final Widget child;

  const _AdvancedCard({
    required this.expanded,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            child: Row(
              children: [
                const Icon(
                  Icons.tune_rounded,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 9),
                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Advanced Parameters',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Optional N, P, K and previous yield.',
                        style: TextStyle(
                          fontSize: 9.5,
                          color:
                              AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  expanded
                      ? Icons
                          .keyboard_arrow_up_rounded
                      : Icons
                          .keyboard_arrow_down_rounded,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: 14),
            child,
          ],
        ],
      ),
    );
  }
}

class _CropSelector extends StatelessWidget {
  final String crop;
  final int count;
  final VoidCallback onTap;

  const _CropSelector({
    required this.crop,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius:
                BorderRadius.circular(17),
            border: Border.all(
              color: AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.cardGreen,
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.eco_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selected Crop',
                      style: TextStyle(
                        fontSize: 9.5,
                        color:
                            AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      crop,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w900,
                        color:
                            AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$count crops available • Tap to search',
                      style: const TextStyle(
                        fontSize: 8.5,
                        color:
                            AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.search_rounded,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
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

class _RecommendedCrops
    extends StatelessWidget {
  final List<String> crops;
  final String selected;
  final ValueChanged<String> onSelected;

  const _RecommendedCrops({
    required this.crops,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (crops.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 54,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: crops.length,
        separatorBuilder:
            (BuildContext context, int index) =>
                const SizedBox(width: 8),
        itemBuilder:
            (BuildContext context, int index) {
          final String crop = crops[index];
          final bool selectedCrop =
              crop == selected;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSelected(crop),
              borderRadius:
                  BorderRadius.circular(14),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 14,
                ),
                decoration: BoxDecoration(
                  color: selectedCrop
                      ? AppColors.primary
                      : AppColors.surface,
                  borderRadius:
                      BorderRadius.circular(14),
                  border: Border.all(
                    color: selectedCrop
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.eco_rounded,
                      size: 17,
                      color: selectedCrop
                          ? Colors.white
                          : AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      crop,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight:
                            FontWeight.w800,
                        color: selectedCrop
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class CropSearchDialog extends StatefulWidget {
  final List<String> crops;
  final String selectedCrop;

  const CropSearchDialog({
    super.key,
    required this.crops,
    required this.selectedCrop,
  });

  @override
  State<CropSearchDialog> createState() =>
      _CropSearchDialogState();
}

class _CropSearchDialogState
    extends State<CropSearchDialog> {
  final TextEditingController
      _searchController =
      TextEditingController();

  late List<String> _results;

  @override
  void initState() {
    super.initState();

    _results = List<String>.from(
      widget.crops,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filter(String value) {
    final String query =
        value.trim().toLowerCase();

    setState(() {
      _results = widget.crops
          .where(
            (String crop) =>
                crop.toLowerCase().contains(
                  query,
                ),
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Search Crop',
        style: TextStyle(
          fontWeight: FontWeight.w800,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 430,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: _filter,
              decoration: InputDecoration(
                hintText: 'Search crop...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                ),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _results.isEmpty
                  ? const Center(
                      child: Text(
                        'No crop found.',
                      ),
                    )
                  : ListView.builder(
                      itemCount:
                          _results.length,
                      itemBuilder:
                          (
                        BuildContext context,
                        int index,
                      ) {
                        final String crop =
                            _results[index];

                        final bool selected =
                            crop ==
                                widget
                                    .selectedCrop;

                        return ListTile(
                          leading: const Icon(
                            Icons.eco_rounded,
                            color:
                                AppColors.primary,
                          ),
                          title: Text(
                            crop,
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                          trailing: selected
                              ? const Icon(
                                  Icons
                                      .check_circle_rounded,
                                  color:
                                      AppColors.primary,
                                )
                              : null,
                          onTap: () =>
                              Navigator.of(
                            context,
                          ).pop(crop),
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

class YieldResultScreen
    extends StatelessWidget {
  final YieldHistoryRecord record;
  final List<YieldHistoryRecord> history;

  const YieldResultScreen({
    super.key,
    required this.record,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Yield Result',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: AppColors.background,
        foregroundColor:
            AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            30,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius:
                      BorderRadius.circular(22),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Prediction Ready',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight:
                            FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${record.crop} • ${record.district}, ${record.state}',
                      textAlign:
                          TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              _ResultMetric(
                title: 'Estimated Production',
                value:
                    '${record.yieldValue.toStringAsFixed(0)} kg',
                subtitle:
                    '${record.yieldPerHectare.toStringAsFixed(0)} kg / hectare',
                icon:
                    Icons.agriculture_rounded,
                large: true,
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _ResultMetric(
                      title: 'Confidence',
                      value:
                          '${record.confidence.toStringAsFixed(0)}%',
                      subtitle:
                          'Prediction confidence',
                      icon:
                          Icons.verified_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ResultMetric(
                      title: 'Farm Area',
                      value:
                          '${record.area.toStringAsFixed(2)} ha',
                      subtitle: 'Farm size',
                      icon: Icons
                          .landscape_outlined,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              const Text(
                'Expected Yield Range',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _RangeMetric(
                      title: 'Minimum',
                      value:
                          '${record.minimumYield.toStringAsFixed(0)} kg',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _RangeMetric(
                      title: 'Maximum',
                      value:
                          '${record.maximumYield.toStringAsFixed(0)} kg',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              const Text(
                'Yield Graph',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 10),

              _YieldGraph(record: record),

              const SizedBox(height: 18),

              const Text(
                'Prediction Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 10),

              _ResultDetails(record: record),

              const SizedBox(height: 18),

              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            YieldHistoryScreen(
                          history: history,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.history_rounded,
                  ),
                  label: const Text(
                    'Open Yield History',
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

class _ResultMetric extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final bool large;

  const _ResultMetric({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.circular(17),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppColors.primary,
          ),
          const SizedBox(height: 7),
          Text(
            title,
            style: const TextStyle(
              fontSize: 9.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: large ? 28 : 18,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 9,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeMetric extends StatelessWidget {
  final String title;
  final String value;

  const _RangeMetric({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.cardGreen,
        borderRadius:
            BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 9.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _YieldGraph extends StatelessWidget {
  final YieldHistoryRecord record;

  const _YieldGraph({
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    final double maximum =
        math.max(record.maximumYield, 1);

    final List<double> values = <double>[
      record.minimumYield,
      record.yieldValue,
      record.maximumYield,
    ];

    const List<String> labels = <String>[
      'Min',
      'Predicted',
      'Max',
    ];

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.end,
        children: List.generate(
          3,
          (int index) {
            final double height =
                (115 *
                        (values[index] /
                                maximum)
                            .clamp(
                          0.12,
                          1.0,
                        )) +
                    10;

            return Expanded(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.end,
                children: [
                  Text(
                    values[index]
                        .toStringAsFixed(0),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    width: 42,
                    height: height,
                    decoration: BoxDecoration(
                      color: index == 1
                          ? AppColors.primary
                          : AppColors.cardGreen,
                      borderRadius:
                          BorderRadius.circular(
                        10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    labels[index],
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight:
                          FontWeight.w700,
                      color:
                          AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ResultDetails extends StatelessWidget {
  final YieldHistoryRecord record;

  const _ResultDetails({
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: [
          _DetailRow('Crop', record.crop),
          _DetailRow('State', record.state),
          _DetailRow(
            'District',
            record.district,
          ),
          _DetailRow(
            'Season',
            record.season,
          ),
          _DetailRow(
            'Soil',
            record.soil,
          ),
          _DetailRow(
            'Irrigation',
            record.irrigation,
          ),
          if (record.latitude != null &&
              record.longitude != null)
            _DetailRow(
              'GPS',
              '${record.latitude!.toStringAsFixed(5)}, ${record.longitude!.toStringAsFixed(5)}',
            ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(
    this.label,
    this.value,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 6,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                color:
                    AppColors.textSecondary,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class YieldHistoryScreen
    extends StatelessWidget {
  final List<YieldHistoryRecord> history;

  const YieldHistoryScreen({
    super.key,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Yield History',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: AppColors.background,
        foregroundColor:
            AppColors.textPrimary,
        elevation: 0,
      ),
      body: history.isEmpty
          ? const Center(
              child: Text(
                'No predictions saved yet.',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color:
                      AppColors.textSecondary,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: history.length,
              separatorBuilder:
                  (
                BuildContext context,
                int index,
              ) =>
                      const SizedBox(height: 10),
              itemBuilder:
                  (
                BuildContext context,
                int index,
              ) {
                final YieldHistoryRecord record =
                    history[index];

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius:
                        BorderRadius.circular(16),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              YieldResultScreen(
                            record: record,
                            history: history,
                          ),
                        ),
                      );
                    },
                    child: _Card(
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration:
                                BoxDecoration(
                              color:
                                  AppColors.cardGreen,
                              borderRadius:
                                  BorderRadius
                                      .circular(12),
                            ),
                            child: const Icon(
                              Icons
                                  .analytics_rounded,
                              color:
                                  AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Text(
                                  record.crop,
                                  style:
                                      const TextStyle(
                                    fontSize: 13,
                                    fontWeight:
                                        FontWeight
                                            .w800,
                                  ),
                                ),
                                const SizedBox(
                                    height: 3),
                                Text(
                                  '${record.district}, ${record.state}',
                                  style:
                                      const TextStyle(
                                    fontSize: 9.5,
                                    color:
                                        AppColors
                                            .textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .end,
                            children: [
                              Text(
                                '${record.yieldValue.toStringAsFixed(0)} kg',
                                style:
                                    const TextStyle(
                                  fontSize: 12,
                                  fontWeight:
                                      FontWeight
                                          .w900,
                                  color:
                                      AppColors.primary,
                                ),
                              ),
                              Text(
                                '${record.confidence.toStringAsFixed(0)}%',
                                style:
                                    const TextStyle(
                                  fontSize: 8.5,
                                  color:
                                      AppColors
                                          .textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class YieldHistoryRecord {
  final DateTime date;
  final String state;
  final String district;
  final String crop;
  final String season;
  final String soil;
  final String irrigation;
  final double area;
  final double? latitude;
  final double? longitude;
  final double yieldValue;
  final double yieldPerHectare;
  final double confidence;
  final double minimumYield;
  final double maximumYield;

  const YieldHistoryRecord({
    required this.date,
    required this.state,
    required this.district,
    required this.crop,
    required this.season,
    required this.soil,
    required this.irrigation,
    required this.area,
    required this.latitude,
    required this.longitude,
    required this.yieldValue,
    required this.yieldPerHectare,
    required this.confidence,
    required this.minimumYield,
    required this.maximumYield,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'date': date.toIso8601String(),
      'state': state,
      'district': district,
      'crop': crop,
      'season': season,
      'soil': soil,
      'irrigation': irrigation,
      'area': area,
      'latitude': latitude,
      'longitude': longitude,
      'yieldValue': yieldValue,
      'yieldPerHectare': yieldPerHectare,
      'confidence': confidence,
      'minimumYield': minimumYield,
      'maximumYield': maximumYield,
    };
  }

  factory YieldHistoryRecord.fromMap(
    Map<String, dynamic> map,
  ) {
    double readDouble(
      String key, {
      double fallback = 0,
    }) {
      final Object? value = map[key];

      if (value is num) {
        return value.toDouble();
      }

      return double.tryParse(value?.toString() ?? '') ??
          fallback;
    }

    double? readNullableDouble(String key) {
      final Object? value = map[key];

      if (value == null) {
        return null;
      }

      if (value is num) {
        return value.toDouble();
      }

      return double.tryParse(value.toString());
    }

    final Object? rawDate = map['date'];
    final DateTime parsedDate =
        DateTime.tryParse(rawDate?.toString() ?? '') ??
            DateTime.now();

    return YieldHistoryRecord(
      date: parsedDate,
      state: map['state']?.toString() ?? 'Unknown',
      district:
          map['district']?.toString() ?? 'Unknown',
      crop: map['crop']?.toString() ?? 'Unknown',
      season: map['season']?.toString() ?? 'Unknown',
      soil: map['soil']?.toString() ?? 'Unknown',
      irrigation:
          map['irrigation']?.toString() ?? 'Unknown',
      area: readDouble('area'),
      latitude: readNullableDouble('latitude'),
      longitude: readNullableDouble('longitude'),
      yieldValue: readDouble('yieldValue'),
      yieldPerHectare:
          readDouble('yieldPerHectare'),
      confidence: readDouble('confidence'),
      minimumYield: readDouble('minimumYield'),
      maximumYield: readDouble('maximumYield'),
    );
  }
}