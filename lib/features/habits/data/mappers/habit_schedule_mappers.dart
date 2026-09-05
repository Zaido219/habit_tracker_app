import 'dart:convert';

extension HabitScheduleStorage on HabitSchedule {
  /// Deserializes database strings into a rich HabitSchedule object
  static HabitSchedule fromStorage(String typeStr, String configStr) {
    final scheduleType = ScheduleType.fromString(typeStr);
    
    // Parse target days or frequency list from stored JSON string
    List<int> targetDays = [];
    if (configStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(configStr);
        if (decoded is List) {
          targetDays = decoded.cast<int>();
        }
      } catch (_) {
        // Fallback for empty or corrupt json strings
        targetDays = [];
      }
    }

    return HabitSchedule(
      type: scheduleType,
      targetDaysOrFrequency: targetDays,
    );
  }

  /// Serializes the target list back to a JSON string for SQLite storage
  String toConfigJson() {
    return jsonEncode(targetDaysOrFrequency);
  }
}