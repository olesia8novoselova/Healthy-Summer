class Activity {
  final String id;
  final String type;
  final String name;
  final int duration;
  final String intensity;
  final int calories;
  final String location;
  final DateTime performedAt;

  Activity({
    required this.id,
    required this.type,
    required this.name,
    required this.duration,
    required this.intensity,
    required this.calories,
    required this.location,
    required this.performedAt,
  });

  factory Activity.fromJson(Map<String, dynamic> json) => Activity(
        id: json['id'],
        type: json['type'],
        name: json['name'],
        duration: json['duration'],
        intensity: json['intensity'],
        calories: json['calories'],
        location: json['location'],
        performedAt: DateTime.parse(json['performedAt']),
      );
}
