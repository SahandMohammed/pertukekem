class AddressModel {
  final String id;
  final String name;
  final String streetAddress;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final String? additionalInfo;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  AddressModel({
    required this.id,
    required this.name,
    required this.streetAddress,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    this.additionalInfo,
    required this.isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory AddressModel.fromMap(Map<String, dynamic> map) {
    return AddressModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      streetAddress: map['streetAddress'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      postalCode: map['postalCode'] ?? '',
      country: map['country'] ?? '',
      additionalInfo: map['additionalInfo'],
      isDefault: map['isDefault'] ?? false,
      createdAt:
          map['createdAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
              : DateTime.now(),
      updatedAt:
          map['updatedAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'streetAddress': streetAddress,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'country': country,
      'additionalInfo': additionalInfo,
      'isDefault': isDefault,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  AddressModel copyWith({
    String? id,
    String? name,
    String? streetAddress,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    String? additionalInfo,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AddressModel(
      id: id ?? this.id,
      name: name ?? this.name,
      streetAddress: streetAddress ?? this.streetAddress,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get fullAddress {
    final parts = <String>[
      streetAddress,
      if (additionalInfo?.isNotEmpty == true) additionalInfo!,
      city,
      state,
      postalCode,
      country,
    ];
    return parts.join(', ');
  }

  @override
  String toString() {
    return 'AddressModel(id: $id, name: $name, fullAddress: $fullAddress, isDefault: $isDefault)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AddressModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
