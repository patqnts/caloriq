// lib/services/food_api_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class FoodApiService {
  static const _usdaBase = 'https://api.nal.usda.gov/fdc/v1';
  static const _usdaKey  = 'DEMO_KEY';

  static List<FoodItem> searchLocal(String query) {
    if (query.trim().isEmpty) return [];
    final q = query.toLowerCase().trim();
    return _db
        .where((f) =>
            f.name.toLowerCase().contains(q) ||
            f.brand.toLowerCase().contains(q))
        .toList();
  }

  static Future<List<FoodItem>> searchUsda(String query) async {
    try {
      final uri = Uri.parse(
        '$_usdaBase/foods/search'
        '?query=${Uri.encodeComponent(query)}'
        '&dataType=SR%20Legacy,Foundation,Branded'
        '&pageSize=20'
        '&api_key=$_usdaKey',
      );
      final res = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'caloriq-app/1.0',
      }).timeout(const Duration(seconds: 12));

      debugPrint('USDA status: ${res.statusCode}');
      if (res.statusCode == 429) {
        debugPrint('USDA rate limited');
        return [];
      }
      if (res.statusCode != 200) {
        debugPrint('USDA error body: ${res.body}');
        return [];
      }
      final data = jsonDecode(res.body);
      final foods = data['foods'] as List? ?? [];
      return foods.map(_fromUsda).where((f) => f.caloriesPer100g > 0).toList();
    } catch (e) {
      debugPrint('USDA search error: $e');
      return [];
    }
  }

  static FoodItem _fromUsda(dynamic item) {
    final nutrients = (item['foodNutrients'] as List? ?? []);
    double get(int id) {
      try {
        return (nutrients.firstWhere(
                  (n) => n['nutrientId'] == id,
                  orElse: () => {'value': 0},
                )['value'] as num?)
                ?.toDouble() ??
            0;
      } catch (_) {
        return 0;
      }
    }
    return FoodItem(
      barcode: 'usda_${item['fdcId']}',
      name: _cleanName(item['description'] ?? ''),
      brand: item['brandOwner'] ?? item['foodCategory'] ?? 'USDA',
      caloriesPer100g: get(1008),
      proteinPer100g:  get(1003),
      carbsPer100g:    get(1005),
      fatPer100g:      get(1004),
    );
  }

  static String _cleanName(String raw) {
    if (raw == raw.toUpperCase()) {
      return raw.toLowerCase().split(' ').map((w) =>
          w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
    }
    return raw;
  }

  static List<FoodItem> get allFoods => _db;
  static List<String> get categories =>
      _db.map((f) => f.brand).toSet().toList();
  static List<FoodItem> byCategory(String cat) =>
      _db.where((f) => f.brand == cat).toList();

  static final List<FoodItem> _db = [
    // Rice & Grains
    _f('White Rice (cooked)',          'Rice & Grains', 130, 2.7, 28.2, 0.3),
    _f('Brown Rice (cooked)',           'Rice & Grains', 112, 2.3, 24.0, 0.8),
    _f('Sinangag (Garlic Fried Rice)', 'Rice & Grains', 163, 3.2, 30.0, 3.5),
    _f('Lugaw (Rice Porridge)',         'Rice & Grains',  65, 1.5, 14.0, 0.2),
    _f('Oatmeal (cooked)',              'Rice & Grains',  71, 2.5, 12.0, 1.4),
    _f('Rolled Oats (dry)',             'Rice & Grains', 389,17.0, 66.0, 7.0),
    _f('Pandesal',                      'Rice & Grains', 285, 8.5, 52.0, 5.0),
    _f('White Bread',                   'Rice & Grains', 265, 9.0, 49.0, 3.2),
    _f('Whole Wheat Bread',             'Rice & Grains', 247,13.0, 41.0, 4.2),
    // Chicken
    _f('Chicken Breast (grilled)',   'Chicken', 165,31.0, 0.0, 3.6),
    _f('Chicken Breast (boiled)',    'Chicken', 150,29.0, 0.0, 3.2),
    _f('Chicken Thigh (grilled)',    'Chicken', 209,26.0, 0.0,11.0),
    _f('Chicken Drumstick (grilled)','Chicken', 195,28.0, 0.0, 9.0),
    _f('Chicken Adobo',              'Chicken', 210,24.0, 2.5,11.0),
    _f('Tinolang Manok',             'Chicken',  95,14.0, 3.0, 3.0),
    _f('Lechon Manok (skin off)',    'Chicken', 185,27.0, 1.0, 8.0),
    _f('Lechon Manok (with skin)',   'Chicken', 239,25.0, 1.0,15.0),
    _f('Chicken Liver',              'Chicken', 119,17.0, 0.7, 4.8),
    _f('Chicken Sisig',              'Chicken', 230,22.0, 3.0,14.0),
    // Pork
    _f('Pork Belly / Liempo (grilled)','Pork', 395,19.0, 0.0,35.0),
    _f('Pork Loin (grilled)',          'Pork', 185,27.0, 0.0, 8.0),
    _f('Pork Adobo',                   'Pork', 285,22.0, 2.5,21.0),
    _f('Pork Sinigang',                'Pork', 130,14.0, 4.0, 6.5),
    _f('Pork Sisig',                   'Pork', 310,20.0, 4.0,24.0),
    _f('Longganisa',                   'Pork', 298,15.0,10.0,22.0),
    _f('Tocino',                       'Pork', 255,18.0,14.0,13.0),
    _f('Lechon Baboy (skin off)',       'Pork', 280,24.0, 0.0,20.0),
    // Beef
    _f('Beef (lean, grilled)',  'Beef', 215,26.0, 0.0,12.0),
    _f('Beef Tapa',             'Beef', 218,26.0, 5.0,10.0),
    _f('Beef Sinigang',         'Beef', 165,18.0, 4.0, 8.0),
    _f('Beef Kaldereta',        'Beef', 210,17.0, 8.0,12.0),
    _f('Bulalo (beef shank)',   'Beef', 180,20.0, 1.0,10.0),
    _f('Ground Beef (cooked)',  'Beef', 250,26.0, 0.0,16.0),
    // Fish & Seafood
    _f('Bangus / Milkfish (grilled)',     'Fish & Seafood', 148,22.0, 0.0, 6.5),
    _f('Tilapia (grilled)',               'Fish & Seafood', 128,26.0, 0.0, 2.6),
    _f('Galunggong / Round Scad (fried)', 'Fish & Seafood', 175,22.0, 0.0, 9.5),
    _f('Tuna (canned in water)',          'Fish & Seafood', 116,26.0, 0.0, 1.0),
    _f('Tuna (canned in oil, drained)',   'Fish & Seafood', 198,29.0, 0.0, 8.2),
    _f('Sardines (canned)',               'Fish & Seafood', 208,25.0, 0.0,11.0),
    _f('Squid / Pusit (grilled)',         'Fish & Seafood',  92,16.0, 3.0, 1.4),
    _f('Shrimp / Hipon (boiled)',         'Fish & Seafood',  99,24.0, 0.0, 0.3),
    _f('Mussels / Tahong (boiled)',       'Fish & Seafood',  86,12.0, 4.0, 2.2),
    _f('Tinapa (smoked fish)',            'Fish & Seafood', 190,28.0, 0.0, 8.5),
    _f('Daing na Bangus (fried)',         'Fish & Seafood', 210,25.0, 0.0,12.0),
    _f('Century Tuna (in water)',         'Fish & Seafood', 100,22.0, 0.0, 1.0),
    // Eggs & Dairy
    _f('Whole Egg (boiled)',          'Eggs & Dairy', 155,13.0, 1.1,11.0),
    _f('Egg White (boiled)',          'Eggs & Dairy',  52,11.0, 0.7, 0.2),
    _f('Egg Yolk',                    'Eggs & Dairy', 322,16.0, 3.6,27.0),
    _f('Scrambled Eggs (no butter)',  'Eggs & Dairy', 149,10.0, 1.6,11.0),
    _f('Fried Egg (minimal oil)',     'Eggs & Dairy', 196,14.0, 0.0,15.0),
    _f('Itlog na Maalat (salted egg)','Eggs & Dairy', 203,13.0, 1.4,16.0),
    _f('Milk (full cream)',           'Eggs & Dairy',  61, 3.2, 4.8, 3.3),
    _f('Milk (low fat)',              'Eggs & Dairy',  42, 3.4, 5.0, 1.0),
    _f('Greek Yogurt (plain)',        'Eggs & Dairy',  59,10.0, 3.6, 0.4),
    _f('Cheese (quick melt)',         'Eggs & Dairy', 340,22.0, 3.0,27.0),
    // Vegetables
    _f('Kangkong / Water Spinach',          'Vegetables',  19, 2.6, 3.1, 0.2),
    _f('Pechay / Bok Choy',                 'Vegetables',  13, 1.5, 2.2, 0.2),
    _f('Sitaw / Long Beans',                'Vegetables',  47, 2.8, 8.4, 0.4),
    _f('Ampalaya / Bitter Gourd',           'Vegetables',  17, 1.0, 3.7, 0.2),
    _f('Malunggay / Moringa',               'Vegetables',  64, 9.4, 8.3, 1.4),
    _f('Camote Tops / Sweet Potato Leaves', 'Vegetables',  44, 3.0, 9.0, 0.5),
    _f('Upo / Bottle Gourd',                'Vegetables',  14, 0.6, 3.4, 0.0),
    _f('Talong / Eggplant',                 'Vegetables',  25, 1.0, 6.0, 0.2),
    _f('Okra (boiled)',                     'Vegetables',  33, 1.9, 7.5, 0.2),
    _f('Sayote / Chayote',                  'Vegetables',  24, 0.8, 5.9, 0.1),
    _f('Tomato',                            'Vegetables',  18, 0.9, 3.9, 0.2),
    _f('Onion',                             'Vegetables',  40, 1.1, 9.3, 0.1),
    _f('Garlic',                            'Vegetables', 149, 6.4,33.0, 0.5),
    _f('Broccoli (steamed)',                'Vegetables',  35, 2.4, 7.2, 0.4),
    _f('Carrots (cooked)',                  'Vegetables',  35, 0.8, 8.2, 0.2),
    _f('Spinach (cooked)',                  'Vegetables',  23, 2.9, 3.6, 0.4),
    _f('Cabbage (cooked)',                  'Vegetables',  23, 1.3, 5.1, 0.1),
    _f('Cucumber',                          'Vegetables',  16, 0.7, 3.6, 0.1),
    _f('Corn (boiled)',                     'Vegetables',  96, 3.4,21.0, 1.5),
    // Root Crops
    _f('Kamote / Sweet Potato (boiled)', 'Root Crops',  90, 2.0,21.0, 0.1),
    _f('Gabi / Taro (boiled)',           'Root Crops', 112, 1.5,26.0, 0.2),
    _f('Potato (boiled)',                'Root Crops',  87, 1.9,20.0, 0.1),
    _f('Ube / Purple Yam (boiled)',      'Root Crops', 118, 1.5,27.0, 0.1),
    _f('Cassava / Kamoteng Kahoy',       'Root Crops', 160, 1.4,38.0, 0.3),
    // Legumes
    _f('Monggo / Mung Beans (cooked)',    'Legumes', 105, 7.0,19.0, 0.4),
    _f('Black Beans (cooked)',            'Legumes', 132, 8.9,24.0, 0.5),
    _f('Chickpeas / Garbanzos (cooked)', 'Legumes', 164, 8.9,27.0, 2.6),
    _f('Tokwa / Firm Tofu',              'Legumes',  76, 8.0, 2.0, 4.2),
    _f('Soft Tofu',                      'Legumes',  55, 5.6, 1.4, 3.0),
    _f('Edamame (boiled)',               'Legumes', 121,11.0, 9.0, 5.2),
    // Fruits
    _f('Banana / Saging Lakatan', 'Fruits',  89, 1.1,23.0, 0.3),
    _f('Saba Banana (boiled)',    'Fruits',  97, 1.0,25.0, 0.3),
    _f('Mango (ripe)',            'Fruits',  60, 0.8,15.0, 0.4),
    _f('Papaya (ripe)',           'Fruits',  43, 0.5,11.0, 0.3),
    _f('Pineapple',               'Fruits',  50, 0.5,13.0, 0.1),
    _f('Watermelon',              'Fruits',  30, 0.6, 7.6, 0.2),
    _f('Apple',                   'Fruits',  52, 0.3,14.0, 0.2),
    _f('Orange / Dalandan',       'Fruits',  47, 0.9,12.0, 0.1),
    _f('Avocado',                 'Fruits', 160, 2.0, 9.0,15.0),
    // Condiments & Fats
    _f('Soy Sauce / Toyo',    'Condiments',  53, 8.1, 4.9, 0.1),
    _f('Fish Sauce / Patis',  'Condiments',  35, 5.0, 3.6, 0.0),
    _f('Coconut Milk / Gata', 'Condiments', 230, 2.3, 6.0,24.0),
    _f('Coconut Oil',         'Condiments', 892, 0.0, 0.0,99.0),
    _f('Vegetable Oil',       'Condiments', 884, 0.0, 0.0,100.0),
    _f('Butter',              'Condiments', 717, 0.9, 0.1,81.0),
    _f('Mayonnaise',          'Condiments', 680, 1.0, 0.6,75.0),
    // Snacks
    _f('Peanuts (roasted)',               'Snacks', 567,26.0,16.0,49.0),
    _f('Chicharon (pork rinds)',          'Snacks', 544,61.0, 0.0,32.0),
    _f('Skyflakes Crackers',              'Snacks', 437, 9.0,71.0,13.0),
    _f('Instant Noodles (Pancit Canton)', 'Snacks', 430,10.0,61.0,16.0),
    _f('Whey Protein (1 scoop ~30g)',     'Snacks', 120,24.0, 3.0, 1.5),
  ];

  static FoodItem _f(String name, String cat, double kcal,
          double p, double c, double f) =>
      FoodItem(
        barcode: name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_'),
        name: name,
        brand: cat,
        caloriesPer100g: kcal,
        proteinPer100g: p,
        carbsPer100g: c,
        fatPer100g: f,
      );
}
