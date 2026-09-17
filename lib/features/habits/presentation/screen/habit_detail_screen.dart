import 'package:flutter/material.dart';
import '../../domain/models/habit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../analytics/presentation/providers/habit_analytics_provider.dart';
import 'package:intl/intl.dart';

class HabitDetailScreen extends ConsumerStatefulWidget {
  final Habit habit;

  const HabitDetailScreen({super.key, required this.habit});

  @override
  ConsumerState<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends ConsumerState<HabitDetailScreen> {
  bool isWeekView = false;

  Color get accentColor {
    var hex = widget.habit.colorHex.replaceFirst('#', '').replaceFirst('0x', '').replaceFirst('0X', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final analyticsAsync = ref.watch(
      habitAnalyticsProvider((habitId: widget.habit.id, schedule: widget.habit.schedule)),
    );

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(widget.habit.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(HabitAnalytics analytics) {
    final stats = [
      _StatData(Icons.local_fire_department, 'Current streak', '${analytics.streakStats.currentStreak} days'),
      _StatData(Icons.check_circle, 'Completions', '${analytics.streakStats.totalCompletions} times'),
      _StatData(Icons.event_busy, 'Missed days', '${analytics.streakStats.missedDays} days'),
      _StatData(Icons.pie_chart, 'Score', '${(analytics.consistencyStats.scorePercent * 100).toStringAsFixed(0)}%'),
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
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(stat.label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(stat.icon, size: 14, color: accentColor),
                  const SizedBox(width: 4),
                  Text(stat.value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCalendar(HabitAnalytics analytics) {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
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
        final logDate = DateTime(log.completedAt.year, log.completedAt.month, log.completedAt.day);
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
              ...List.generate(7, (i) => SizedBox(
                width: 24,
                height: 28,
                child: Center(
                  child: Text(dayLabels[i], style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                ),
              )),
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
                      ? Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500))
                      : null,
                ),
                ...List.generate(7, (dayIndex) {
                  final date = weekStart.add(Duration(days: dayIndex));
                  final isFuture = date.isAfter(today);
                  final completed = isCompletedOn(date);

                  return Container(
                    width: 26,
                    height: 26,
                    margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 2),
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
                              color: completed ? Colors.white : Colors.grey.shade700,
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
}

class _StatData {
  final IconData icon;
  final String label;
  final String value;
  _StatData(this.icon, this.label, this.value);
}