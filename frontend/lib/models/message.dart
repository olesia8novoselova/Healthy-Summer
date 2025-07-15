class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
  id         : json['id']            ?? json['ID']            ?? '',
  senderId   : json['sender_id']     ?? json['SenderID']      ?? '',
  receiverId : json['receiver_id']   ?? json['ReceiverID']    ?? '',
  text       : json['text']          ?? json['Text']          ?? '',
  createdAt  : DateTime.tryParse(
                 (json['created_at'] ?? json['CreatedAt'] ?? DateTime.now().toIso8601String())
               ) ?? DateTime.now(),
);


  Map<String, dynamic> toJson() => {
    'id': id,
    'sender_id': senderId,
    'receiver_id': receiverId,
    'text': text,
    'created_at': createdAt.toIso8601String(),
  };
}
