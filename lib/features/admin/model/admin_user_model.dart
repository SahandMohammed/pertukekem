import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUserModel {
  final String userId;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final List<String> roles;
  final bool isBlocked;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final String? profilePicture;
  final String? storeId;
  final String? storeName;

  AdminUserModel({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.roles,
    required this.isBlocked,
    required this.isEmailVerified,
    required this.isPhoneVerified,
    required this.createdAt,
    required this.lastLoginAt,
    this.profilePicture,
    this.storeId,
    this.storeName,
  });

  factory AdminUserModel.fromMap(Map<String, dynamic> map) {
    return AdminUserModel(
      userId: map['userId'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      roles: List<String>.from(map['roles'] ?? []),
      isBlocked: map['isBlocked'] ?? false,
      isEmailVerified: map['isEmailVerified'] ?? false,
      isPhoneVerified: map['isPhoneVerified'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt:
          (map['lastLoginAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      profilePicture: map['profilePicture'],
      storeId: map['storeId'],
      storeName: map['storeName'],
    );
  }

  String get fullName => '$firstName $lastName';
  String get userType => isStoreOwner ? 'Store Owner' : 'Customer';

  bool get isStoreOwner =>
      roles.contains('store_owner') || roles.contains('store');

  bool get isCustomer =>
      roles.contains('customer') || (!roles.contains('admin') && !isStoreOwner);
}
