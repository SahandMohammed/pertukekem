import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileModel {
  final String userId;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? profilePicture;
  final List<String> roles;
  final List<Map<String, dynamic>> addresses;
  final List<String> favorites;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final bool isBlocked;
  final String? storeId;
  final String? storeName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;
  final String createdByApp;
  final Map<String, dynamic>? fcmTokens;

  UserProfileModel({
    required this.userId,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.profilePicture,
    required this.roles,
    required this.addresses,
    required this.favorites,
    required this.isEmailVerified,
    required this.isPhoneVerified,
    required this.isBlocked,
    this.storeId,
    this.storeName,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
    required this.createdByApp,
    this.fcmTokens,
  });

  String get fullName => '$firstName $lastName';

  String get displayEmail => email;

  String get displayPhone => phoneNumber ?? 'Not provided';

  factory UserProfileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserProfileModel(
      userId: doc.id,
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      phoneNumber: data['phoneNumber'],
      profilePicture: data['profilePicture'],
      roles: List<String>.from(data['roles'] ?? []),
      addresses: List<Map<String, dynamic>>.from(
        (data['addresses'] ?? []).map(
          (addr) => Map<String, dynamic>.from(addr),
        ),
      ),
      favorites: List<String>.from(data['favorites'] ?? []),
      isEmailVerified: data['isEmailVerified'] ?? false,
      isPhoneVerified: data['isPhoneVerified'] ?? false,
      isBlocked: data['isBlocked'] ?? false,
      storeId: data['storeId'],
      storeName: data['storeName'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      lastLoginAt:
          data['lastLoginAt'] != null
              ? (data['lastLoginAt'] as Timestamp).toDate()
              : null,
      createdByApp: data['createdByApp'] ?? 'unknown',
      fcmTokens: data['fcmTokens'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'email_lowercase': email.toLowerCase(),
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'profilePicture': profilePicture,
      'roles': roles,
      'addresses': addresses,
      'favorites': favorites,
      'isEmailVerified': isEmailVerified,
      'isPhoneVerified': isPhoneVerified,
      'isBlocked': isBlocked,
      'storeId': storeId,
      'storeName': storeName,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdByApp': createdByApp,
      'fcmTokens': fcmTokens,
    };
  }

  UserProfileModel copyWith({
    String? userId,
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? profilePicture,
    List<String>? roles,
    List<Map<String, dynamic>>? addresses,
    List<String>? favorites,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    bool? isBlocked,
    String? storeId,
    String? storeName,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    String? createdByApp,
    Map<String, dynamic>? fcmTokens,
  }) {
    return UserProfileModel(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePicture: profilePicture ?? this.profilePicture,
      roles: roles ?? this.roles,
      addresses: addresses ?? this.addresses,
      favorites: favorites ?? this.favorites,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      isBlocked: isBlocked ?? this.isBlocked,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdByApp: createdByApp ?? this.createdByApp,
      fcmTokens: fcmTokens ?? this.fcmTokens,
    );
  }
}
