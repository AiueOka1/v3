class User {
  final String id;
  final String name;
  final String email;
  final String role; // 'admin', 'handler', 'veterinarian'
  final String department;
  final String profileImageUrl;
  final String phoneNumber;
  final String badgeNumber;
  final List<String> assignedDogIds;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    required this.profileImageUrl,
    required this.phoneNumber,
    required this.badgeNumber,
    required this.assignedDogIds,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      department: json['department'],
      profileImageUrl: json['profileImageUrl'],
      phoneNumber: json['phoneNumber'],
      badgeNumber: json['badgeNumber'],
      assignedDogIds:
          (json['assignedDogIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'department': department,
      'profileImageUrl': profileImageUrl,
      'phoneNumber': phoneNumber,
      'badgeNumber': badgeNumber,
      'assignedDogIds': assignedDogIds,
    };
  }
}
