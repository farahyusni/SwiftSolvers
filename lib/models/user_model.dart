class User {
  final String id;
  final String email;
  final String? displayName;
  final String? fullName;
  final String? phone;
  final String? address;
  final String? userType; // e.g., 'buyer' or 'seller'

  User({
    required this.id,
    required this.email,
    this.displayName,
    this.fullName,
    this.phone,
    this.address,
    this.userType,
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
    };
  }
}
