import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/habit_reminders.dart';

part 'habit_reminder_dao.g.dart';

@DriftAccessor(tables: [HabitReminders])
class HabitReminderDao extends DatabaseAccessor<AppDatabase>
    with _$HabitReminderDaoMixin {
  HabitReminderDao(super.db);

  /// Get all reminders for a habit.
  Future<List<HabitReminder>> getForHabit(String habitId) {
    return (select(
      habitReminders,
    )..where((reminder) => reminder.habitId.equals(habitId))).get();
  }

  /// Watch reminders for a habit.
  Stream<List<HabitReminder>> watchForHabit(String habitId) {
    return (select(
      habitReminders,
    )..where((reminder) => reminder.habitId.equals(habitId))).watch();
  }

  /// Get a single reminder.
  Future<HabitReminder?> getById(String id) {
    return (select(
      habitReminders,
    )..where((reminder) => reminder.id.equals(id))).getSingleOrNull();
  }

  /// Create a reminder.
  Future<void> create(HabitRemindersCompanion reminder) {
    return into(habitReminders).insert(reminder);
  }

  /// Update a reminder.
  Future<bool> updateReminder(
    String id,
    HabitRemindersCompanion changes,
  ) async {
    final updatedRows = await (update(
      habitReminders,
    )..where((reminder) => reminder.id.equals(id))).write(changes);

    return updatedRows > 0;
  }

  /// Delete a reminder.
  Future<int> deleteById(String id) {
    return (delete(
      habitReminders,
    )..where((reminder) => reminder.id.equals(id))).go();
  }

  /// Delete all reminders for a habit.
  Future<int> deleteForHabit(String habitId) {
    return (delete(
      habitReminders,
    )..where((reminder) => reminder.habitId.equals(habitId))).go();
  }

  /// Fetch all reminders linked to a specific habit
  Future<List<HabitReminder>> getByHabitId(String habitId) {
    return (select(
      habitReminders,
    )..where((tbl) => tbl.habitId.equals(habitId))).get();
  }

  /// Delete all reminders linked to a specific habit
  Future<int> deleteByHabitId(String habitId) {
    return (delete(
      habitReminders,
    )..where((tbl) => tbl.habitId.equals(habitId))).go();
  }
}
