import 'package:flutter/material.dart';
import '../../domain/models/habit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../analytics/presentation/providers/habit_analytics_provider.dart';

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
              _buildHeatmap(analytics),
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

  Widget _buildHeatmap(HabitAnalytics analytics) {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    // Last 35 days, oldest first, ending today
    final days = List.generate(35, (index) => today.subtract(Duration(days: 34 - index)));

    bool isCompletedOn(DateTime date) {
      return analytics.logs.any((log) {
        final logDate = DateTime(log.completedAt.year, log.completedAt.month, log.completedAt.day);
        return logDate == date;
      });
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: days.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemBuilder: (context, index) {
        final date = days[index];
        final completed = isCompletedOn(date);
        final isFuture = date.isAfter(today);

        return Container(
          decoration: BoxDecoration(
            color: isFuture
                ? Colors.transparent
                : completed
                    ? accentColor
                    : accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      },
    );
  }
}

class _StatData {
  final IconData icon;
  final String label;
  final String value;
  _StatData(this.icon, this.label, this.value);
}