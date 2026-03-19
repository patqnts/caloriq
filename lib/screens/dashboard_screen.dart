// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.bg_(isDark),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppTheme.surface_(isDark),
            surfaceTintColor: Colors.transparent,
            title: Text(
              DateFormat('EEEE, MMM d').format(DateTime.now()),
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary_(isDark)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _CalorieRingCard(provider: p),
                const SizedBox(height: 16),
                _MacroCard(provider: p),
                const SizedBox(height: 16),
                _WeeklyChart(provider: p),
                const SizedBox(height: 16),
                _GoalCard(provider: p),
                const SizedBox(height: 16),
                _WeightToday(provider: p),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalorieRingCard extends StatelessWidget {
  final AppProvider provider;
  const _CalorieRingCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final goal      = provider.profile.dailyCalorieGoal;
    final eaten     = provider.todayCaloriesConsumed;
    final burned    = provider.todayCaloriesBurned;
    final net       = eaten - burned;
    final remaining = goal - net;
    final isGaining = provider.profile.isGaining;
    final isOver    = isGaining ? net >= goal : remaining < 0;

    final eatenProgress  = goal > 0 ? (eaten  / goal).clamp(0.0, 1.0) : 0.0;
    final burnedProgress = goal > 0 ? (burned / goal).clamp(0.0, 1.0) : 0.0;

    final accentColor = AppTheme.accent_(isDark);
    final greenColor  = AppTheme.green_(isDark);
    final redColor    = AppTheme.red_(isDark);
    final bgColor     = AppTheme.bg_(isDark);

    // For gaining: ring fills green when hitting surplus goal
    final innerColor = isGaining
        ? (isOver ? greenColor : accentColor)
        : (isOver ? redColor   : accentColor);

    return CCard(
      child: Row(
        children: [
          SizedBox(
            width: 130,
            height: 130,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer ring: burned (green)
                CustomPaint(
                  size: const Size(130, 130),
                  painter: RingProgress(
                    progress: burnedProgress,
                    color: greenColor,
                    bgColor: bgColor,
                    strokeWidth: 8,
                  ),
                ),
                // Inner ring: eaten
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: CustomPaint(
                    size: const Size(102, 102),
                    painter: RingProgress(
                      progress: eatenProgress,
                      color: innerColor,
                      bgColor: bgColor,
                      strokeWidth: 10,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      remaining.abs().round().toString(),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: isGaining
                            ? (isOver ? greenColor : AppTheme.textPrimary_(isDark))
                            : (isOver ? redColor   : AppTheme.textPrimary_(isDark)),
                      ),
                    ),
                    Text(
                      isGaining
                          ? (isOver ? 'surplus!' : 'to surplus')
                          : (isOver ? 'over'     : 'left'),
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textMuted_(isDark)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _statRow(context, 'Goal',   '${goal.round()} kcal',  AppTheme.textMuted_(isDark)),
                const SizedBox(height: 12),
                _statRow(context, 'Eaten',  '${eaten.round()} kcal', accentColor),
                const SizedBox(height: 12),
                _statRow(context, 'Burned', '${burned.round()} kcal', greenColor),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1, color: AppTheme.border_(isDark)),
                ),
                _statRow(context, 'Net', '${net.round()} kcal',
                    isGaining
                        ? (isOver ? greenColor : AppTheme.textPrimary_(isDark))
                        : (isOver ? redColor   : AppTheme.textPrimary_(isDark)),
                    bold: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(BuildContext context, String label, String value,
      Color valueColor, {bool bold = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(color: AppTheme.textMuted_(isDark), fontSize: 14)),
        Text(value,
            style: TextStyle(
              color: valueColor,
              fontSize: 14,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
            )),
      ],
    );
  }
}

class _MacroCard extends StatelessWidget {
  final AppProvider provider;
  const _MacroCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Macros today'),
          const SizedBox(height: 10),
          MacroBar(
            label: 'Protein',
            value: provider.todayProtein,
            max: provider.profile.currentWeight * 1.6,
            color: AppTheme.accent_(isDark),
          ),
          const SizedBox(height: 12),
          MacroBar(
            label: 'Carbs',
            value: provider.todayCarbs,
            max: provider.profile.dailyCalorieGoal * 0.5 / 4,
            color: AppTheme.orange_(isDark),
          ),
          const SizedBox(height: 12),
          MacroBar(
            label: 'Fat',
            value: provider.todayFat,
            max: provider.profile.dailyCalorieGoal * 0.3 / 9,
            color: AppTheme.green_(isDark),
          ),
        ],
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  final AppProvider provider;
  const _WeeklyChart({required this.provider});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final data   = provider.weeklyCalories;
    if (data.isEmpty) return const SizedBox();
    final goal = provider.profile.dailyCalorieGoal;
    final keys = data.keys.toList()..sort();

    final bars = keys.asMap().entries.map((e) {
      final val     = (data[e.value] ?? 0).clamp(0.0, double.infinity);
      final isToday = e.value == DateTime.now().toIso8601String().substring(0, 10);
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: val,
            color: isToday
                ? AppTheme.accent_(isDark)
                : AppTheme.accent_(isDark).withOpacity(0.25),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
            width: 26,
          ),
        ],
      );
    }).toList();

    return CCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('This week'),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: BarChart(BarChartData(
              barGroups: bars,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (val, _) {
                      final idx = val.toInt();
                      if (idx < 0 || idx >= keys.length) return const SizedBox();
                      final date = DateTime.parse(keys[idx]);
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          DateFormat('E').format(date)[0],
                          style: TextStyle(
                              color: AppTheme.textMuted_(isDark), fontSize: 11),
                        ),
                      );
                    },
                  ),
                ),
              ),
              extraLinesData: goal > 0
                  ? ExtraLinesData(horizontalLines: [
                      HorizontalLine(
                        y: goal,
                        color: AppTheme.red_(isDark).withOpacity(0.4),
                        strokeWidth: 1,
                        dashArray: [4, 4],
                      ),
                    ])
                  : null,
            )),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final AppProvider provider;
  const _GoalCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final profile  = provider.profile;
    final days     = profile.daysToGoal;
    final goalDate = profile.estimatedGoalDate;
    final diff     = profile.targetWeight - profile.currentWeight;
    final isGaining = profile.isGaining;

    return CCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Goal'),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$days',
                  style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary_(isDark))),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text('days to goal',
                    style: TextStyle(
                        color: AppTheme.textMuted_(isDark), fontSize: 15)),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DateFormat('MMM d, y').format(goalDate),
                    style: TextStyle(
                        color: AppTheme.textSecondary_(isDark),
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${profile.currentWeight.toStringAsFixed(1)} → ${profile.targetWeight.toStringAsFixed(1)} kg',
                    style: TextStyle(
                        color: AppTheme.textMuted_(isDark), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: 0.0,
              backgroundColor: AppTheme.bg_(isDark),
              valueColor: AlwaysStoppedAnimation(
                  isGaining ? AppTheme.accent_(isDark) : AppTheme.green_(isDark)),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isGaining
                    ? 'Surplus ${profile.calorieDeficit.round()} kcal/day'
                    : 'Deficit ${profile.calorieDeficit.round()} kcal/day',
                style: TextStyle(
                    color: AppTheme.textMuted_(isDark), fontSize: 12)),
              Text(
                isGaining
                    ? '+${diff.abs().toStringAsFixed(1)} kg to gain'
                    : '−${diff.abs().toStringAsFixed(1)} kg to lose',
                style: TextStyle(
                    color: isGaining
                        ? AppTheme.accent_(isDark)
                        : AppTheme.green_(isDark),
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeightToday extends StatelessWidget {
  final AppProvider provider;
  const _WeightToday({required this.provider});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final entry  = provider.todayWeight;
    return CCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('Weight today'),
                const SizedBox(height: 4),
                if (entry != null) ...[
                  Text(
                    '${entry.averageWeight.toStringAsFixed(1)} kg',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary_(isDark)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'AM ${entry.morningWeight.toStringAsFixed(1)}'
                    '${entry.eveningWeight != null ? "  ·  PM ${entry.eveningWeight!.toStringAsFixed(1)}" : ""}',
                    style: TextStyle(
                        color: AppTheme.textMuted_(isDark), fontSize: 13),
                  ),
                ] else
                  Text('Not logged yet',
                      style: TextStyle(
                          color: AppTheme.textMuted_(isDark), fontSize: 15)),
              ],
            ),
          ),
          Icon(Icons.monitor_weight_outlined,
              color: AppTheme.textMuted_(isDark), size: 28),
        ],
      ),
    );
  }
}
