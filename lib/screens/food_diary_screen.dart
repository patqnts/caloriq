// lib/screens/food_diary_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../services/food_api_service.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';

class FoodDiaryScreen extends StatelessWidget {
  const FoodDiaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p      = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isToday = _sameDay(p.selectedDate, DateTime.now());

    return Scaffold(
      backgroundColor: AppTheme.bg_(isDark),
      appBar: AppBar(
        backgroundColor: AppTheme.surface_(isDark),
        surfaceTintColor: Colors.transparent,
        title: GestureDetector(
          onTap: () => _pickDate(context, p),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isToday ? 'Today' : DateFormat('MMM d').format(p.selectedDate),
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary_(isDark)),
              ),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down,
                  color: AppTheme.textMuted_(isDark), size: 20),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _CalorieSummary(provider: p),
          const SizedBox(height: 16),
          ...MealType.values.map((m) => _MealSection(mealType: m, provider: p)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _pickDate(BuildContext context, AppProvider p) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final picked = await showDatePicker(
      context: context,
      initialDate: p.selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: isDark
              ? ColorScheme.dark(primary: AppTheme.accent_(isDark), surface: AppTheme.surface_(isDark))
              : ColorScheme.light(primary: AppTheme.accent_(isDark)),
        ),
        child: child!,
      ),
    );
    if (picked != null) await p.setSelectedDate(picked);
  }
}

class _CalorieSummary extends StatelessWidget {
  final AppProvider provider;
  const _CalorieSummary({required this.provider});

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final remaining = provider.todayCaloriesRemaining;
    final isGaining = provider.profile.isGaining;
    final isOver    = isGaining ? remaining < 0 : remaining < 0;
    final goal      = provider.profile.dailyCalorieGoal;
    final consumed  = provider.todayCaloriesConsumed;
    final burned    = provider.todayCaloriesBurned;
    final progress  = goal > 0 ? (consumed / goal).clamp(0.0, 1.5) : 0.0;

    // For gaining: "over" means you HIT your surplus — show green
    final valueColor = isGaining
        ? (isOver ? AppTheme.green_(isDark) : AppTheme.accent_(isDark))
        : (isOver ? AppTheme.red_(isDark)   : AppTheme.accent_(isDark));

    final barColor = isGaining
        ? (isOver ? AppTheme.green_(isDark) : AppTheme.accent_(isDark))
        : (isOver ? AppTheme.red_(isDark)   : AppTheme.accent_(isDark));

    return CCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${goal.round()}',
                    style: TextStyle(
                        color: AppTheme.textSecondary_(isDark), fontSize: 13)),
                Text('Goal',
                    style: TextStyle(
                        color: AppTheme.textMuted_(isDark), fontSize: 11)),
              ]),
              Column(children: [
                Text(
                  remaining.abs().round().toString(),
                  style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w700,
                      color: valueColor),
                ),
                Text(
                  isGaining
                      ? (isOver ? 'kcal surplus!' : 'kcal to surplus')
                      : (isOver ? 'kcal over'     : 'kcal left'),
                  style: TextStyle(
                      color: AppTheme.textMuted_(isDark), fontSize: 12),
                ),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${consumed.round()}',
                    style: TextStyle(
                        color: AppTheme.accent_(isDark), fontSize: 13)),
                Text('Eaten',
                    style: TextStyle(
                        color: AppTheme.textMuted_(isDark), fontSize: 11)),
                const SizedBox(height: 4),
                Text('-${burned.round()}',
                    style: TextStyle(
                        color: AppTheme.green_(isDark), fontSize: 13)),
                Text('Burned',
                    style: TextStyle(
                        color: AppTheme.textMuted_(isDark), fontSize: 11)),
              ]),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.bg_(isDark),
              valueColor: AlwaysStoppedAnimation(barColor),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}

class _MealSection extends StatelessWidget {
  final MealType mealType;
  final AppProvider provider;
  const _MealSection({required this.mealType, required this.provider});

