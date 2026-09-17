import '../../../habits/domain/models/habit_schedule.dart';
import '../../../habits/domain/models/habit_log.dart';


class ConsistencyStats {
  final double scorePercent; // 0.0 - 1.0

  const ConsistencyStats({required this.scorePercent});
}

class ConsistencyEngine {
  final HabitSchedule schedule;
  final List<HabitLog> logs;

  ConsistencyEngine({required this.schedule, required this.logs});

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _isCompletedOn(DateTime date) {
    final target = _dateOnly(date);
    return logs.any((log) => _dateOnly(log.completedAt) == target);
  }

  /// Score = completed expected days / total expected days, within [from, to].
  double calculateScore({required DateTime from, required DateTime to}) {
    int expected = 0;
    int completed = 0;

    for (DateTime d = _dateOnly(from); !d.isAfter(_dateOnly(to)); d = d.add(const Duration(days: 1))) {
      if (schedule.isExpectedDay(d)) {
        expected++;
        if (_isCompletedOn(d)) completed++;
      }
    }
    return expected == 0 ? 0.0 : completed / expected;
  }

  ConsistencyStats computeAll({DateTime? from, DateTime? to}) {
    final now = to ?? DateTime.now();
    final start = from ?? schedule.startDate ?? now.subtract(const Duration(days: 30));
    return ConsistencyStats(scorePercent: calculateScore(from: start, to: now));
  }
}