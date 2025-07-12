class FriendRequest {
  final String id;
  final String fromUserId;
  final String fromUserName;
  final String fromUserEmail;

  FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.fromUserName,
    required this.fromUserEmail,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) => FriendRequest(
        id: json['id']             as String,
        fromUserId: json['fromUserId']     as String,
        fromUserName: json['fromUserName'] as String,
        fromUserEmail: json['fromUserEmail'] as String,
      );
}