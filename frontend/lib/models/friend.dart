class Friend {
  final String id;
  final String name;
  final String email;

  final bool isRequest;

  Friend({
    required this.id,
    required this.name,
    required this.email,
    this.isRequest = false,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id:    json['id']    as String,
      name:  json['name']  as String,
      email: json['email'] as String,
    );
  }
  
  factory Friend.fromRequestJson(Map<String, dynamic> json) {
    return Friend(
      id:       json['id']              as String,
      name:     json['fromUserName']    as String,
      email:    json['fromUserEmail']   as String,
      isRequest: true,
    );
  }
}
