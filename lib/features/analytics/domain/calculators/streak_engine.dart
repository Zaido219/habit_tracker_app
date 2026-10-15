import '../../../habits/domain/models/habit_schedule.dart';
import '../../../habits/domain/models/habit_log.dart'; // domain model, not Drift's generated one

class StreakStats {
  final int currentStreak;
  final int totalCompletions;
  final int missedDays;

  const StreakStats({
    required this.currentStreak,
    required this.totalCompletions,
    required this.missedDays,
  });
}

class StreakEngine {
  final HabitSchedule schedule;
  final List<HabitLog> logs; // sorted desc by completedAt

  StreakEngine({required this.schedule, required this.logs});

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  late final Set<DateTime> _completedDates = logs
      .map((log) => _dateOnly(log.completedAt))
      .toSet();

  /// Consecutive expected days completed, counting back from today.
  int calculateCurrentStreak() {
    int streak = 0;
    DateTime cursor = _dateOnly(DateTime.now());
    final today = cursor;

    while (true) {
      if (schedule.isExpectedDay(cursor)) {
        if (_completedDates.contains(cursor)) {
          streak++;
        } else if (cursor == today) {
          // Don't break the streak just because today isn't done yet.
        } else {
          break;
        }
      }
      cursor = cursor.subtract(const Duration(days: 1));

      if (schedule.startDate != null && cursor.isBefore(_dateOnly(schedule.startDate!))) {
        break;
      }
    }
    return streak;
  }

  int calculateTotalCompletions() => logs.length;

  /// Missed = expected days between startDate and today that have no log.
  int calculateMissedDays() {
    final start = schedule.startDate != null
        ? _dateOnly(schedule.startDate!)
        : _dateOnly(logs.isNotEmpty ? logs.last.completedAt : DateTime.now());
    final today = _dateOnly(DateTime.now());

    int missed = 0;
    for (DateTime d = start; !d.isAfter(today); d = d.add(const Duration(days: 1))) {
      if (schedule.isExpectedDay(d) && !_completedDates.contains(d)) {
        missed++;
      }
    }
    return missed;
  }

  StreakStats computeAll() {
    return StreakStats(
      currentStreak: calculateCurrentStreak(),
      totalCompletions: calculateTotalCompletions(),
      missedDays: calculateMissedDays(),
    );
  }
}