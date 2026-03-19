// lib/providers/app_provider.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/database_service.dart';

class AppProvider extends ChangeNotifier {
  UserProfile _profile = const UserProfile();
  List<WeightEntry> _weightEntries = [];
  List<FoodLog> _foodLogs = [];
  List<ExerciseLog> _exerciseLogs = [];
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  Map<String, double> _weeklyCalories = {};
  bool _profileSetup = false;
  ThemeMode _themeMode = ThemeMode.light;

  UserProfile get profile => _profile;
  List<WeightEntry> get weightEntries => _weightEntries;
  List<FoodLog> get foodLogs => _foodLogs;
  List<ExerciseLog> get exerciseLogs => _exerciseLogs;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  Map<String, double> get weeklyCalories => _weeklyCalories;
  bool get profileSetup => _profileSetup;
  ThemeMode get themeMode => _themeMode;

  double get todayCaloriesConsumed =>
      _foodLogs.fold(0, (s, l) => s + l.calories);
  double get todayCaloriesBurned =>
      _exerciseLogs.fold(0, (s, l) => s + l.caloriesBurned);
  double get todayNetCalories => todayCaloriesConsumed - todayCaloriesBurned;
  double get todayCaloriesRemaining =>
      _profile.dailyCalorieGoal - todayNetCalories;
  double get todayProtein => _foodLogs.fold(0, (s, l) => s + l.protein);
  double get todayCarbs   => _foodLogs.fold(0, (s, l) => s + l.carbs);
  double get todayFat     => _foodLogs.fold(0, (s, l) => s + l.fat);

  List<CustomFood> _customFoods = [];
  List<CustomFood> get customFoods => _customFoods;

  WeightEntry? get todayWeight {
    final ds = _selectedDate.toIso8601String().substring(0, 10);
    try {
      return _weightEntries.firstWhere(
          (e) => e.date.toIso8601String().substring(0, 10) == ds);
    } catch (_) {
      return null;
    }
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _loadProfile();
      _foodLogs = await DatabaseService.instance.getFoodLogsForDate(_selectedDate);
      _exerciseLogs = await DatabaseService.instance.getExerciseLogsForDate(_selectedDate);
      _weightEntries = await DatabaseService.instance.getWeightEntries();
      _weeklyCalories = await DatabaseService.instance.getCaloriesLast7Days();
      _customFoods = await DatabaseService.instance.getCustomFoods();
    } catch (e) {
      debugPrint('init error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('user_profile');
    if (json != null) {
      _profile = UserProfile.fromJson(jsonDecode(json));
      _profileSetup = true;
    }
    final theme = prefs.getString('theme_mode');
    if (theme != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (e) => e.name == theme,
        orElse: () => ThemeMode.light,
      );
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    _profile = profile;
    _profileSetup = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile', jsonEncode(profile.toJson()));
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.name);
    notifyListeners();
  }

  Future<void> setSelectedDate(DateTime date) async {
    _selectedDate = date;
    await loadDataForDate(date);
    notifyListeners();
  }

  Future<void> loadDataForDate(DateTime date) async {
    _foodLogs = await DatabaseService.instance.getFoodLogsForDate(date);
    _exerciseLogs = await DatabaseService.instance.getExerciseLogsForDate(date);
    notifyListeners();
  }

  Future<void> loadWeightEntries() async {
    _weightEntries = await DatabaseService.instance.getWeightEntries();
    notifyListeners();
  }

  Future<void> loadWeeklyCalories() async {
    _weeklyCalories = await DatabaseService.instance.getCaloriesLast7Days();
    notifyListeners();
  }

  Future<void> saveWeightEntry(WeightEntry entry) async {
    await DatabaseService.instance.saveWeightEntry(entry);
    await loadWeightEntries();
    notifyListeners();
  }

  Future<void> deleteWeightEntry(int id) async {
    await DatabaseService.instance.deleteWeightEntry(id);
    await loadWeightEntries();
    notifyListeners();
  }

  Future<void> saveFoodLog(FoodLog log) async {
    await DatabaseService.instance.saveFoodLog(log);
    await loadDataForDate(_selectedDate);
    await loadWeeklyCalories();
    notifyListeners();
  }

  Future<void> deleteFoodLog(int id) async {
    await DatabaseService.instance.deleteFoodLog(id);
    await loadDataForDate(_selectedDate);
    await loadWeeklyCalories();
    notifyListeners();
  }

  Future<void> saveExerciseLog(ExerciseLog log) async {
    await DatabaseService.instance.saveExerciseLog(log);
    await loadDataForDate(_selectedDate);
    notifyListeners();
  }

  Future<void> deleteExerciseLog(int id) async {
    await DatabaseService.instance.deleteExerciseLog(id);
    await loadDataForDate(_selectedDate);
    notifyListeners();
  }

  Future<List<FoodItem>> getRecentFoods() =>
      DatabaseService.instance.getRecentFoods();

  List<FoodLog> getFoodLogsByMeal(MealType meal) =>
      _foodLogs.where((l) => l.mealType == meal).toList();

  Future<void> loadCustomFoods() async {
  _customFoods = await DatabaseService.instance.getCustomFoods();
  notifyListeners();
  }

  Future<void> saveCustomFood(CustomFood food) async {
    await DatabaseService.instance.saveCustomFood(food);
    await loadCustomFoods();
  }

  Future<void> deleteCustomFood(int id) async {
    await DatabaseService.instance.deleteCustomFood(id);
    await loadCustomFoods();
  }

  Future<void> updateCustomFood(CustomFood food) async {
    await DatabaseService.instance.updateCustomFood(food);
    await loadCustomFoods();
  }

}