  @override
  Widget build(BuildContext context) {
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final isExercise  = mealType == MealType.exercise;
    final logs        = provider.getFoodLogsByMeal(mealType);
    final exerciseLogs = isExercise ? provider.exerciseLogs : <ExerciseLog>[];
    final totalCals   = isExercise
        ? exerciseLogs.fold(0.0, (s, e) => s + e.caloriesBurned)
        : logs.fold(0.0, (s, l) => s + l.calories);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface_(isDark),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            InkWell(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              onTap: () => _openAddSheet(context),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(mealType.emoji,
                        style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Text(mealType.label,
                        style: TextStyle(
                            color: AppTheme.textPrimary_(isDark),
                            fontSize: 17,
                            fontWeight: FontWeight.w500)),
                    const Spacer(),
                    if (totalCals > 0)
                      Text(
                        isExercise
                            ? '-${totalCals.round()} kcal'
                            : '${totalCals.round()} kcal',
                        style: TextStyle(
                          color: isExercise
                              ? AppTheme.green_(isDark)
                              : AppTheme.accent_(isDark),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    const SizedBox(width: 8),
                    Icon(Icons.add, color: AppTheme.accent_(isDark), size: 20),
                  ],
                ),
              ),
            ),
            if (!isExercise && logs.isNotEmpty) ...[
              Divider(height: 1, color: AppTheme.border_(isDark)),
              ...logs.map((l) => _FoodLogTile(log: l, provider: provider)),
            ],
            if (isExercise && exerciseLogs.isNotEmpty) ...[
              Divider(height: 1, color: AppTheme.border_(isDark)),
              ...exerciseLogs
                  .map((e) => _ExerciseTile(log: e, provider: provider)),
            ],
          ],
        ),
      ),
    );
  }

  void _openAddSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (mealType == MealType.exercise) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppTheme.surface_(isDark),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => _ExerciseSheet(provider: provider),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppTheme.surface_(isDark),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) =>
            _FoodSearchSheet(mealType: mealType, provider: provider),
      );
    }
  }
}

