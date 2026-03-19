// lib/screens/weight_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';

class WeightScreen extends StatefulWidget {
  const WeightScreen({super.key});

  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final p      = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.bg_(isDark),
      appBar: AppBar(
        title: const Text('Weight'),
        backgroundColor: AppTheme.surface_(isDark),
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showLogDialog(context, p, _selectedDay),
        backgroundColor: AppTheme.accent_(isDark),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _buildChart(p),
          )),
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _buildCalendar(p),
          )),
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildSelectedEntry(p),
          )),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildChart(AppProvider p) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final entries  = p.weightEntries.reversed.toList();

    if (entries.isEmpty) {
      return CCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Log your first weight to see the chart',
                style: TextStyle(color: AppTheme.textMuted_(isDark))),
          ),
        ),
      );
    }

    final spots = entries.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.averageWeight))
        .toList();
    final weights = entries.map((e) => e.averageWeight);
    final minY = weights.reduce((a, b) => a < b ? a : b) - 1;
    final maxY = weights.reduce((a, b) => a > b ? a : b) + 1;

    return CCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Progress'),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: LineChart(LineChartData(
              minY: minY,
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: AppTheme.border_(isDark), strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 38,
                    getTitlesWidget: (val, _) => Text(
                      val.toStringAsFixed(1),
                      style: TextStyle(
                          color: AppTheme.textMuted_(isDark), fontSize: 10),
                    ),
                  ),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: (entries.length / 4).ceilToDouble(),
                    getTitlesWidget: (val, _) {
                      final idx = val.toInt();
                      if (idx < 0 || idx >= entries.length) return const SizedBox();
                      return Text(
                        DateFormat('M/d').format(entries[idx].date),
                        style: TextStyle(
                            color: AppTheme.textMuted_(isDark), fontSize: 9),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: AppTheme.accent_(isDark),
                  barWidth: 2,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                      radius: 3,
                      color: AppTheme.accent_(isDark),
                      strokeWidth: 0,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.accent_(isDark).withOpacity(0.15),
                        AppTheme.accent_(isDark).withOpacity(0),
                      ],
                    ),
                  ),
                ),
                if (p.profile.targetWeight > 0)
                  LineChartBarData(
                    spots: [
                      FlSpot(0, p.profile.targetWeight),
                      FlSpot((entries.length - 1).toDouble(), p.profile.targetWeight),
                    ],
                    color: AppTheme.green_(isDark).withOpacity(0.5),
                    barWidth: 1,
                    dashArray: [4, 4],
                    dotData: const FlDotData(show: false),
                  ),
              ],
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(AppProvider p) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final entryDates = {
      for (final e in p.weightEntries)
        '${e.date.year}-${e.date.month}-${e.date.day}'
    };

    return CCard(
      padding: const EdgeInsets.all(8),
      child: TableCalendar(
        firstDay: DateTime.now().subtract(const Duration(days: 365)),
        lastDay: DateTime.now(),
        focusedDay: _focusedDay,
        selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
        availableGestures: AvailableGestures.horizontalSwipe,
        onDaySelected: (selected, focused) {
          setState(() {
            _selectedDay = selected;
            _focusedDay  = focused;
          });
        },
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary_(isDark)),
          leftChevronIcon:  Icon(Icons.chevron_left,  color: AppTheme.accent_(isDark)),
          rightChevronIcon: Icon(Icons.chevron_right, color: AppTheme.accent_(isDark)),
        ),
        calendarStyle: CalendarStyle(
          defaultTextStyle:
              TextStyle(color: AppTheme.textPrimary_(isDark), fontSize: 14),
          weekendTextStyle:
              TextStyle(color: AppTheme.textPrimary_(isDark), fontSize: 14),
          outsideDaysVisible: false,
          todayDecoration: BoxDecoration(
            border: Border.all(color: AppTheme.accent_(isDark)),
            shape: BoxShape.circle,
          ),
          todayTextStyle:
              TextStyle(color: AppTheme.accent_(isDark), fontSize: 14),
          selectedDecoration: BoxDecoration(
            color: AppTheme.accent_(isDark), shape: BoxShape.circle),
          selectedTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, day, _) {
            final key = '${day.year}-${day.month}-${day.day}';
            if (entryDates.contains(key)) {
              return Positioned(
                bottom: 4,
                child: Container(
                  width: 5, height: 5,
                  decoration: BoxDecoration(
                    color: AppTheme.green_(isDark), shape: BoxShape.circle),
                ),
              );
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildSelectedEntry(AppProvider p) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ds = '${_selectedDay.year}-${_selectedDay.month.toString().padLeft(2, '0')}-${_selectedDay.day.toString().padLeft(2, '0')}';
    WeightEntry? entry;
    try {
      entry = p.weightEntries.firstWhere(
          (e) => e.date.toIso8601String().substring(0, 10) == ds);
    } catch (_) {}

    return CCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SectionLabel(DateFormat('EEEE, MMM d').format(_selectedDay)),
              if (entry != null)
                Row(children: [
                  GestureDetector(
                    onTap: () => _showLogDialog(context, p, _selectedDay, entry),
                    child: Icon(Icons.edit_outlined,
                        color: AppTheme.textMuted_(isDark), size: 18),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => p.deleteWeightEntry(entry!.id!),
                    child: Icon(Icons.delete_outline,
                        color: AppTheme.textMuted_(isDark), size: 18),
                  ),
                ]),
            ],
          ),
          const SizedBox(height: 8),
          if (entry != null) ...[
            Row(children: [
              _stat('Morning', '${entry.morningWeight.toStringAsFixed(1)} kg', isDark),
              const SizedBox(width: 24),
              if (entry.eveningWeight != null)
                _stat('Evening', '${entry.eveningWeight!.toStringAsFixed(1)} kg', isDark),
              const SizedBox(width: 24),
              _stat('Average', '${entry.averageWeight.toStringAsFixed(1)} kg', isDark,
                  color: AppTheme.accent_(isDark)),
            ]),
            if (entry.note != null && entry.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(entry.note!,
                  style: TextStyle(
                      color: AppTheme.textSecondary_(isDark),
                      fontStyle: FontStyle.italic)),
            ],
          ] else
            TextButton.icon(
              onPressed: () => _showLogDialog(context, p, _selectedDay),
              icon: Icon(Icons.add, color: AppTheme.accent_(isDark)),
              label: Text('Log weight',
                  style: TextStyle(color: AppTheme.accent_(isDark))),
            ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, bool isDark, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(color: AppTheme.textMuted_(isDark), fontSize: 11)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
              color: color ?? AppTheme.textPrimary_(isDark),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            )),
      ],
    );
  }

  Future<void> _showLogDialog(BuildContext context, AppProvider p,
      DateTime date, [WeightEntry? existing]) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final morningCtrl =
        TextEditingController(text: existing?.morningWeight.toString() ?? '');
    final eveningCtrl =
        TextEditingController(text: existing?.eveningWeight?.toString() ?? '');
    final noteCtrl = TextEditingController(text: existing?.note ?? '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface_(isDark),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(existing != null ? 'Edit weight' : 'Log weight',
                    style: Theme.of(context).textTheme.headlineMedium),
                Text(DateFormat('MMM d').format(date),
                    style: TextStyle(color: AppTheme.textMuted_(isDark))),
              ],
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Morning (kg)',
                        style: TextStyle(
                            color: AppTheme.textMuted_(isDark), fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: morningCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      autofocus: true,
                      decoration: const InputDecoration(hintText: '70.0'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Evening (optional)',
                        style: TextStyle(
                            color: AppTheme.textMuted_(isDark), fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: eveningCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(hintText: '70.0'),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 12),
            TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(hintText: 'Note (optional)')),
            const SizedBox(height: 20),
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
                onPressed: () async {
                  final morning = double.tryParse(morningCtrl.text);
                  if (morning == null) return;
                  final evening = double.tryParse(eveningCtrl.text);
                  await p.saveWeightEntry(WeightEntry(
                    id: existing?.id,
                    date: date,
                    morningWeight: morning,
                    eveningWeight: evening,
                    note: noteCtrl.text.isEmpty ? null : noteCtrl.text,
                  ));
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
