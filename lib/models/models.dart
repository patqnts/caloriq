// lib/models/models.dart

class UserProfile {
  final String name;
  final double currentWeight;
  final double targetWeight;
  final double heightCm;
  final int age;
  final String gender;
  final String activityLevel;
  final double calorieDeficit;
  final String weightUnit;

  const UserProfile({
    this.name = '',
    this.currentWeight = 70,
    this.targetWeight = 65,
    this.heightCm = 170,
    this.age = 25,
    this.gender = 'male',
    this.activityLevel = 'sedentary',
    this.calorieDeficit = 500,
    this.weightUnit = 'kg',
  });

  bool get isGaining => targetWeight > currentWeight;

  double get tdee {
    double bmr;
    if (gender == 'male') {
      bmr = 10 * currentWeight + 6.25 * heightCm - 5 * age + 5;
    } else {
      bmr = 10 * currentWeight + 6.25 * heightCm - 5 * age - 161;
    }
    const multipliers = {
      'sedentary': 1.2,
      'light': 1.375,
      'moderate': 1.55,
      'active': 1.725,
      'very_active': 1.9,
    };
    return bmr * (multipliers[activityLevel] ?? 1.2);
  }

  double get dailyCalorieGoal =>
      isGaining ? tdee + calorieDeficit : tdee - calorieDeficit;

  double get bmi => currentWeight / ((heightCm / 100) * (heightCm / 100));

  int get daysToGoal {
    final weightDiff = (targetWeight - currentWeight).abs();
    if (weightDiff <= 0) return 0;
    final daysPerKg = 7700 / calorieDeficit;
    return (weightDiff * daysPerKg).round();
  }

  DateTime get estimatedGoalDate =>
      DateTime.now().add(Duration(days: daysToGoal));

  UserProfile copyWith({
    String? name,
    double? currentWeight,
    double? targetWeight,
    double? heightCm,
    int? age,
    String? gender,
    String? activityLevel,
    double? calorieDeficit,
    String? weightUnit,
  }) =>
      UserProfile(
        name: name ?? this.name,
        currentWeight: currentWeight ?? this.currentWeight,
        targetWeight: targetWeight ?? this.targetWeight,
        heightCm: heightCm ?? this.heightCm,
        age: age ?? this.age,
        gender: gender ?? this.gender,
        activityLevel: activityLevel ?? this.activityLevel,
        calorieDeficit: calorieDeficit ?? this.calorieDeficit,
        weightUnit: weightUnit ?? this.weightUnit,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'currentWeight': currentWeight,
        'targetWeight': targetWeight,
        'heightCm': heightCm,
        'age': age,
        'gender': gender,
        'activityLevel': activityLevel,
        'calorieDeficit': calorieDeficit,
        'weightUnit': weightUnit,
      };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        name: j['name'] ?? '',
        currentWeight: (j['currentWeight'] ?? 70).toDouble(),
        targetWeight: (j['targetWeight'] ?? 65).toDouble(),
        heightCm: (j['heightCm'] ?? 170).toDouble(),
        age: j['age'] ?? 25,
        gender: j['gender'] ?? 'male',
        activityLevel: j['activityLevel'] ?? 'sedentary',
        calorieDeficit: (j['calorieDeficit'] ?? 500).toDouble(),
        weightUnit: j['weightUnit'] ?? 'kg',
      );
}

class WeightEntry {
  final int? id;
  final DateTime date;
  final double morningWeight;
  final double? eveningWeight;
  final String? note;

  const WeightEntry({
    this.id,
    required this.date,
    required this.morningWeight,
    this.eveningWeight,
    this.note,
  });

  double get averageWeight =>
      eveningWeight != null
          ? (morningWeight + eveningWeight!) / 2
          : morningWeight;

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'date': date.toIso8601String().substring(0, 10),
        'morningWeight': morningWeight,
        'eveningWeight': eveningWeight,
        'note': note,
      };

  factory WeightEntry.fromMap(Map<String, dynamic> m) => WeightEntry(
        id: m['id'],
        date: DateTime.parse(m['date']),
        morningWeight: (m['morningWeight'] ?? 0).toDouble(),
        eveningWeight:
            m['eveningWeight'] != null ? (m['eveningWeight']).toDouble() : null,
        note: m['note'],
      );
}

class FoodItem {
  final String barcode;
  final String name;
  final String brand;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final String? imageUrl;

  const FoodItem({
    required this.barcode,
    required this.name,
    this.brand = '',
    required this.caloriesPer100g,
    this.proteinPer100g = 0,
    this.carbsPer100g = 0,
    this.fatPer100g = 0,
    this.imageUrl,
  });

  double caloriesForAmount(double g) => caloriesPer100g * g / 100;
  double proteinForAmount(double g)  => proteinPer100g * g / 100;
  double carbsForAmount(double g)    => carbsPer100g * g / 100;
  double fatForAmount(double g)      => fatPer100g * g / 100;

  Map<String, dynamic> toMap() => {
        'barcode': barcode,
        'name': name,
        'brand': brand,
        'caloriesPer100g': caloriesPer100g,
        'proteinPer100g': proteinPer100g,
        'carbsPer100g': carbsPer100g,
        'fatPer100g': fatPer100g,
        'imageUrl': imageUrl,
      };