class _FoodLogTile extends StatelessWidget {
  final FoodLog log;
  final AppProvider provider;
  const _FoodLogTile({required this.log, required this.provider});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dismissible(
      key: Key('food_${log.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        color: AppTheme.red_(isDark).withOpacity(0.15),
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete_outline, color: AppTheme.red_(isDark)),
      ),
      onDismissed: (_) => provider.deleteFoodLog(log.id!),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(log.food.name,
                      style: TextStyle(
                          color: AppTheme.textPrimary_(isDark), fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    '${log.amountGrams.round()}g  ·  P:${log.protein.toStringAsFixed(1)}  C:${log.carbs.toStringAsFixed(1)}  F:${log.fat.toStringAsFixed(1)}',
                    style: TextStyle(
                        color: AppTheme.textMuted_(isDark), fontSize: 11),
                  ),
                ],
              ),
            ),
            Text('${log.calories.round()} kcal',
                style: TextStyle(
                    color: AppTheme.accent_(isDark),
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  final ExerciseLog log;
  final AppProvider provider;
  const _ExerciseTile({required this.log, required this.provider});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dismissible(
      key: Key('exercise_${log.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        color: AppTheme.red_(isDark).withOpacity(0.15),
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete_outline, color: AppTheme.red_(isDark)),
      ),
      onDismissed: (_) => provider.deleteExerciseLog(log.id!),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(log.name,
                      style: TextStyle(
                          color: AppTheme.textPrimary_(isDark), fontSize: 15)),
                  const SizedBox(height: 2),
                  Text('${log.durationMinutes} min',
                      style: TextStyle(
                          color: AppTheme.textMuted_(isDark), fontSize: 11)),
                ],
              ),
            ),
            Text('-${log.caloriesBurned} kcal',
                style: TextStyle(
                    color: AppTheme.green_(isDark),
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ── Food Search Sheet ─────────────────────────────────────────────────────────

class _FoodSearchSheet extends StatefulWidget {
  final MealType mealType;
  final AppProvider provider;
  const _FoodSearchSheet({required this.mealType, required this.provider});

  @override
  State<_FoodSearchSheet> createState() => _FoodSearchSheetState();
}

class _FoodSearchSheetState extends State<_FoodSearchSheet> {
  final _searchCtrl = TextEditingController();
  List<FoodItem> _localResults = [];
  List<FoodItem> _usdaResults  = [];
  List<FoodItem> _recents      = [];
  bool _usdaLoading = false;
  FoodItem? _selected;
  final _amountCtrl = TextEditingController(text: '100');
  Timer? _usdaDebounce;

  @override
  void initState() {
    super.initState();
    _loadRecents();
  }

  Future<void> _loadRecents() async {
    final r = await widget.provider.getRecentFoods();
    if (mounted) setState(() => _recents = r);
  }

  void _onSearchChanged(String q) {
    _usdaDebounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() { _localResults = []; _usdaResults = []; _usdaLoading = false; });
      return;
    }
    setState(() {
      _localResults = FoodApiService.searchLocal(q);
      _usdaLoading  = true;
      _usdaResults  = [];
    });
    _usdaDebounce = Timer(const Duration(milliseconds: 600), () async {
      final results = await FoodApiService.searchUsda(q);
      if (mounted) setState(() { _usdaResults = results; _usdaLoading = false; });
    });
  }

  @override
  void dispose() {
    _usdaDebounce?.cancel();
    _searchCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      builder: (ctx, scrollCtrl) => Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: AppTheme.border_(isDark),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Add to ${widget.mealType.label}',
                        style: Theme.of(context).textTheme.headlineMedium),
                    IconButton(
                      icon: Icon(Icons.close, color: AppTheme.textMuted_(isDark)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  style: TextStyle(color: AppTheme.textPrimary_(isDark)),
                  decoration: InputDecoration(
                    hintText: 'Search food…',
                    prefixIcon: Icon(Icons.search, color: AppTheme.textMuted_(isDark)),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ],
            ),
          ),
          Expanded(
            child: _selected != null
                ? _AmountEntry(
                    food: _selected!,
                    amountCtrl: _amountCtrl,
                    onSave: _saveFood,
                    onBack: () => setState(() => _selected = null),
                  )
                : _searchCtrl.text.isEmpty
                    ? _browseView(scrollCtrl)
                    : _searchResultsView(scrollCtrl),
          ),
        ],
      ),
    );
  }

  Widget _browseView(ScrollController scrollCtrl) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      controller: scrollCtrl,
      padding: const EdgeInsets.all(16),
      children: [
        if (_recents.isNotEmpty) ...[
          const SectionLabel('Recent'),
          ..._recents.map(_foodTile),
          const SizedBox(height: 16),
        ],
        const SectionLabel('Browse'),
        ...FoodApiService.categories.map((cat) {
          final foods = FoodApiService.byCategory(cat);
          return Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: Text(cat,
                  style: TextStyle(
                      color: AppTheme.textSecondary_(isDark), fontSize: 14)),
              iconColor: AppTheme.textMuted_(isDark),
              collapsedIconColor: AppTheme.textMuted_(isDark),
              collapsedBackgroundColor: Colors.transparent,
              backgroundColor: Colors.transparent,
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              children: foods.map(_foodTile).toList(),
            ),
          );
        }),
      ],
    );
  }

  Widget _searchResultsView(ScrollController scrollCtrl) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      controller: scrollCtrl,
      padding: const EdgeInsets.all(16),
      children: [
        if (_localResults.isNotEmpty) ...[
          const SectionLabel('Local database'),
          ..._localResults.map(_foodTile),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            const Expanded(child: SectionLabel('USDA database')),
            if (_usdaLoading)
              SizedBox(
                width: 12, height: 12,
                child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: AppTheme.textMuted_(isDark)),
              ),
          ],
        ),
        const SizedBox(height: 4),
        if (_usdaResults.isNotEmpty)
          ..._usdaResults.map(_foodTile)
        else if (!_usdaLoading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('No USDA results',
                style: TextStyle(
                    color: AppTheme.textMuted_(isDark), fontSize: 13)),
          ),
        if (_localResults.isEmpty && _usdaResults.isEmpty && !_usdaLoading)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('No results found',
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
          ),
      ],
    );
  }

  Widget _foodTile(FoodItem food) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(food.name,
          style: TextStyle(color: AppTheme.textPrimary_(isDark), fontSize: 15),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${food.brand}  ·  ${food.caloriesPer100g.round()} kcal/100g',
        style: TextStyle(color: AppTheme.textMuted_(isDark), fontSize: 12),
      ),
      trailing: Icon(Icons.chevron_right, color: AppTheme.textMuted_(isDark)),
      onTap: () => setState(() => _selected = food),
    );
  }

  Future<void> _saveFood() async {
    final grams = double.tryParse(_amountCtrl.text) ?? 100;
    await widget.provider.saveFoodLog(FoodLog(
      date: widget.provider.selectedDate,
      mealType: widget.mealType,
      food: _selected!,
      amountGrams: grams,
    ));
    if (mounted) Navigator.pop(context);
  }
}

class _AmountEntry extends StatefulWidget {
  final FoodItem food;
  final TextEditingController amountCtrl;
  final VoidCallback onSave;
  final VoidCallback onBack;

  const _AmountEntry({
    required this.food,
    required this.amountCtrl,
    required this.onSave,
    required this.onBack,
  });

  @override
  State<_AmountEntry> createState() => _AmountEntryState();
}

class _AmountEntryState extends State<_AmountEntry> {
  // Serving size presets (grams)
  static const _presets = [
    ('100g',   100.0),
    ('150g',   150.0),
    ('200g',   200.0),
    ('250g',   250.0),
    ('1 cup',  240.0),
    ('1 tbsp',  15.0),
    ('1 tsp',    5.0),
  ];

