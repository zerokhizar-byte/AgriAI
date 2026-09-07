class LanguageModel {
  final String code;
  final String name;
  final String nativeName;
  final String shortCode;

  const LanguageModel({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.shortCode,
  });

  static const List<LanguageModel> supportedLanguages = [
    LanguageModel(
      code: 'en',
      name: 'English',
      nativeName: 'English',
      shortCode: 'EN',
    ),
    LanguageModel(
      code: 'hi',
      name: 'Hindi',
      nativeName: 'हिन्दी',
      shortCode: 'हि',
    ),
    LanguageModel(
      code: 'mr',
      name: 'Marathi',
      nativeName: 'मराठी',
      shortCode: 'म',
    ),
    LanguageModel(
      code: 'ur',
      name: 'Urdu',
      nativeName: 'اردو',
      shortCode: 'ا',
    ),
  ];

  factory LanguageModel.fromCode(String code) {
    return supportedLanguages.firstWhere(
      (language) => language.code == code,
      orElse: () => supportedLanguages.first,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is LanguageModel && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;
}