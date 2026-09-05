import '../../../../core/database/app_database.dart' as db;
import '../../domain/models/habit_reminder.dart';

extension HabitReminderDataMapper on db.HabitReminder {
  HabitReminder toDomain() {
    return HabitReminder(
      id: id,
      habitId: habitId,
      leadTimeMinutes: leadTimeMinutes, // adjust properties based on your Domain HabitReminder model
      targetTime: targetTime,
    );
  }
}

extension HabitReminderDomainMapper on HabitReminder {
  db.HabitRemindersCompanion toCompanion() {
    return db.HabitRemindersCompanion.insert(
      id: id,
      habitId: habitId,
      leadTimeMinutes: leadTimeMinutes, // adjust properties based on your Domain HabitReminder model
      targetTime: targetTime,
    );
  }
}