  int _quantity = 1;
  double _servingGrams = 100;
  final _customCtrl = TextEditingController(text: '100');
  bool _useCustom = false;

  @override
  void initState() {
    super.initState();
    _servingGrams = double.tryParse(widget.amountCtrl.text) ?? 100;
    _updateAmountCtrl();
  }

  double get _totalGrams => _servingGrams * _quantity;

  void _updateAmountCtrl() {
    widget.amountCtrl.text = _totalGrams.toStringAsFixed(
        _totalGrams == _totalGrams.roundToDouble() ? 0 : 1);
  }

  void _setQuantity(int q) {
    if (q < 1) return;
    setState(() { _quantity = q; });
    _updateAmountCtrl();
  }

  void _setServing(double g) {
    setState(() {
      _servingGrams = g;
      _useCustom = false;
    });
    _updateAmountCtrl();
  }

  void _setCustomServing(String val) {
    final g = double.tryParse(val);
    if (g != null && g > 0) {
      setState(() { _servingGrams = g; _useCustom = true; });
      _updateAmountCtrl();
    }
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final cals     = widget.food.caloriesForAmount(_totalGrams);
    final protein  = widget.food.proteinForAmount(_totalGrams);
    final carbs    = widget.food.carbsForAmount(_totalGrams);
    final fat      = widget.food.fatForAmount(_totalGrams);

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back
          GestureDetector(
            onTap: widget.onBack,
            child: Row(children: [
              Icon(Icons.arrow_back_ios,
                  color: AppTheme.textMuted_(isDark), size: 14),
              const SizedBox(width: 4),
              Text('Back',
                  style: TextStyle(
                      color: AppTheme.textMuted_(isDark), fontSize: 13)),
            ]),
          ),
          const SizedBox(height: 16),

          // Food name
          Text(widget.food.name,
              style: Theme.of(context).textTheme.headlineMedium),
          if (widget.food.brand.isNotEmpty)
            Text(widget.food.brand,
                style: TextStyle(
                    color: AppTheme.textMuted_(isDark), fontSize: 12)),
          const SizedBox(height: 20),

          // ── Total calories (big) ──────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.accent_(isDark).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(children: [
              Text(
                '${cals.round()}',
                style: TextStyle(
                  color: AppTheme.accent_(isDark),
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                ),
              ),
              Text('kcal total',
                  style: TextStyle(
                      color: AppTheme.textMuted_(isDark), fontSize: 13)),
              const SizedBox(height: 4),
              Text(
                '${widget.food.caloriesPer100g.round()} kcal per 100g  ·  ${_totalGrams.toStringAsFixed(0)}g total',
                style: TextStyle(
                    color: AppTheme.textMuted_(isDark), fontSize: 11),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // ── Quantity stepper ──────────────────────────────────────────
          Text('Quantity',
              style: TextStyle(
                  color: AppTheme.textSecondary_(isDark),
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface_(isDark),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border_(isDark)),
            ),
            child: Row(
              children: [
                // Minus
                _stepBtn(
                  icon: Icons.remove,
                  onTap: () => _setQuantity(_quantity - 1),
                  isDark: isDark,
                  enabled: _quantity > 1,
                ),
                // Count display
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '$_quantity',
                        style: TextStyle(
                          color: AppTheme.textPrimary_(isDark),
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        '× ${_servingGrams.toStringAsFixed(_servingGrams == _servingGrams.roundToDouble() ? 0 : 1)}g = ${_totalGrams.toStringAsFixed(0)}g',
                        style: TextStyle(
                            color: AppTheme.textMuted_(isDark), fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                // Plus
                _stepBtn(
                  icon: Icons.add,
                  onTap: () => _setQuantity(_quantity + 1),
                  isDark: isDark,
                  enabled: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Serving size presets ──────────────────────────────────────
          Text('Serving size',
              style: TextStyle(
                  color: AppTheme.textSecondary_(isDark),
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._presets.map((p) {
                final selected = !_useCustom &&
                    (_servingGrams - p.$2).abs() < 0.1;
                return GestureDetector(
                  onTap: () => _setServing(p.$2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.accent_(isDark).withOpacity(0.15)
                          : AppTheme.surface_(isDark),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? AppTheme.accent_(isDark)
                            : AppTheme.border_(isDark),
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      p.$1,
                      style: TextStyle(
                        color: selected
                            ? AppTheme.accent_(isDark)
                            : AppTheme.textSecondary_(isDark),
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }),
              // Custom input chip
              GestureDetector(
                onTap: () {
                  setState(() => _useCustom = true);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _useCustom
                        ? AppTheme.accent_(isDark).withOpacity(0.15)
                        : AppTheme.surface_(isDark),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _useCustom
                          ? AppTheme.accent_(isDark)
                          : AppTheme.border_(isDark),
                      width: _useCustom ? 1.5 : 1,
                    ),
                  ),
                  child: _useCustom
                      ? SizedBox(
                          width: 60,
                          child: TextField(
                            controller: _customCtrl,
                            autofocus: true,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            style: TextStyle(
                              color: AppTheme.accent_(isDark),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              fillColor: Colors.transparent,
                              hintText: 'g',
                              hintStyle: TextStyle(
                                  color: AppTheme.textMuted_(isDark),
                                  fontSize: 13),
                            ),
                            onChanged: _setCustomServing,
                          ),
                        )
                      : Text(
                          'Custom',
                          style: TextStyle(
                            color: AppTheme.textSecondary_(isDark),
                            fontSize: 13,
                          ),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Macros ───────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _macroChip('Protein', '${protein.toStringAsFixed(1)}g',
                  AppTheme.accent_(isDark), isDark),
              _macroChip('Carbs', '${carbs.toStringAsFixed(1)}g',
                  AppTheme.orange_(isDark), isDark),
              _macroChip('Fat', '${fat.toStringAsFixed(1)}g',
                  AppTheme.green_(isDark), isDark),
            ],
          ),
          const SizedBox(height: 24),

          // ── Add button ───────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.accent_(isDark),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: widget.onSave,
              child: Text(
                _quantity > 1
                    ? 'Add $_quantity × ${_servingGrams.toStringAsFixed(0)}g (${_totalGrams.toStringAsFixed(0)}g total)'
                    : 'Add to diary',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepBtn({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
    required bool enabled,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 56,
        height: 64,
        alignment: Alignment.center,
        child: Icon(
          icon,
          color: enabled
              ? AppTheme.accent_(isDark)
              : AppTheme.border_(isDark),
          size: 24,
        ),
      ),
    );
  }

  Widget _macroChip(String label, String val, Color color, bool isDark) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(children: [
          Text(val,
              style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: color.withOpacity(0.7), fontSize: 11)),
        ]),
      ),
    );
  }
}

// ── Exercise Sheet ────────────────────────────────────────────────────────────

class _ExerciseSheet extends StatefulWidget {
  final AppProvider provider;
  const _ExerciseSheet({required this.provider});

  @override
  State<_ExerciseSheet> createState() => _ExerciseSheetState();
}

class _ExerciseSheetState extends State<_ExerciseSheet> {
  final _nameCtrl     = TextEditingController();
  final _durationCtrl = TextEditingController(text: '30');
  final _calsCtrl     = TextEditingController();

  static const _templates = [
    ('Walking', 30, 150),
    ('Running', 30, 300),
    ('Cycling', 30, 250),
    ('Swimming', 30, 280),
    ('Weight Training', 45, 200),
    ('HIIT', 20, 250),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Log Exercise',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _templates.map((t) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(t.$1,
                        style: TextStyle(
                            color: AppTheme.textSecondary_(isDark),
                            fontSize: 12)),
                    backgroundColor: AppTheme.surfaceElevated_(isDark),
                    side: BorderSide(color: AppTheme.border_(isDark)),
                    onPressed: () => setState(() {
                      _nameCtrl.text     = t.$1;
                      _durationCtrl.text = t.$2.toString();
                      _calsCtrl.text     = t.$3.toString();
                    }),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            style: TextStyle(color: AppTheme.textPrimary_(isDark)),
            decoration: const InputDecoration(hintText: 'Exercise name'),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _durationCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: AppTheme.textPrimary_(isDark)),
                decoration: InputDecoration(
                  labelText: 'Duration (min)',
                  labelStyle: TextStyle(color: AppTheme.textMuted_(isDark)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _calsCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: AppTheme.textPrimary_(isDark)),
                decoration: InputDecoration(
                  labelText: 'Calories burned',
                  labelStyle: TextStyle(color: AppTheme.textMuted_(isDark)),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.green_(isDark),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                if (_nameCtrl.text.isEmpty) return;
                await widget.provider.saveExerciseLog(ExerciseLog(
                  date: widget.provider.selectedDate,
                  name: _nameCtrl.text,
                  durationMinutes: int.tryParse(_durationCtrl.text) ?? 30,
                  caloriesBurned: int.tryParse(_calsCtrl.text) ?? 0,
                ));
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Log exercise'),
            ),
          ),
        ],
      ),
    );
  }
}
