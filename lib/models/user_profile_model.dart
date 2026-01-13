class UserProfileModel {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final String? phone;

  UserProfileModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.phone,
  });

  factory UserProfileModel.fromMap(Map<String, dynamic> map) {
    return UserProfileModel(
      id: map['id'],
      fullName: map['full_name'] ?? 'User',
      email: map['email'] ?? '',
      role: map['role'] ?? 'user',
      phone: map['phone'],
    );
  }
}
