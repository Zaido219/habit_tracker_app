import 'package:drift/drift.dart';
import 'package:habit_tracker_app/core/database/connection.dart';
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
  AppDatabase() : super(openConnection());

  @override
  int get schemaVersion => 1;
}