  factory FoodItem.fromMap(Map<String, dynamic> m) => FoodItem(
        barcode: m['barcode'] ?? '',
        name: m['name'] ?? '',
        brand: m['brand'] ?? '',
        caloriesPer100g: (m['caloriesPer100g'] ?? 0).toDouble(),
        proteinPer100g:  (m['proteinPer100g'] ?? 0).toDouble(),
        carbsPer100g:    (m['carbsPer100g'] ?? 0).toDouble(),
        fatPer100g:      (m['fatPer100g'] ?? 0).toDouble(),
        imageUrl: m['imageUrl'],
      );
}

enum MealType { breakfast, lunch, dinner, snacks, exercise }

extension MealTypeExt on MealType {
  String get label {
    switch (this) {
      case MealType.breakfast: return 'Breakfast';
      case MealType.lunch:     return 'Lunch';
      case MealType.dinner:    return 'Dinner';
      case MealType.snacks:    return 'Snacks';
      case MealType.exercise:  return 'Exercise';
    }
  }

  String get emoji {
    switch (this) {
      case MealType.breakfast: return '🌅';
      case MealType.lunch:     return '☀️';
      case MealType.dinner:    return '🌙';
      case MealType.snacks:    return '🍎';
      case MealType.exercise:  return '🔥';
    }
  }
}

class FoodLog {
  final int? id;
  final DateTime date;
  final MealType mealType;
  final FoodItem food;
  final double amountGrams;
  final String? note;

  const FoodLog({
    this.id,
    required this.date,
    required this.mealType,
    required this.food,
    required this.amountGrams,
    this.note,
  });

  double get calories => food.caloriesForAmount(amountGrams);
  double get protein  => food.proteinForAmount(amountGrams);
  double get carbs    => food.carbsForAmount(amountGrams);
  double get fat      => food.fatForAmount(amountGrams);

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'date': date.toIso8601String().substring(0, 10),
        'mealType': mealType.index,
        'amountGrams': amountGrams,
        'note': note,
        'barcode': food.barcode,
        'foodName': food.name,
        'brand': food.brand,
        'caloriesPer100g': food.caloriesPer100g,
        'proteinPer100g': food.proteinPer100g,
        'carbsPer100g': food.carbsPer100g,
        'fatPer100g': food.fatPer100g,
        'imageUrl': food.imageUrl,
      };

  factory FoodLog.fromMap(Map<String, dynamic> m) => FoodLog(
        id: m['id'],
        date: DateTime.parse(m['date']),
        mealType: MealType.values[m['mealType'] ?? 0],
        amountGrams: (m['amountGrams'] ?? 100).toDouble(),
        note: m['note'],
        food: FoodItem(
          barcode: m['barcode'] ?? '',
          name: m['foodName'] ?? '',
          brand: m['brand'] ?? '',
          caloriesPer100g: (m['caloriesPer100g'] ?? 0).toDouble(),
          proteinPer100g:  (m['proteinPer100g'] ?? 0).toDouble(),
          carbsPer100g:    (m['carbsPer100g'] ?? 0).toDouble(),
          fatPer100g:      (m['fatPer100g'] ?? 0).toDouble(),
          imageUrl: m['imageUrl'],
        ),
      );
}

class ExerciseLog {
  final int? id;
  final DateTime date;
  final String name;
  final int durationMinutes;
  final int caloriesBurned;
  final String? source;

  const ExerciseLog({
    this.id,
    required this.date,
    required this.name,
    required this.durationMinutes,
    required this.caloriesBurned,
    this.source = 'manual',
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'date': date.toIso8601String().substring(0, 10),
        'name': name,
        'durationMinutes': durationMinutes,
        'caloriesBurned': caloriesBurned,
        'source': source,
      };

  factory ExerciseLog.fromMap(Map<String, dynamic> m) => ExerciseLog(
        id: m['id'],
        date: DateTime.parse(m['date']),
        name: m['name'] ?? '',
        durationMinutes: m['durationMinutes'] ?? 0,
        caloriesBurned: m['caloriesBurned'] ?? 0,
        source: m['source'] ?? 'manual',
      );
}

class CustomFood {
  final int? id;
  final String name;
  final String category;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final DateTime createdAt;

  const CustomFood({
    this.id,
    required this.name,
    this.category = 'My Foods',
    required this.caloriesPer100g,
    this.proteinPer100g = 0,
    this.carbsPer100g = 0,
    this.fatPer100g = 0,
    required this.createdAt,
  });

  FoodItem toFoodItem() => FoodItem(
        barcode: 'custom_${id ?? name.toLowerCase().replaceAll(' ', '_')}',
        name: name,
        brand: 'My Foods',
        caloriesPer100g: caloriesPer100g,
        proteinPer100g: proteinPer100g,
        carbsPer100g: carbsPer100g,
        fatPer100g: fatPer100g,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'category': category,
        'caloriesPer100g': caloriesPer100g,
        'proteinPer100g': proteinPer100g,
        'carbsPer100g': carbsPer100g,
        'fatPer100g': fatPer100g,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CustomFood.fromMap(Map<String, dynamic> m) => CustomFood(
        id: m['id'],
        name: m['name'] ?? '',
        category: m['category'] ?? 'My Foods',
        caloriesPer100g: (m['caloriesPer100g'] ?? 0).toDouble(),
        proteinPer100g: (m['proteinPer100g'] ?? 0).toDouble(),
        carbsPer100g: (m['carbsPer100g'] ?? 0).toDouble(),
        fatPer100g: (m['fatPer100g'] ?? 0).toDouble(),
        createdAt: DateTime.parse(
            m['createdAt'] ?? DateTime.now().toIso8601String()),
      );
}