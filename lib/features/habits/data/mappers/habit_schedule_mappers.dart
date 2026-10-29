import 'dart:convert';

import '../../domain/models/habit_schedule.dart';

extension HabitScheduleStorage on HabitSchedule {
  /// Deserializes database strings into a rich HabitSchedule object
  static HabitSchedule fromStorage(
    String typeStr,
    String configStr, {
    DateTime? fallbackStartDate,
  }) {
    final scheduleType = ScheduleType.fromString(typeStr);

    // Parse target days or frequency list from stored JSON string
    List<int> targetDays = [];
    DateTime? startDate;
    if (configStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(configStr);
        if (decoded is List) {
          targetDays = decoded.cast<int>();
        } else if (decoded is Map<String, dynamic>) {
          targetDays = (decoded['targetDaysOrFrequency'] as List? ?? const [])
              .cast<int>();
          final storedStartDate = decoded['startDate'];
          if (storedStartDate is String) {
            startDate = DateTime.tryParse(storedStartDate);
          }
        }
      } catch (_) {
        // Fallback for empty or corrupt json strings
        targetDays = [];
      }
    }

    return HabitSchedule(
      type: scheduleType,
      targetDaysOrFrequency: targetDays,
      startDate:
          startDate ??
          (scheduleType == ScheduleType.custom ? fallbackStartDate : null),
    );
  }

  /// Serializes the target list back to a JSON string for SQLite storage
  String toConfigJson() {
    if (type == ScheduleType.custom && startDate != null) {
      return jsonEncode({
        'targetDaysOrFrequency': targetDaysOrFrequency,
        'startDate': DateTime(
          startDate!.year,
          startDate!.month,
          startDate!.day,
        ).toIso8601String(),
      });
    }
    return jsonEncode(targetDaysOrFrequency);
  }
}
