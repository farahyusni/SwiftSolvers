class User {
  final String id;
  final String email;
  final String? displayName;
  final String? fullName;
  final String? phone;
  final String? address;
  final String? userType; // e.g., 'buyer' or 'seller'
  final String? profileImageUrl; // Add this field

  User({
    required this.id,
    required this.email,
    this.displayName,
    this.fullName,
    this.phone,
    this.address,
    this.userType,
    this.profileImageUrl, // Add this parameter
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'],
      fullName: json['fullName'],
      phone: json['phone'],
      address: json['address'],
      userType: json['userType'],
      profileImageUrl: json['profileImageUrl'], // Add this line
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'fullName': fullName,
      'phone': phone,
      'address': address,
      'userType': userType,
      'profileImageUrl': profileImageUrl, // Add this line
    };
  }

  // Add a copyWith method for easy updates
  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? fullName,
    String? phone,
    String? address,
    String? userType,
    String? profileImageUrl,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      userType: userType ?? this.userType,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}