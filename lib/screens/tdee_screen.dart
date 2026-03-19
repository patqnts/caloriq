// lib/screens/tdee_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';

class TdeeScreen extends StatefulWidget {
  const TdeeScreen({super.key});

  @override
  State<TdeeScreen> createState() => _TdeeScreenState();
}

class _TdeeScreenState extends State<TdeeScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _heightCtrl;
  late TextEditingController _ageCtrl;
  late TextEditingController _currentWeightCtrl;
  late TextEditingController _targetWeightCtrl;
  late TextEditingController _deficitCtrl;
  late String _gender;
  late String _activityLevel;
  late String _weightUnit;
  bool _edited = false;

  @override
  void initState() {
    super.initState();
    final p = context.read<AppProvider>().profile;
    _nameCtrl          = TextEditingController(text: p.name);
    _heightCtrl        = TextEditingController(text: p.heightCm.toString());
    _ageCtrl           = TextEditingController(text: p.age.toString());
    _currentWeightCtrl = TextEditingController(text: p.currentWeight.toString());
    _targetWeightCtrl  = TextEditingController(text: p.targetWeight.toString());
    _deficitCtrl       = TextEditingController(text: p.calorieDeficit.toString());
    _gender        = p.gender;
    _activityLevel = p.activityLevel;
    _weightUnit    = p.weightUnit;
  }

  UserProfile _buildProfile() => UserProfile(
        name: _nameCtrl.text,
        currentWeight: double.tryParse(_currentWeightCtrl.text) ?? 70,
        targetWeight:  double.tryParse(_targetWeightCtrl.text) ?? 65,
        heightCm:      double.tryParse(_heightCtrl.text) ?? 170,
        age:           int.tryParse(_ageCtrl.text) ?? 25,
        gender:        _gender,
        activityLevel: _activityLevel,
        calorieDeficit: double.tryParse(_deficitCtrl.text) ?? 500,
        weightUnit:    _weightUnit,
      );

  bool get _isGaining {
    final c = double.tryParse(_currentWeightCtrl.text) ?? 0;
    final t = double.tryParse(_targetWeightCtrl.text) ?? 0;
    return t > c;
  }

  String _buildTip() {
    final val       = double.tryParse(_deficitCtrl.text) ?? 500;
    final kgPerWeek = (val * 7 / 7700).toStringAsFixed(2);
    return _isGaining
        ? '$val kcal/day surplus ≈ $kgPerWeek kg/week gain'
        : '$val kcal/day deficit ≈ $kgPerWeek kg/week loss';
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final preview = _buildProfile();

    return Scaffold(
      backgroundColor: AppTheme.bg_(isDark),
      appBar: AppBar(
        title: const Text('Profile & TDEE'),
        backgroundColor: AppTheme.surface_(isDark),
        surfaceTintColor: Colors.transparent,
        actions: [
          if (_edited)
            TextButton(
              onPressed: _save,
              child: Text('Save',
                  style: TextStyle(color: AppTheme.accent_(isDark))),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme toggle
          _ThemeToggle(),
          const SizedBox(height: 16),

          // Live preview
          _TdeePreview(profile: preview),
          const SizedBox(height: 20),

          // About you
          SectionLabel('About you'),
          CCard(
            child: Column(children: [
              _inputRow('Name',   _nameCtrl,   'Your name'),
              Divider(height: 20, color: AppTheme.border_(isDark)),
              _inputRow('Age',    _ageCtrl,    '25',  numeric: true),
              Divider(height: 20, color: AppTheme.border_(isDark)),
              _inputRow('Height', _heightCtrl, '170', suffix: 'cm', numeric: true),
            ]),
          ),
          const SizedBox(height: 16),

          // Gender
          SectionLabel('Gender'),
          Row(children: [
            Expanded(child: _selectChip('Male',   _gender == 'male',
                () => setState(() { _gender = 'male';   _edited = true; }))),
            const SizedBox(width: 8),
            Expanded(child: _selectChip('Female', _gender == 'female',
                () => setState(() { _gender = 'female'; _edited = true; }))),
          ]),
          const SizedBox(height: 16),

          // Activity
          SectionLabel('Activity level'),
          ..._activityOptions.map((opt) => _ActivityOption(
                label:       opt['label']!,
                description: opt['desc']!,
                value:       opt['value']!,
                selected:    _activityLevel == opt['value'],
                onTap: () => setState(() {
                  _activityLevel = opt['value']!;
                  _edited = true;
                }),
              )),
          const SizedBox(height: 16),

          // Weight unit
          SectionLabel('Weight unit'),
          Row(children: [
            Expanded(child: _selectChip('kg',  _weightUnit == 'kg',
                () => setState(() { _weightUnit = 'kg';  _edited = true; }))),
            const SizedBox(width: 8),
            Expanded(child: _selectChip('lbs', _weightUnit == 'lbs',
                () => setState(() { _weightUnit = 'lbs'; _edited = true; }))),
          ]),
          const SizedBox(height: 12),

          // Weight values
          CCard(
            child: Column(children: [
              _inputRow('Current weight', _currentWeightCtrl, '70',
                  suffix: _weightUnit, numeric: true),
              Divider(height: 20, color: AppTheme.border_(isDark)),
              _inputRow('Target weight', _targetWeightCtrl, '65',
                  suffix: _weightUnit, numeric: true),
            ]),
          ),

          // Gain/loss indicator
          const SizedBox(height: 8),
          Builder(builder: (context) {
            final c = double.tryParse(_currentWeightCtrl.text) ?? 0;
            final t = double.tryParse(_targetWeightCtrl.text) ?? 0;
            if (c == 0 || t == 0) return const SizedBox();
            final gaining = t > c;
            final diff    = (t - c).abs();
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: (gaining
                        ? AppTheme.green_(isDark)
                        : AppTheme.accent_(isDark))
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  gaining ? Icons.trending_up : Icons.trending_down,
                  size: 16,
                  color: gaining
                      ? AppTheme.green_(isDark)
                      : AppTheme.accent_(isDark),
                ),
                const SizedBox(width: 6),
                Text(
                  gaining
                      ? 'Goal: gain ${diff.toStringAsFixed(1)} kg'
                      : 'Goal: lose ${diff.toStringAsFixed(1)} kg',
                  style: TextStyle(
                    color: gaining
                        ? AppTheme.green_(isDark)
                        : AppTheme.accent_(isDark),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ]),
            );
          }),
          const SizedBox(height: 16),

          // Deficit / Surplus
          SectionLabel(_isGaining ? 'Daily calorie surplus' : 'Daily calorie deficit'),
          CCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              TextField(
                controller: _deficitCtrl,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() => _edited = true),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  color: AppTheme.textPrimary_(isDark),
                ),
                decoration: InputDecoration(
                  hintText: '500',
                  suffixText: 'kcal',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  fillColor: Colors.transparent,
                  suffixStyle:
                      TextStyle(color: AppTheme.textMuted_(isDark)),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [250, 500, 750, 1000].map((v) {
                  return ActionChip(
                    label: Text('$v',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary_(isDark))),
                    backgroundColor: AppTheme.surfaceElevated_(isDark),
                    side: BorderSide(
                      color: double.tryParse(_deficitCtrl.text) == v.toDouble()
                          ? AppTheme.accent_(isDark)
                          : AppTheme.border_(isDark),
                    ),
                    onPressed: () => setState(() {
                      _deficitCtrl.text = v.toString();
                      _edited = true;
                    }),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Text(_buildTip(),
                  style: TextStyle(
                      color: AppTheme.textMuted_(isDark), fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 24),

          if (_edited)
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
                onPressed: _save,
                child: const Text('Save profile'),
              ),
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _inputRow(String label, TextEditingController ctrl, String hint,
      {String? suffix, bool numeric = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(children: [
      SizedBox(
        width: 130,
        child: Text(label,
            style: TextStyle(
                color: AppTheme.textSecondary_(isDark), fontSize: 14)),
      ),
      Expanded(
        child: TextField(
          controller: ctrl,
          keyboardType: numeric
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          onChanged: (_) => setState(() => _edited = true),
          textAlign: TextAlign.end,
          style: TextStyle(color: AppTheme.textPrimary_(isDark)),
          decoration: InputDecoration(
            hintText: hint,
            suffixText: suffix,
            suffixStyle:
                TextStyle(color: AppTheme.textMuted_(isDark), fontSize: 12),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            fillColor: Colors.transparent,
          ),
        ),
      ),
    ]);
  }

  Widget _selectChip(String label, bool selected, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.accent_(isDark).withOpacity(0.15)
              : AppTheme.surface_(isDark),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppTheme.accent_(isDark)
                : AppTheme.border_(isDark),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? AppTheme.accent_(isDark)
                : AppTheme.textSecondary_(isDark),
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final p = _buildProfile();
    await context.read<AppProvider>().saveProfile(p);
    setState(() => _edited = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile saved'),
          backgroundColor: AppTheme.green_(
              Theme.of(context).brightness == Brightness.dark),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  static const _activityOptions = [
    {'value': 'sedentary',  'label': 'Sedentary',         'desc': 'Little or no exercise, desk job'},
    {'value': 'light',      'label': 'Lightly active',    'desc': '1–3 days/week light exercise'},
    {'value': 'moderate',   'label': 'Moderately active', 'desc': '3–5 days/week moderate exercise'},
    {'value': 'active',     'label': 'Very active',       'desc': '6–7 days/week hard exercise'},
    {'value': 'very_active','label': 'Extra active',      'desc': 'Physical job + hard exercise'},
  ];
}

class _ActivityOption extends StatelessWidget {
  final String label;
  final String description;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _ActivityOption({
    required this.label,
    required this.description,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.accent_(isDark).withOpacity(0.1)
              : AppTheme.surface_(isDark),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppTheme.accent_(isDark)
                : AppTheme.border_(isDark),
          ),
        ),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                      color: selected
                          ? AppTheme.accent_(isDark)
                          : AppTheme.textPrimary_(isDark),
                      fontWeight: FontWeight.w500,
                    )),
                const SizedBox(height: 2),
                Text(description,
                    style: TextStyle(
                        color: AppTheme.textMuted_(isDark), fontSize: 12)),
              ],
            ),
          ),
          if (selected)
            Icon(Icons.check_circle,
                color: AppTheme.accent_(isDark), size: 18),
        ]),
      ),
    );
  }
}

