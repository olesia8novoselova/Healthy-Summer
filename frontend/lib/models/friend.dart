class Friend {
  final String id;
  final String name;
  final String email;

  Friend({required this.id, required this.name, required this.email});

  factory Friend.fromJson(Map<String, dynamic> json) => Friend(
        id: json['id'],
        name: json['name'],
        email: json['email'],
      );
}
