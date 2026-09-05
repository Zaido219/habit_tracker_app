import 'package:drift/drift.dart';

import 'connection.dart';

import 'tables/habits.dart';
import 'tables/habit_logs.dart';
import 'tables/habit_reminders.dart';

import 'daos/habit_dao.dart';
import 'daos/habit_log_dao.dart';
import 'daos/habit_reminder_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Habits,
    HabitLogs,
    HabitReminders,
  ],
  daos: [
    HabitDao,
    HabitLogDao,
    HabitReminderDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? openConnection());

  @override
  int get schemaVersion => 1;
}