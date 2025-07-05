class UserProfile {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'],
        name: json['name'],
        email: json['email'],
        avatarUrl: json['avatarUrl'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'avatarUrl': avatarUrl,
      };
}
