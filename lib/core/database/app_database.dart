import 'package:drift/drift.dart';
import 'tables/habit_logs.dart';
import 'tables/habit_reminders.dart';
import 'tables/habits.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables:[
    Habits,
    HabitLogs,
    HabitReminders,
  ],
)
class AppDatabase extends _$AppDatabase{
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;
}