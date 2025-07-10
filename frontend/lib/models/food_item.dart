class FoodItem {
  final String description;
  final int fdcId;
  final Map<String, num> macros;

  FoodItem({
    required this.description,
    required this.fdcId,
    required this.macros,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    final nutrients = <String, num>{};

    // Go through the nutrients list and extract values
    for (var item in json['foodNutrients']) {
      final name = item['nutrientName']?.toString().toLowerCase();
      final value = item['value'];
      if (value == null) continue;

      if (name == 'energy' || name == 'energy (kcal)' || name == 'calories') {
        nutrients['calories'] = (value as num);
      } else if (name == 'protein') {
        nutrients['protein'] = (value as num);
      } else if (name == 'total lipid (fat)' || name == 'fat') {
        nutrients['fat'] = (value as num);
      } else if (name == 'carbohydrate, by difference' || name == 'carbohydrates') {
        nutrients['carbs'] = (value as num);
      }
    }

    return FoodItem(
      description: json['description'] ?? 'Unknown',
      fdcId: json['fdcId'],
      macros: nutrients,
    );
  }
}
