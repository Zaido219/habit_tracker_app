import '../models/habit.dart';
import '../models/habit_log.dart';
import '../models/habit_reminder.dart';

abstract class HabitRepository {
  /// Stream of all habits ordered by their manual position index.
  Stream<List<Habit>> watchAllHabits();

  /// Retrieve a single habit by its unique ID.
  Future<Habit?> getHabitById(String id);

  /// Create a new habit along with its associated initial reminders.
  Future<void> createHabit({
    required Habit habit,
    List<HabitReminder> reminders = const [],
  });

  /// Update existing habit configuration details.
  Future<void> updateHabit(Habit habit);

  /// Delete a habit. Cascading delete in SQLite handles associated logs & reminders.
  Future<void> deleteHabit(String habitId);

  /// Update manual drag-and-drop ordinal indexes for habit reordering.
  Future<void> updateHabitPositions(List<Habit> reorderedHabits);

  /// Stream of logs recorded for a specific habit within a date window.
  Stream<List<HabitLog>> watchLogsForHabit(
    String habitId, {
    DateTime? from,
    DateTime? to,
  });

  /// Log a habit completion entry for a specific date.
  Future<void> logCompletion(String habitId, DateTime timestamp);

  /// Remove a completion entry (e.g., if a user unchecks a habit card).
  Future<void> removeLog(String logId);

  /// Get scheduled reminders attached to a specific habit.
  Future<List<HabitReminder>> getRemindersForHabit(String habitId);

  /// Replace or update reminders for a habit.
  Future<void> syncReminders(
    String habitId,
    List<HabitReminder> reminders,
  );
}