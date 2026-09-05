class HabitReminder {
  final String id;
  final String habitId;
  final int leadTimeMinutes;
  /// Target time stored in 24-hour HH:MM format (e.g., "08:30")
  final String targetTime;

  const HabitReminder({
    required this.id,
    required this.habitId,
    required this.leadTimeMinutes,
    required this.targetTime
  });
}