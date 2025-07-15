class PostActivity {
  final String id;
  final String userId;
  final String type;
  final String message;
  final DateTime createdAt;
  final String userName;

  PostActivity({
    required this.id,
    required this.userId,
    required this.type,
    required this.message,
    required this.createdAt,
    required this.userName,
  });

  factory PostActivity.fromJson(Map<String, dynamic> json) => PostActivity(
        id: json['id'],
        userId: json['userId'],
        type: json['type'],
        message: json['message'],
        createdAt: DateTime.parse(json['createdAt']),
        userName: json['user_name'] ?? '',
      );
}