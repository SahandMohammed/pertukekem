import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {  final String userId;
  final String firstName;
  final String lastName;
  final String? storeName;
  final String? storeId;
  final String email;
  final String emailLowercase;
  final String phoneNumber;
  final List<String> roles;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastLoginAt;
  final String createdByApp;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final bool isBlocked;
  final List<dynamic> addresses;
  final List<dynamic> favorites;
  final String? profilePicture;  UserModel({
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.storeName,
    this.storeId,
    required this.email,
    required this.emailLowercase,
    required this.phoneNumber,
    required this.roles,
    required this.createdAt,
    required this.updatedAt,
    required this.lastLoginAt,
    required this.createdByApp,
    required this.isEmailVerified,
    required this.isPhoneVerified,
    required this.isBlocked,
    required this.addresses,
    required this.favorites,
    this.profilePicture,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(      userId: map['userId'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      storeName: map['storeName'],
      storeId: map['storeId'],
      email: map['email'] ?? '',
      emailLowercase: map['email_lowercase'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      roles: List<String>.from(map['roles'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt:
          (map['lastLoginAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdByApp: map['createdByApp'] ?? '',
      isEmailVerified: map['isEmailVerified'] ?? false,
      isPhoneVerified: map['isPhoneVerified'] ?? false,
      isBlocked: map['isBlocked'] ?? false,
      addresses: List<dynamic>.from(map['addresses'] ?? []),
      favorites: List<dynamic>.from(map['favorites'] ?? []),
      profilePicture: map['profilePicture'],
    );
  }

  Map<String, dynamic> toMap() {
    return {      'userId': userId,
      'firstName': firstName,
      'lastName': lastName,
      'storeName': storeName,
      'storeId': storeId,
      'email': email,
      'email_lowercase': emailLowercase,
      'phoneNumber': phoneNumber,
      'roles': roles,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
      'createdByApp': createdByApp,
      'isEmailVerified': isEmailVerified,
      'isPhoneVerified': isPhoneVerified,
      'isBlocked': isBlocked,
      'addresses': addresses,
      'favorites': favorites,
      'profilePicture': profilePicture,
    };
  }

  UserModel copyWith({
    String? userId,
    String? firstName,
    String? lastName,
    String? storeName,
    String? storeId, 
    String? email,
    String? emailLowercase,
    String? phoneNumber,
    List<String>? roles,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    String? createdByApp,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    bool? isBlocked,
    List<dynamic>? addresses,
    List<dynamic>? favorites,
    String? profilePicture,
  }) {    return UserModel(
      userId: userId ?? this.userId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      storeName: storeName ?? this.storeName,
      storeId: storeId ?? this.storeId,
      email: email ?? this.email,
      emailLowercase: emailLowercase ?? this.emailLowercase,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      roles: roles ?? this.roles,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdByApp: createdByApp ?? this.createdByApp,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      isBlocked: isBlocked ?? this.isBlocked,
      addresses: addresses ?? this.addresses,
      favorites: favorites ?? this.favorites,
      profilePicture: profilePicture ?? this.profilePicture,
    );
  }
}
