class Challenge {
  final String id;
  final String title;
  final String type;
  final int    target;
  Challenge({required this.id, required this.title, required this.type, required this.target});

  factory Challenge.fromJson(Map<String,dynamic> j) => Challenge(
    id:     j['id'],
    title:  j['title'],
    type:   j['type'],
    target: (j['target'] as num).toInt(), 
  );
}

class Participant {
  final String userId;
  final int    progress;
  Participant(this.userId,this.progress);

  factory Participant.fromJson(Map<String,dynamic> j) => Participant(
  j['user_id'],
  (j['progress'] as num).toInt(),
);
}