class _TdeePreview extends StatelessWidget {
  final UserProfile profile;
  const _TdeePreview({required this.profile});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Your numbers'),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _num(context, 'TDEE',
                  '${profile.tdee.round()} kcal',
                  AppTheme.textSecondary_(isDark)),
              _num(context, 'Goal',
                  '${profile.dailyCalorieGoal.round()} kcal',
                  AppTheme.accent_(isDark)),
              _num(context,
                  profile.isGaining ? 'Surplus' : 'Deficit',
                  '${profile.calorieDeficit.round()} kcal',
                  profile.isGaining
                      ? AppTheme.green_(isDark)
                      : AppTheme.red_(isDark)),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: AppTheme.border_(isDark)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _num(context, 'BMI',
                  profile.bmi.toStringAsFixed(1),
                  _bmiColor(profile.bmi, isDark)),
              _num(context, 'To goal',
                  '${(profile.targetWeight - profile.currentWeight).abs().toStringAsFixed(1)} kg',
                  profile.isGaining
                      ? AppTheme.green_(isDark)
                      : AppTheme.accent_(isDark)),
              _num(context, 'Est. ${profile.daysToGoal}d',
                  _fmtDate(profile),
                  AppTheme.textSecondary_(isDark)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _num(BuildContext context, String label, String val, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(children: [
      Text(val,
          style: TextStyle(
              color: color, fontSize: 15, fontWeight: FontWeight.w600)),
      const SizedBox(height: 2),
      Text(label,
          style: TextStyle(
              color: AppTheme.textMuted_(isDark), fontSize: 11)),
    ]);
  }

  Color _bmiColor(double bmi, bool isDark) {
    if (bmi < 18.5) return AppTheme.accent_(isDark);
    if (bmi < 25)   return AppTheme.green_(isDark);
    if (bmi < 30)   return AppTheme.orange_(isDark);
    return AppTheme.red_(isDark);
  }

  String _fmtDate(UserProfile p) {
    final d = p.estimatedGoalDate;
    return '${d.month}/${d.day}/${d.year % 100}';
  }
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context) {
    final p      = context.watch<AppProvider>();
    final isDark = p.themeMode == ThemeMode.dark;

    return CCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Icon(
          isDark ? Icons.dark_mode : Icons.light_mode,
          color: isDark
              ? AppTheme.accent_(true)
              : AppTheme.orange_(false),
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            isDark ? 'Dark mode' : 'Light mode',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary_(isDark)),
          ),
        ),
        CupertinoSwitch(
          value: isDark,
          activeColor: AppTheme.accent_(isDark),
          onChanged: (v) =>
              p.setThemeMode(v ? ThemeMode.dark : ThemeMode.light),
        ),
      ]),
    );
  }
}
