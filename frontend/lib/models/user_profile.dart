class UserProfile {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final double? weight;
  final double? height;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    this.weight,
    this.height,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'],
        name: json['name'],
        email: json['email'],
        avatarUrl: json['avatarUrl'] ?? '',
         weight: json['weight'] != null ? (json['weight'] as num).toDouble() : null,
        height: json['height'] != null ? (json['height'] as num).toDouble() : null,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'avatarUrl': avatarUrl,
        'weight': weight,
        'height': height,
      };
}
