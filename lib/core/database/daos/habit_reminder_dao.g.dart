// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit_reminder_dao.dart';

// ignore_for_file: type=lint
mixin _$HabitReminderDaoMixin on DatabaseAccessor<AppDatabase> {
  $HabitsTable get habits => attachedDatabase.habits;
  $HabitRemindersTable get habitReminders => attachedDatabase.habitReminders;
  HabitReminderDaoManager get managers => HabitReminderDaoManager(this);
}

class HabitReminderDaoManager {
  final _$HabitReminderDaoMixin _db;
  HabitReminderDaoManager(this._db);
  $$HabitsTableTableManager get habits =>
      $$HabitsTableTableManager(_db.attachedDatabase, _db.habits);
  $$HabitRemindersTableTableManager get habitReminders =>
      $$HabitRemindersTableTableManager(
        _db.attachedDatabase,
        _db.habitReminders,
      );
}
