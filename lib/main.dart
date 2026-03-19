// lib/main.dart
import 'package:caloriq/models/models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/weight_screen.dart';
import 'screens/food_diary_screen.dart';
import 'screens/tdee_screen.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const CaloriqApp());
}

class CaloriqApp extends StatelessWidget {
  const CaloriqApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final provider = AppProvider();
        Future.microtask(() => provider.init());
        return provider;
      },
      child: Consumer<AppProvider>(
        builder: (_, provider, __) => MaterialApp(
          title: 'caloríq',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: provider.themeMode,
          debugShowCheckedModeBanner: false,
          home: const AppShell(),
        ),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  static const _screens = [
    DashboardScreen(),
    WeightScreen(),
    FoodDiaryScreen(),
    TdeeScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final p      = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (p.isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.bg_(isDark),
        body: Center(
          child: CircularProgressIndicator(
              color: AppTheme.accent_(isDark)),
        ),
      );
    }

    if (!p.profileSetup) {
      return const _OnboardingScreen();
    }

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
              top: BorderSide(color: AppTheme.border_(isDark), width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.monitor_weight_outlined),
                activeIcon: Icon(Icons.monitor_weight),
                label: 'Weight'),
            BottomNavigationBarItem(
                icon: Icon(Icons.restaurant_outlined),
                activeIcon: Icon(Icons.restaurant),
                label: 'Diary'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

// ── Onboarding ────────────────────────────────────────────────────────────────

class _OnboardingScreen extends StatefulWidget {
  const _OnboardingScreen();

  @override
  State<_OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<_OnboardingScreen> {
  final _pageCtrl        = PageController();
  int _page = 0;

  final _nameCtrl          = TextEditingController();
  final _ageCtrl           = TextEditingController();
  final _heightCtrl        = TextEditingController();
  final _currentWeightCtrl = TextEditingController();
  final _targetWeightCtrl  = TextEditingController();
  String _gender        = 'male';
  String _activityLevel = 'sedentary';

  bool get _isGaining {
    final c = double.tryParse(_currentWeightCtrl.text) ?? 0;
    final t = double.tryParse(_targetWeightCtrl.text) ?? 0;
    return t > c;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.bg_(isDark),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: List.generate(3, (i) => Container(
                  margin: const EdgeInsets.only(right: 6),
                  width: i == _page ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _page
                        ? AppTheme.accent_(isDark)
                        : AppTheme.border_(isDark),
                    borderRadius: BorderRadius.circular(4),
                  ),
                )),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [_page0(), _page1(), _page2()],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.accent_(isDark),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _next,
                  child: Text(_page < 2 ? 'Continue' : 'Get started'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _page0() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hey there 👋',
              style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary_(isDark))),
          const SizedBox(height: 8),
          Text("Let's set up your profile so we can calculate your calorie goal.",
              style: TextStyle(
                  color: AppTheme.textSecondary_(isDark), fontSize: 15)),
          const SizedBox(height: 32),
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            style: TextStyle(color: AppTheme.textPrimary_(isDark)),
            decoration: InputDecoration(
              labelText: 'Name (optional)',
              labelStyle: TextStyle(color: AppTheme.textMuted_(isDark)),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _ageCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: AppTheme.textPrimary_(isDark)),
                decoration: InputDecoration(
                  labelText: 'Age',
                  labelStyle: TextStyle(color: AppTheme.textMuted_(isDark)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _heightCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: AppTheme.textPrimary_(isDark)),
                decoration: InputDecoration(
                  labelText: 'Height (cm)',
                  labelStyle: TextStyle(color: AppTheme.textMuted_(isDark)),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _genderChip('Male',   'male')),
            const SizedBox(width: 8),
            Expanded(child: _genderChip('Female', 'female')),
          ]),
        ],
      ),
    );
  }

  Widget _page1() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your weight',
              style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary_(isDark))),
          const SizedBox(height: 32),
          TextField(
            controller: _currentWeightCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            onChanged: (_) => setState(() {}),
            style: TextStyle(color: AppTheme.textPrimary_(isDark)),
            decoration: InputDecoration(
              labelText: 'Current weight (kg)',
              labelStyle: TextStyle(color: AppTheme.textMuted_(isDark)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _targetWeightCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            style: TextStyle(color: AppTheme.textPrimary_(isDark)),
            decoration: InputDecoration(
              labelText: 'Target weight (kg)',
              labelStyle: TextStyle(color: AppTheme.textMuted_(isDark)),
            ),
          ),
          const SizedBox(height: 16),
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
        ],
      ),
    );
  }

  Widget _page2() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Activity level',
              style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary_(isDark))),
          const SizedBox(height: 8),
          Text('This helps estimate how many calories you burn daily.',
              style: TextStyle(
                  color: AppTheme.textSecondary_(isDark), fontSize: 15)),
          const SizedBox(height: 20),
          ...[
            ('sedentary',  'Sedentary',         'Desk job, little exercise'),
            ('light',      'Lightly active',    '1–3x/week'),
            ('moderate',   'Moderately active', '3–5x/week'),
            ('active',     'Very active',       '6–7x/week'),
            ('very_active','Extra active',      'Physical job + training'),
          ].map((opt) => GestureDetector(
            onTap: () => setState(() => _activityLevel = opt.$1),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _activityLevel == opt.$1
                    ? AppTheme.accent_(isDark).withOpacity(0.1)
                    : AppTheme.surface_(isDark),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _activityLevel == opt.$1
                      ? AppTheme.accent_(isDark)
                      : AppTheme.border_(isDark),
                ),
              ),
              child: Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(opt.$2,
                          style: TextStyle(
                            color: _activityLevel == opt.$1
                                ? AppTheme.accent_(isDark)
                                : AppTheme.textPrimary_(isDark),
                            fontWeight: FontWeight.w500,
                          )),
                      Text(opt.$3,
                          style: TextStyle(
                              color: AppTheme.textMuted_(isDark),
                              fontSize: 12)),
                    ],
                  ),
                ),
                if (_activityLevel == opt.$1)
                  Icon(Icons.check_circle,
                      color: AppTheme.accent_(isDark), size: 18),
              ]),
            ),
          )),
        ],
      ),
    );
  }

  Widget _genderChip(String label, String value) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final selected = _gender == value;
    return GestureDetector(
      onTap: () => setState(() => _gender = value),
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

  Future<void> _next() async {
    if (_page < 2) {
      setState(() => _page++);
      _pageCtrl.animateToPage(_page,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      final profile = UserProfile(
        name: _nameCtrl.text,
        currentWeight: double.tryParse(_currentWeightCtrl.text) ?? 70,
        targetWeight:  double.tryParse(_targetWeightCtrl.text) ?? 65,
        heightCm:      double.tryParse(_heightCtrl.text) ?? 170,
        age:           int.tryParse(_ageCtrl.text) ?? 25,
        gender:        _gender,
        activityLevel: _activityLevel,
        calorieDeficit: 500,
      );
      await context.read<AppProvider>().saveProfile(profile);
    }
  }
}
