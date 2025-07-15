class FriendRequest {
  final String id;
  final String name;
  final String email;

  FriendRequest({
    required this.id,
    required this.name,
    required this.email,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) => FriendRequest(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
  );
}