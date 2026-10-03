import 'package:flutter/material.dart';

import '../../domain/models/habit.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../analytics/presentation/providers/habit_analytics_provider.dart';

import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../widgets/create_habit_bottom_sheet.dart';

class HabitDetailScreen extends ConsumerStatefulWidget {
  final Habit habit;

  const HabitDetailScreen({super.key, required this.habit});

  @override
  ConsumerState<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends ConsumerState<HabitDetailScreen> {
  bool isWeekView = false;

  Color get accentColor {
    var hex = widget.habit.colorHex
        .replaceFirst('#', '')
        .replaceFirst('0x', '')
        .replaceFirst('0X', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final analyticsAsync = ref.watch(
      habitAnalyticsProvider((
        habitId: widget.habit.id,
        schedule: widget.habit.schedule,
      )),
    );

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(
          widget.habit.title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            tooltip: 'Edit habit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: _showEditSheet,
          ),
        ],
      ),
      body: analyticsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (analytics) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStatsGrid(analytics),
              const SizedBox(height: 16),
              _buildCalendar(analytics),
              const SizedBox(height: 24),
              _buildCompletionGraph(analytics),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(HabitAnalytics analytics) {
    final stats = [
      _StatData(
        Icons.local_fire_department,
        'Current streak',
        '${analytics.streakStats.currentStreak} days',
      ),
      _StatData(
        Icons.check_circle,
        'Completions',
        '${analytics.streakStats.totalCompletions} times',
      ),
      _StatData(
        Icons.event_busy,
        'Missed days',
        '${analytics.streakStats.missedDays} days',
      ),
      _StatData(
        Icons.pie_chart,
        'Score',
        '${(analytics.consistencyStats.scorePercent * 100).toStringAsFixed(0)}%',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.2,
      ),
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                stat.label,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(stat.icon, size: 14, color: accentColor),
                  const SizedBox(width: 4),
                  Text(
                    stat.value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCalendar(HabitAnalytics analytics) {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    const numWeeks = 18;

    // Most recent Sunday (start of current week)
    final currentWeekStart = today.subtract(Duration(days: today.weekday % 7));

    // Week start dates, oldest to newest
    final weekStarts = List.generate(
      numWeeks,
      (i) => currentWeekStart.subtract(Duration(days: (numWeeks - 1 - i) * 7)),
    );

    bool isCompletedOn(DateTime date) {
      return analytics.logs.any((log) {
        final logDate = DateTime(
          log.completedAt.year,
          log.completedAt.month,
          log.completedAt.day,
        );
        return logDate == date;
      });
    }

    String? monthLabelFor(DateTime weekStart) {
      for (int d = 0; d < 7; d++) {
        final date = weekStart.add(Duration(days: d));
        if (date.day == 1) return DateFormat('MMM').format(date);
      }
      return null;
    }

    const dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true, // auto-scroll to the most recent week
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fixed weekday label column
          Column(
            children: [
              const SizedBox(height: 20),
              ...List.generate(
                7,
                (i) => SizedBox(
                  width: 24,
                  height: 28,
                  child: Center(
                    child: Text(
                      dayLabels[i],
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // One column per week
          ...weekStarts.map((weekStart) {
            final label = monthLabelFor(weekStart);
            return Column(
              children: [
                SizedBox(
                  height: 20,
                  width: 30,
                  child: label != null
                      ? Text(
                          label,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        )
                      : null,
                ),
                ...List.generate(7, (dayIndex) {
                  final date = weekStart.add(Duration(days: dayIndex));
                  final isFuture = date.isAfter(today);
                  final completed = isCompletedOn(date);

                  return Container(
                    width: 26,
                    height: 26,
                    margin: const EdgeInsets.symmetric(
                      vertical: 1,
                      horizontal: 2,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isFuture
                          ? Colors.transparent
                          : completed
                          ? accentColor
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: isFuture
                        ? null
                        : Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: completed
                                  ? Colors.white
                                  : Colors.grey.shade700,
                            ),
                          ),
                  );
                }),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCompletionGraph(HabitAnalytics analytics) {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    const weeksToShow = 12;

    // Find the Monday of the current week.
    final currentWeekStart = today.subtract(
      Duration(days: today.weekday - DateTime.monday),
    );

    // Create 12 weekly periods, oldest first.
    final weekStarts = List.generate(
      weeksToShow,
      (index) => currentWeekStart.subtract(
        Duration(days: (weeksToShow - 1 - index) * 7),
      ),
    );

    // Convert logs into unique calendar dates.
    final completedDates = analytics.logs.map((log) {
      return DateTime(
        log.completedAt.year,
        log.completedAt.month,
        log.completedAt.day,
      );
    }).toSet();

    final spots = weekStarts.asMap().entries.map((entry) {
      final index = entry.key;
      final weekStart = entry.value;
      final weekEnd = weekStart.add(const Duration(days: 7));

      // For completed weeks, 7 days are expected.
      // For the current week, only count the days that have happened so far.
      final isCurrentWeek = weekStart == currentWeekStart;

      final expectedDays = isCurrentWeek
          ? today.difference(weekStart).inDays + 1
          : 7;

      final completedDays = completedDates.where((date) {
        return !date.isBefore(weekStart) && date.isBefore(weekEnd);
      }).length;

      final score = expectedDays == 0
          ? 0.0
          : (completedDays / expectedDays) * 100;

      return FlSpot(index.toDouble(), score.clamp(0, 100).toDouble());
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Score',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 4),

          Text(
            'Last 12 weeks',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,

                gridData: FlGridData(show: true, horizontalInterval: 20),

                borderData: FlBorderData(show: false),

                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),

                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),

                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 20,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        );
                      },
                    ),
                  ),

                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();

                        if (index < 0 || index >= weekStarts.length) {
                          return const SizedBox();
                        }

                        final date = weekStarts[index];

                        // Show month when the month changes.
                        if (index == 0 ||
                            date.month != weekStarts[index - 1].month) {
                          return Text(
                            DateFormat('MMM').format(date),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          );
                        }

                        return Text(
                          DateFormat('d').format(date),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: false,
                    barWidth: 3,
                    color: accentColor,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: accentColor.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // lets the sheet rise above the keyboard
      useSafeArea: true,
      builder: (sheetContext) => CreateHabitBottomSheet(
        habitToEdit: widget.habit,
        onClose: () => Navigator.of(sheetContext).pop(),
      ),
    );
  }
}

class _StatData {
  final IconData icon;
  final String label;
  final String value;
  _StatData(this.icon, this.label, this.value);
}
