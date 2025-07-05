class Achievement {
  final String id;
  final String title;
  final String iconUrl;
  final bool unlocked;

  Achievement({
    required this.id,
    required this.title,
    required this.iconUrl,
    required this.unlocked,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
        id: json['id'],
        title: json['title'],
        iconUrl: json['iconUrl'],
        unlocked: json['unlocked'] as bool,
      );
}
