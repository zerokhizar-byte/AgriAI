import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  const AppLocalizations(this.locale);

  static const supportedLocales = [
    Locale('en'),
    Locale('hi'),
    Locale('mr'),
    Locale('ur'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final result =
        Localizations.of<AppLocalizations>(
          context,
          AppLocalizations,
        );

    if (result == null) {
      throw FlutterError(
        'AppLocalizations could not be found in the widget tree.',
      );
    }

    return result;
  }

  String get _languageCode => locale.languageCode;

  String _text({
    required String en,
    required String hi,
    required String mr,
    required String ur,
  }) {
    switch (_languageCode) {
      case 'hi':
        return hi;
      case 'mr':
        return mr;
      case 'ur':
        return ur;
      default:
        return en;
    }
  }

  // App
  String get appName => 'AgriAI';

  String get appSubtitle => _text(
        en: 'Smart Farming Assistant',
        hi: 'स्मार्ट खेती सहायक',
        mr: 'स्मार्ट शेती सहाय्यक',
        ur: 'اسمارٹ فارمنگ اسسٹنٹ',
      );

  // Splash
  String get splashTagline => _text(
        en: 'Smart Farming Assistant',
        hi: 'स्मार्ट खेती सहायक',
        mr: 'स्मार्ट शेती सहाय्यक',
        ur: 'اسمارٹ فارمنگ اسسٹنٹ',
      );

  // Language selection
  String get welcome => _text(
        en: 'Welcome to AgriAI',
        hi: 'AgriAI में आपका स्वागत है',
        mr: 'AgriAI मध्ये आपले स्वागत आहे',
        ur: 'AgriAI میں خوش آمدید',
      );

  String get chooseLanguage => _text(
        en: 'Choose your preferred language',
        hi: 'अपनी पसंदीदा भाषा चुनें',
        mr: 'आपली आवडती भाषा निवडा',
        ur: 'اپنی پسندیدہ زبان منتخب کریں',
      );

  String get continueText => _text(
        en: 'Continue',
        hi: 'जारी रखें',
        mr: 'पुढे चला',
        ur: 'جاری رکھیں',
      );

  String get english => 'English';

  String get hindi => 'हिन्दी';

  String get marathi => 'मराठी';

  String get urdu => 'اردو';

  // Home
  String get goodMorning => _text(
        en: 'Good morning, Farmer',
        hi: 'सुप्रभात, किसान',
        mr: 'शुभ सकाळ, शेतकरी',
        ur: 'صبح بخیر، کسان',
      );

  String get homeDescription => _text(
        en: 'Let AgriAI help you make smarter farming decisions.',
        hi: 'AgriAI को बेहतर खेती के फैसले लेने में आपकी मदद करने दें।',
        mr: 'AgriAI ला शेतीचे अधिक चांगले निर्णय घेण्यास मदत करू द्या.',
        ur: 'AgriAI کو بہتر زرعی فیصلے لینے میں آپ کی مدد کرنے دیں۔',
      );

  String get smartTools => _text(
        en: 'Smart tools',
        hi: 'स्मार्ट टूल्स',
        mr: 'स्मार्ट साधने',
        ur: 'اسمارٹ ٹولز',
      );

  String get farmOverview => _text(
        en: 'Farm overview',
        hi: 'खेत का अवलोकन',
        mr: 'शेताचा आढावा',
        ur: 'کھیت کا جائزہ',
      );

  // Weather
  String get today => _text(
        en: 'Today',
        hi: 'आज',
        mr: 'आज',
        ur: 'آج',
      );

  String get goodFarmingConditions => _text(
        en: 'Good conditions for farming',
        hi: 'खेती के लिए अच्छी परिस्थितियाँ',
        mr: 'शेतीसाठी चांगली परिस्थिती',
        ur: 'کاشتکاری کے لیے اچھی صورتحال',
      );

  // Smart tools
  String get cropYield => _text(
        en: 'Crop Yield',
        hi: 'फसल उत्पादन',
        mr: 'पीक उत्पादन',
        ur: 'فصل کی پیداوار',
      );

  String get predictCropYield => _text(
        en: 'Predict your crop yield',
        hi: 'अपनी फसल का उत्पादन अनुमानित करें',
        mr: 'आपल्या पिकाच्या उत्पादनाचा अंदाज लावा',
        ur: 'اپنی فصل کی پیداوار کی پیش گوئی کریں',
      );

  String get disease => _text(
        en: 'Disease',
        hi: 'रोग',
        mr: 'रोग',
        ur: 'بیماری',
      );

  String get checkPlantHealth => _text(
        en: 'Check plant health',
        hi: 'पौधे का स्वास्थ्य जांचें',
        mr: 'पिकाचे आरोग्य तपासा',
        ur: 'پودے کی صحت چیک کریں',
      );

  String get soil => _text(
        en: 'Soil',
        hi: 'मिट्टी',
        mr: 'माती',
        ur: 'مٹی',
      );

  String get analyzeSoil => _text(
        en: 'Analyze soil conditions',
        hi: 'मिट्टी की स्थिति का विश्लेषण करें',
        mr: 'मातीच्या स्थितीचे विश्लेषण करा',
        ur: 'مٹی کی صورتحال کا تجزیہ کریں',
      );

  String get advice => _text(
        en: 'Advice',
        hi: 'सलाह',
        mr: 'सल्ला',
        ur: 'مشورہ',
      );

  String get smartRecommendations => _text(
        en: 'Get smart recommendations',
        hi: 'स्मार्ट सुझाव प्राप्त करें',
        mr: 'स्मार्ट शिफारसी मिळवा',
        ur: 'اسمارٹ سفارشات حاصل کریں',
      );

  // Farm status
  String get good => _text(
        en: 'Good',
        hi: 'अच्छा',
        mr: 'चांगले',
        ur: 'اچھا',
      );

  String get healthy => _text(
        en: 'Healthy',
        hi: 'स्वस्थ',
        mr: 'निरोगी',
        ur: 'صحت مند',
      );

  String get soilMoisture => _text(
        en: 'Soil moisture',
        hi: 'मिट्टी की नमी',
        mr: 'मातीतील ओलावा',
        ur: 'مٹی کی نمی',
      );

  String get cropHealth => _text(
        en: 'Crop health',
        hi: 'फसल का स्वास्थ्य',
        mr: 'पिकाचे आरोग्य',
        ur: 'فصل کی صحت',
      );

  // Navigation
  String get home => _text(
        en: 'Home',
        hi: 'होम',
        mr: 'मुख्यपृष्ठ',
        ur: 'ہوم',
      );

  String get yield => _text(
        en: 'Yield',
        hi: 'उत्पादन',
        mr: 'उत्पादन',
        ur: 'پیداوار',
      );

  String get profile => _text(
        en: 'Profile',
        hi: 'प्रोफ़ाइल',
        mr: 'प्रोफाइल',
        ur: 'پروفائل',
      );

  // Disease detection
  String get plantDiseaseDetection => _text(
        en: 'Plant Disease Detection',
        hi: 'पौधों के रोग की पहचान',
        mr: 'पिकांच्या रोगांची ओळख',
        ur: 'پودوں کی بیماری کی شناخت',
      );

  String get takePhoto => _text(
        en: 'Take Photo',
        hi: 'फोटो लें',
        mr: 'फोटो काढा',
        ur: 'تصویر لیں',
      );

  String get chooseFromGallery => _text(
        en: 'Choose from Gallery',
        hi: 'गैलरी से चुनें',
        mr: 'गॅलरीमधून निवडा',
        ur: 'گیلری سے منتخب کریں',
      );

  String get analyzingImage => _text(
        en: 'Analyzing image...',
        hi: 'छवि का विश्लेषण किया जा रहा है...',
        mr: 'प्रतिमेचे विश्लेषण केले जात आहे...',
        ur: 'تصویر کا تجزیہ کیا جا رہا ہے...',
      );

  String get diseaseResult => _text(
        en: 'Disease Result',
        hi: 'रोग का परिणाम',
        mr: 'रोगाचा निकाल',
        ur: 'بیماری کا نتیجہ',
      );

  // Yield prediction
  String get yieldPrediction => _text(
        en: 'Crop Yield Prediction',
        hi: 'फसल उत्पादन की भविष्यवाणी',
        mr: 'पीक उत्पादनाचा अंदाज',
        ur: 'فصل کی پیداوار کی پیش گوئی',
      );

  String get predictYield => _text(
        en: 'Predict Yield',
        hi: 'उत्पादन की भविष्यवाणी करें',
        mr: 'उत्पादनाचा अंदाज लावा',
        ur: 'پیداوار کی پیش گوئی کریں',
      );

  String get predictedYield => _text(
        en: 'Predicted Yield',
        hi: 'अनुमानित उत्पादन',
        mr: 'अंदाजित उत्पादन',
        ur: 'متوقع پیداوار',
      );

  // Soil analysis
  String get soilAnalysis => _text(
        en: 'Soil Analysis',
        hi: 'मिट्टी का विश्लेषण',
        mr: 'मातीचे विश्लेषण',
        ur: 'مٹی کا تجزیہ',
      );

  String get soilTemperature => _text(
        en: 'Soil Temperature',
        hi: 'मिट्टी का तापमान',
        mr: 'मातीचे तापमान',
        ur: 'مٹی کا درجہ حرارت',
      );

  String get soilPh => _text(
        en: 'Soil pH',
        hi: 'मिट्टी का pH',
        mr: 'मातीचा pH',
        ur: 'مٹی کا pH',
      );

  String get nitrogen => _text(
        en: 'Nitrogen',
        hi: 'नाइट्रोजन',
        mr: 'नायट्रोजन',
        ur: 'نائٹروجن',
      );

  String get phosphorus => _text(
        en: 'Phosphorus',
        hi: 'फास्फोरस',
        mr: 'फॉस्फरस',
        ur: 'فاسفورس',
      );

  String get potassium => _text(
        en: 'Potassium',
        hi: 'पोटेशियम',
        mr: 'पोटॅशियम',
        ur: 'پوٹاشیم',
      );

  // Recommendations
  String get recommendations => _text(
        en: 'Recommendations',
        hi: 'सुझाव',
        mr: 'शिफारसी',
        ur: 'سفارشات',
      );

  String get irrigation => _text(
        en: 'Irrigation',
        hi: 'सिंचाई',
        mr: 'सिंचन',
        ur: 'آبپاشی',
      );

  String get fertilizer => _text(
        en: 'Fertilizer',
        hi: 'उर्वरक',
        mr: 'खत',
        ur: 'کھاد',
      );

  String get cropRecommendation => _text(
        en: 'Crop Recommendation',
        hi: 'फसल की सिफारिश',
        mr: 'पीक शिफारस',
        ur: 'فصل کی سفارش',
      );

  // Weather
  String get weather => _text(
        en: 'Weather',
        hi: 'मौसम',
        mr: 'हवामान',
        ur: 'موسم',
      );

  String get forecast => _text(
        en: 'Forecast',
        hi: 'पूर्वानुमान',
        mr: 'अंदाज',
        ur: 'پیش گوئی',
      );

  // Profile and settings
  String get settings => _text(
        en: 'Settings',
        hi: 'सेटिंग्स',
        mr: 'सेटिंग्ज',
        ur: 'ترتیبات',
      );

  String get language => _text(
        en: 'Language',
        hi: 'भाषा',
        mr: 'भाषा',
        ur: 'زبان',
      );

  String get about => _text(
        en: 'About',
        hi: 'जानकारी',
        mr: 'माहिती',
        ur: 'ہمارے بارے میں',
      );

  String get notifications => _text(
        en: 'Notifications',
        hi: 'सूचनाएं',
        mr: 'सूचना',
        ur: 'اطلاعات',
      );
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (supportedLocale) =>
          supportedLocale.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(
    covariant LocalizationsDelegate<AppLocalizations> old,
  ) {
    return false;
  }
}