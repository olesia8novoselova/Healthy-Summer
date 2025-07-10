class Meal {
  final String id;
  final String description;
  final int fdcId;
  final double calories, protein, fat, carbs, quantity;
  final String unit;
  final DateTime eatenAt;

  Meal({
    required this.id,
    required this.description,
    required this.fdcId,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.quantity,
    required this.unit,
    required this.eatenAt,
  });

  factory Meal.fromJson(Map<String, dynamic> json) => Meal(
    id: json['id']?.toString() ?? '', // fallback to empty string
    description: json['description']?.toString() ?? '',
    fdcId: json['fdcId'] is int
        ? json['fdcId'] as int
        : int.tryParse(json['fdcId']?.toString() ?? '') ?? 0,
    calories: (json['calories'] as num?)?.toDouble() ?? 0.0,
    protein: (json['protein'] as num?)?.toDouble() ?? 0.0,
    fat: (json['fat'] as num?)?.toDouble() ?? 0.0,
    carbs: (json['carbs'] as num?)?.toDouble() ?? 0.0,
    quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
    unit: json['unit']?.toString() ?? '',
    eatenAt: DateTime.tryParse(json['eatenAt']?.toString() ?? '') ?? DateTime.now(),
  );
}
