class UserModel {
  final String id;
  final String name;
  final String? phoneNumber;
  final String? email;
  final String? profileImage;
  final String? location;
  final String preferredLanguage;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.name,
    this.phoneNumber,
    this.email,
    this.profileImage,
    this.location,
    this.preferredLanguage = 'en',
    this.createdAt,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? email,
    String? profileImage,
    String? location,
    String? preferredLanguage,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      location: location ?? this.location,
      preferredLanguage:
          preferredLanguage ?? this.preferredLanguage,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory UserModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phoneNumber:
          json['phoneNumber']?.toString(),
      email: json['email']?.toString(),
      profileImage:
          json['profileImage']?.toString(),
      location:
          json['location']?.toString(),
      preferredLanguage:
          json['preferredLanguage']?.toString() ?? 'en',
      createdAt:
          _parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'profileImage': profileImage,
      'location': location,
      'preferredLanguage': preferredLanguage,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}