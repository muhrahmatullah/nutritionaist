class NutritionInfo {
  final bool relevant;
  final String protein;
  final String carbs;
  final String fat;
  final String calories;

  NutritionInfo({
    required this.relevant,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.calories,
  });

  factory NutritionInfo.fromJson(Map<String, dynamic> json) {
    return NutritionInfo(
      relevant: json['relevant'],
      protein: json['protein'] ?? '',
      carbs: json['carbs'] ?? '',
      fat: json['fat'] ?? '',
      calories: json['Calories'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'relevant': relevant,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'Calories': calories,
    };
  }
}