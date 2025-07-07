class Achievement {
  final String id;
  final String title;
  final bool unlocked;

  Achievement({
    required this.id,
    required this.title,
    required this.unlocked,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
        id: json['id'],
        title: json['title'],
        unlocked: json['unlocked'] as bool,
      );
}
